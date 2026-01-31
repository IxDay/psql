const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Build dependencies
    const z = buildZlib(b, target, optimize);
    const ncurses = buildNcurses(b, target, optimize);
    const readline = buildReadline(b, target, optimize, ncurses);
    const openssl = buildOpenssl(b, target, optimize);

    // Build psql
    const psql = buildPsql(b, target, optimize, z, ncurses, readline, openssl);
    b.installArtifact(psql);

    // Optionally install dependency libraries
    const install_libs = b.option(bool, "install-libs", "Install dependency libraries") orelse false;
    if (install_libs) {
        b.installArtifact(z);
        b.installArtifact(ncurses);
        b.installArtifact(readline);
        b.installArtifact(openssl);
    }
}

fn buildZlib(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const z_dep = b.dependency("z", .{});

    const z_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    z_mod.addCSourceFiles(.{
        .root = z_dep.path(""),
        .files = &.{
            "adler32.c",  "compress.c", "crc32.c",   "deflate.c",
            "gzclose.c",  "gzlib.c",    "gzread.c",  "gzwrite.c",
            "inflate.c",  "infback.c",  "inftrees.c", "inffast.c",
            "trees.c",    "uncompr.c",  "zutil.c",
        },
        .flags = &.{
            "-DHAVE_SYS_TYPES_H",
            "-DHAVE_STDINT_H",
            "-DHAVE_STDDEF_H",
            "-DZ_HAVE_UNISTD_H",
        },
    });

    const z = b.addLibrary(.{
        .name = "z",
        .root_module = z_mod,
    });

    z.installHeader(z_dep.path("zlib.h"), "zlib.h");
    z.installHeader(z_dep.path("zconf.h"), "zconf.h");

    return z;
}

fn buildNcurses(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const ncurses_dep = b.dependency("ncurses", .{
        .target = target,
        .optimize = optimize,
    });

    // The ncurses package exports a single "ncurses" artifact
    return ncurses_dep.artifact("ncurses");
}

fn buildReadline(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    ncurses: *std.Build.Step.Compile,
) *std.Build.Step.Compile {
    // The readline package has proper Zig 0.15 API
    const readline_dep = b.dependency("readline", .{
        .target = target,
        .optimize = optimize,
    });

    // Get the readline library artifact
    const lib = readline_dep.artifact("lib");

    // Link ncurses to readline and add ncurses headers explicitly
    // (linkLibrary alone doesn't propagate headers for cross-compilation)
    lib.root_module.linkLibrary(ncurses);

    const ncurses_dep = b.dependency("ncurses", .{});
    lib.root_module.addIncludePath(ncurses_dep.path("config"));

    return lib;
}

fn buildOpenssl(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const openssl_dep = b.dependency("openssl", .{
        .target = target,
        .optimize = optimize,
    });

    // The openssl package exports a single "openssl" artifact
    return openssl_dep.artifact("openssl");
}

