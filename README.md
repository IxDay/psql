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

## Download

Check the [Releases](../../releases) page for pre-built binaries.

## Building from Source

The build uses [Zig](https://ziglang.org/) as a cross-compiler.

### Requirements

- Zig 0.15+

### Build

```bash
# Native build
zig build

# Cross-compile for Linux (fully static)
zig build -Dtarget=x86_64-linux-musl -Dlinkage=static -Doptimize=ReleaseSmall

# Cross-compile for Linux (dynamic musl, for Alpine/musl systems)
zig build -Dtarget=x86_64-linux-musl -Dlinkage=dynamic -Doptimize=ReleaseSmall

# Cross-compile for macOS
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseSmall
```

### Supported Targets

| Target | Linkage | Binary | Description |
|--------|---------|--------|-------------|
| `x86_64-linux-musl` | `static` | `psql-x86_64-linux-static` | Fully static, no dependencies |
| `x86_64-linux-musl` | `dynamic` | `psql-x86_64-linux-musl` | Dynamic musl (for Alpine, etc.) |
| `aarch64-linux-musl` | `static` | `psql-aarch64-linux-static` | Fully static, no dependencies |
| `aarch64-linux-musl` | `dynamic` | `psql-aarch64-linux-musl` | Dynamic musl (for Alpine, etc.) |
| `x86_64-linux-gnu` | - | `psql-x86_64-linux-gnu` | Links against glibc |
| `aarch64-linux-gnu` | - | `psql-aarch64-linux-gnu` | Links against glibc |
| `x86_64-macos` | - | `psql-x86_64-macos` | macOS Intel |
| `aarch64-macos` | - | `psql-aarch64-macos` | macOS Apple Silicon |

## Features

- SSL/TLS support (OpenSSL 3.3)
- Compression support (zlib)
- Readline support (command history and line editing)
- Two Linux musl variants:
  - **Static**: Fully self-contained, runs anywhere without dependencies
  - **Dynamic**: Links against system musl libc, smaller binary for Alpine/musl-based systems

## License

This project is licensed under the MIT License. PostgreSQL is licensed under the [PostgreSQL License](https://www.postgresql.org/about/licence/).
