# Static psql

Pre-built statically linked PostgreSQL client (`psql`) binaries for multiple platforms.

## Downloads

Check the [Releases](../../releases) page for pre-built binaries:

- Linux x86_64 (musl, fully static)
- Linux aarch64 (musl, fully static)
- macOS x86_64
- macOS aarch64

## Building

The build uses [zig](https://ziglang.org/) as a cross-compiler to produce static binaries.

### Requirements

- zig
- curl

### Manual Build

```bash
# Set target architecture
export TARGET=x86_64-linux-musl

# Set PostgreSQL version (must match a release tag)
export PG_VERSION=REL_16_1

# Run the build
./build.sh
```

The resulting binary will be in `build/$TARGET/bin/psql`.

### Supported Targets

- `x86_64-linux-musl` - Linux x86_64 (fully static)
- `aarch64-linux-musl` - Linux ARM64 (fully static)
- `x86_64-macos` - macOS Intel
- `aarch64-macos` - macOS Apple Silicon

## Features

- SSL/TLS support (OpenSSL 3.2)
- Compression support (zlib)
- Readline support (command history and line editing)
- Fully static binaries on Linux (musl)

## How it Works

1. Downloads and builds static libraries: ncurses, zlib, readline, OpenSSL
2. Downloads PostgreSQL source from the official repository
3. Configures a minimal build (only client libraries and psql)
4. Uses zig cc as the compiler for cross-compilation and static linking
5. Produces a single static binary with full feature support

## GitHub Actions

This repository uses GitHub Actions to automatically build and release binaries when a tag is pushed.

To create a new release:

```bash
git tag 16.1.0
git push origin 16.1.0
```

## License

This project is licensed under the MIT License. PostgreSQL is licensed under the [PostgreSQL License](https://www.postgresql.org/about/licence/).