fn buildPsql(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    z: *std.Build.Step.Compile,
    ncurses: *std.Build.Step.Compile,
    readline: *std.Build.Step.Compile,
    openssl: *std.Build.Step.Compile,
) *std.Build.Step.Compile {
    const pg_dep = b.dependency("postgresql", .{});

    const psql_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    // Add our config headers
    psql_mod.addIncludePath(b.path("pg_config"));

    // Add PostgreSQL include paths
    psql_mod.addIncludePath(pg_dep.path("src/include"));
    psql_mod.addIncludePath(pg_dep.path("src/interfaces/libpq"));
    psql_mod.addIncludePath(pg_dep.path("src/common"));
    psql_mod.addIncludePath(pg_dep.path("src/port"));
    psql_mod.addIncludePath(pg_dep.path("src/bin/psql"));
    psql_mod.addIncludePath(pg_dep.path("src/fe_utils"));
    // For generated catalog headers (*_d.h) - they're at src/backend/catalog/
    // but included as "catalog/pg_am_d.h", so we add src/backend/
    psql_mod.addIncludePath(pg_dep.path("src/backend"));

    // Link dependencies
    psql_mod.linkLibrary(z);
    psql_mod.linkLibrary(ncurses);
    psql_mod.linkLibrary(readline);
    psql_mod.linkLibrary(openssl);

    // Detect target characteristics
    const is_musl = target.result.abi == .musl;
    const is_darwin = target.result.os.tag.isDarwin();

    const common_flags: []const []const u8 = &.{
        "-D_GNU_SOURCE",
        "-DFRONTEND",
        "-DHAVE_CONFIG_H",
        "-DUSE_OPENSSL",
    };

    // Add port sources (libpgport)
    psql_mod.addCSourceFiles(.{
        .root = pg_dep.path("src/port"),
        .files = &.{
            "bsearch_arg.c",
            "chklocale.c",
            // getpeereid.c - macOS has it built-in
            "inet_net_ntop.c",
            "noblock.c",
            "path.c",
            "pg_bitutils.c",
            "pg_strong_random.c",
            "pgcheckdir.c",
            "pgmkdirp.c",
            "pgsleep.c",
            "pgstrcasecmp.c",
            "pgstrsignal.c",
            // pqsignal.c excluded - provided by legacy-pqsignal.c in libpq
            "qsort.c",
            "qsort_arg.c",
            "quotes.c",
            "snprintf.c",
            "strerror.c",
            "tar.c",
            "thread.c",
            "pg_crc32c_sb8.c",
        },
        .flags = common_flags,
    });

    // Platform-specific port files
    if (!is_darwin) {
        // getpeereid - macOS has it built-in
        psql_mod.addCSourceFiles(.{
            .root = pg_dep.path("src/port"),
            .files = &.{"getpeereid.c"},
            .flags = common_flags,
        });
    }
    if (is_darwin) {
        // explicit_bzero - macOS doesn't have it
        psql_mod.addCSourceFiles(.{
            .root = pg_dep.path("src/port"),
            .files = &.{"explicit_bzero.c"},
            .flags = common_flags,
        });
    }

    // glibc doesn't have strlcpy/strlcat, add port implementations
    // (musl and Darwin have them built-in)
    if (!is_musl and !is_darwin) {
        psql_mod.addCSourceFiles(.{
            .root = pg_dep.path("src/port"),
            .files = &.{
                "strlcat.c",
                "strlcpy.c",
            },
            .flags = common_flags,
        });
    }

    // Add common sources (libpgcommon)
    psql_mod.addCSourceFiles(.{
        .root = pg_dep.path("src/common"),
        .files = &.{
            "archive.c",
            "base64.c",
            "checksum_helper.c",
            "compression.c",
            "config_info.c",
            "controldata_utils.c",
            "d2s.c",
            "encnames.c",
            "exec.c",
            "f2s.c",
            "fe_memutils.c",
            "file_perm.c",
            "file_utils.c",
            "hashfn.c",
            "ip.c",
            "jsonapi.c",
            "keywords.c",
            "kwlookup.c",
            "link-canary.c",
            "logging.c",
            "md5_common.c",
            "percentrepl.c",
            "pg_get_line.c",
            "pg_lzcompress.c",
            "pg_prng.c",
            "pgfnames.c",
            "psprintf.c",
            "relpath.c",
            "restricted_token.c",
            "rmtree.c",
            "saslprep.c",
            "scram-common.c",
            "sprompt.c",
            "string.c",
            "stringinfo.c",
            "unicode_norm.c",
            "username.c",
            "wait_error.c",
            "wchar.c",
            // OpenSSL-specific
            "cryptohash_openssl.c",
            "hmac_openssl.c",
            "protocol_openssl.c",
        },
        .flags = common_flags,
    });

    // Add libpq sources
    psql_mod.addCSourceFiles(.{
        .root = pg_dep.path("src/interfaces/libpq"),
        .files = &.{
            "fe-auth-scram.c",
            "fe-auth.c",
            "fe-connect.c",
            "fe-exec.c",
            "fe-lobj.c",
            "fe-misc.c",
            "fe-print.c",
            "fe-protocol3.c",
            "fe-secure-common.c",
            "fe-secure-openssl.c",
            "fe-secure.c",
            "fe-trace.c",
            "legacy-pqsignal.c",
            "libpq-events.c",
            "pqexpbuffer.c",
        },
        .flags = common_flags,
    });

    // Add fe_utils sources
    psql_mod.addCSourceFiles(.{
        .root = pg_dep.path("src/fe_utils"),
        .files = &.{
            "archive.c",
            "cancel.c",
            "conditional.c",
            "connect_utils.c",
            "mbprint.c",
            "option_utils.c",
            "parallel_slot.c",
            "print.c",
            "psqlscan.c",
            "query_utils.c",
            "recovery_gen.c",
            "simple_list.c",
            "string_utils.c",
        },
        .flags = common_flags,
    });

    // Add psql sources
    psql_mod.addCSourceFiles(.{
        .root = pg_dep.path("src/bin/psql"),
        .files = &.{
            "command.c",
            "common.c",
            "copy.c",
            "crosstabview.c",
            "describe.c",
            "help.c",
            "input.c",
            "large_obj.c",
            "mainloop.c",
            "prompt.c",
            "psqlscanslash.c",
            "sql_help.c",
            "startup.c",
            "stringutils.c",
            "tab-complete.c",
            "variables.c",
        },
        .flags = common_flags,
    });

    const psql = b.addExecutable(.{
        .name = "psql",
        .root_module = psql_mod,
    });

    return psql;
}
