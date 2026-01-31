# Static psql

Pre-built statically linked PostgreSQL client (`psql`) binaries for multiple platforms.

## Why?

The PostgreSQL client (`psql`) is essential for database work, but installing it typically requires pulling in the entire PostgreSQL package or dealing with system dependencies. This project provides standalone static binaries that:

- Work without any dependencies (fully static on Linux)
- Can be managed with [mise](https://mise.jdx.dev/) alongside your other dev tools
- Are easy to install in CI/CD pipelines and containers

## Installation with mise

The easiest way to install is via [mise](https://mise.jdx.dev/):

```bash
mise install "github:IxDay/psql@16.1.0"
```

Then use it directly:

```bash
mise exec github:IxDay/psql -- psql --version
```

Or add to your project's `.mise.toml`:

```toml
[tools]
"github:IxDay/psql" = "16.1.0"
```

## Manual Download

Check the [Releases](../../releases) page for pre-built binaries:

- Linux x86_64 (glibc)
- Linux x86_64 (musl, fully static)
- Linux aarch64 (glibc)
- Linux aarch64 (musl, fully static)
- macOS x86_64
- macOS aarch64

## Building from Source

The build uses [Zig](https://ziglang.org/) as a cross-compiler to produce static binaries.

### Requirements

- Zig 0.15+

### Build

```bash
# Native build
zig build

# Cross-compile for Linux
zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseSmall

# Cross-compile for macOS
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseSmall
```

The resulting binary will be in `zig-out/bin/psql`.

### Supported Targets

- `x86_64-linux-gnu` - Linux x86_64 (glibc)
- `x86_64-linux-musl` - Linux x86_64 (fully static)
- `aarch64-linux-gnu` - Linux ARM64 (glibc)
- `aarch64-linux-musl` - Linux ARM64 (fully static)
- `x86_64-macos` - macOS Intel
- `aarch64-macos` - macOS Apple Silicon

## Features

- SSL/TLS support (OpenSSL 3.3)
- Compression support (zlib)
- Readline support (command history and line editing)
- Fully static binaries on Linux (musl)

## License

This project is licensed under the MIT License. PostgreSQL is licensed under the [PostgreSQL License](https://www.postgresql.org/about/licence/).
