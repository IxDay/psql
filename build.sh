#!/usr/bin/env bash
set -euo pipefail

# Configuration
: "${TARGET:=x86_64-linux-musl}"
: "${PG_VERSION:=REL_16_1}"
: "${NCURSES_VERSION:=6.4}"
: "${READLINE_VERSION:=8.2}"
: "${OPENSSL_VERSION:=3.2.0}"
: "${ZLIB_VERSION:=1.3.1}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build/${TARGET}"
SRC_DIR="${SCRIPT_DIR}/src"
DEPS_DIR="${BUILD_DIR}/deps"

# Get zig target for the given target
get_zig_target() {
    case "$1" in
        x86_64-linux-musl)  echo "x86_64-linux-musl" ;;
        aarch64-linux-musl) echo "aarch64-linux-musl" ;;
        x86_64-linux)       echo "x86_64-linux-gnu" ;;
        aarch64-linux)      echo "aarch64-linux-gnu" ;;
        x86_64-macos)       echo "x86_64-macos" ;;
        aarch64-macos)      echo "aarch64-macos" ;;
        *)                  echo "$1" ;;
    esac
}

# Determine if we're doing a native build
is_native() {
    case "$TARGET" in
        x86_64-macos)
            [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "x86_64" ]]
            ;;
        aarch64-macos)
            [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# Setup compiler
setup_compiler() {
    local zig_target
    zig_target="$(get_zig_target "$TARGET")"

    if is_native; then
        export CC="zig cc"
        export CXX="zig c++"
    else
        export CC="zig cc -target ${zig_target}"
        export CXX="zig c++ -target ${zig_target}"
    fi
    export AR="zig ar"
    export RANLIB="zig ranlib"
    export CFLAGS="-Os"
    export LDFLAGS="-s"
}

# Download PostgreSQL source
download_postgres() {
    local pg_tarball="postgresql-${PG_VERSION}.tar.gz"
    local pg_url="https://github.com/postgres/postgres/archive/refs/tags/${PG_VERSION}.tar.gz"

    mkdir -p "${SRC_DIR}"

    if [[ ! -d "${SRC_DIR}/postgres-${PG_VERSION}" ]]; then
        echo "Downloading PostgreSQL ${PG_VERSION}..."
        curl -L -o "${SRC_DIR}/${pg_tarball}" "${pg_url}"
        tar -xzf "${SRC_DIR}/${pg_tarball}" -C "${SRC_DIR}"
        rm "${SRC_DIR}/${pg_tarball}"
    fi
}

# Build ncurses
build_ncurses() {
    local ncurses_tarball="ncurses-${NCURSES_VERSION}.tar.gz"
    local ncurses_url="https://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"

    mkdir -p "${SRC_DIR}" "${DEPS_DIR}"

    if [[ -f "${DEPS_DIR}/lib/libncurses.a" ]]; then
        echo "ncurses already built, skipping..."
        return
    fi

    echo "Building ncurses ${NCURSES_VERSION}..."

    if [[ ! -d "${SRC_DIR}/ncurses-${NCURSES_VERSION}" ]]; then
        curl -L -o "${SRC_DIR}/${ncurses_tarball}" "${ncurses_url}"
        tar -xzf "${SRC_DIR}/${ncurses_tarball}" -C "${SRC_DIR}"
        rm "${SRC_DIR}/${ncurses_tarball}"
    fi

    cd "${SRC_DIR}/ncurses-${NCURSES_VERSION}"
    make distclean 2>/dev/null || true

    local configure_opts=(
        --prefix="${DEPS_DIR}"
        --disable-shared
        --enable-static
        --without-debug
        --without-ada
        --without-manpages
        --without-progs
        --without-tests
        --with-termlib
    )

    if ! is_native; then
        case "$TARGET" in
            x86_64-linux*) configure_opts+=(--host=x86_64-linux-gnu) ;;
            aarch64-linux*) configure_opts+=(--host=aarch64-linux-gnu) ;;
        esac
        # For cross-compilation, disable stripping (zig handles it)
        configure_opts+=(--disable-stripping)
    fi

    # Unset CPPFLAGS/LDFLAGS that might interfere
    CPPFLAGS="" LDFLAGS="" ./configure "${configure_opts[@]}"
    make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"
    # Only install libs and headers, skip terminfo database
    make install.libs install.includes

    cd "${SCRIPT_DIR}"
}

# Build zlib
build_zlib() {
    local zlib_tarball="zlib-${ZLIB_VERSION}.tar.gz"
    local zlib_url="https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz"

    mkdir -p "${SRC_DIR}" "${DEPS_DIR}"

    if [[ -f "${DEPS_DIR}/lib/libz.a" ]]; then
        echo "zlib already built, skipping..."
        return
    fi

    echo "Building zlib ${ZLIB_VERSION}..."

    if [[ ! -d "${SRC_DIR}/zlib-${ZLIB_VERSION}" ]]; then
        curl -L -o "${SRC_DIR}/${zlib_tarball}" "${zlib_url}"
        tar -xzf "${SRC_DIR}/${zlib_tarball}" -C "${SRC_DIR}"
        rm "${SRC_DIR}/${zlib_tarball}"
    fi

    cd "${SRC_DIR}/zlib-${ZLIB_VERSION}"
    make distclean 2>/dev/null || true

    # Build zlib manually for cross-compilation compatibility
    local zlib_objs="adler32.o crc32.o deflate.o infback.o inffast.o inflate.o"
    zlib_objs+=" inftrees.o trees.o zutil.o compress.o uncompr.o"
    zlib_objs+=" gzclose.o gzlib.o gzread.o gzwrite.o"

    local nproc
    nproc="$(nproc 2>/dev/null || sysctl -n hw.ncpu)"

    for src in adler32 crc32 deflate infback inffast inflate inftrees trees zutil compress uncompr gzclose gzlib gzread gzwrite; do
        ${CC} -Os -D_LARGEFILE64_SOURCE=1 -c -o "${src}.o" "${src}.c" &
    done
    wait

    ${AR} crs libz.a ${zlib_objs}
    ${RANLIB} libz.a

    # Install
    mkdir -p "${DEPS_DIR}/lib" "${DEPS_DIR}/include"
    cp libz.a "${DEPS_DIR}/lib/"
    cp zlib.h zconf.h "${DEPS_DIR}/include/"

    cd "${SCRIPT_DIR}"
}

# Build readline
build_readline() {
    local readline_tarball="readline-${READLINE_VERSION}.tar.gz"
    local readline_url="https://ftp.gnu.org/gnu/readline/readline-${READLINE_VERSION}.tar.gz"

    mkdir -p "${SRC_DIR}" "${DEPS_DIR}"

    if [[ -f "${DEPS_DIR}/lib/libreadline.a" ]]; then
        echo "readline already built, skipping..."
        return
    fi

    echo "Building readline ${READLINE_VERSION}..."

    if [[ ! -d "${SRC_DIR}/readline-${READLINE_VERSION}" ]]; then
        curl -L -o "${SRC_DIR}/${readline_tarball}" "${readline_url}"
        tar -xzf "${SRC_DIR}/${readline_tarball}" -C "${SRC_DIR}"
        rm "${SRC_DIR}/${readline_tarball}"
    fi

    cd "${SRC_DIR}/readline-${READLINE_VERSION}"
    make distclean 2>/dev/null || true

    local configure_opts=(
        --prefix="${DEPS_DIR}"
        --disable-shared
        --enable-static
        --with-curses
    )

    if ! is_native; then
        case "$TARGET" in
            x86_64-linux*) configure_opts+=(--host=x86_64-linux-gnu) ;;
            aarch64-linux*) configure_opts+=(--host=aarch64-linux-gnu) ;;
        esac
    fi

    # Point to our ncurses
    CPPFLAGS="-I${DEPS_DIR}/include -I${DEPS_DIR}/include/ncurses" \
    LDFLAGS="-L${DEPS_DIR}/lib" \
    ./configure "${configure_opts[@]}"
    make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"
    make install

    cd "${SCRIPT_DIR}"
}

# Build OpenSSL
build_openssl() {
    local openssl_tarball="openssl-${OPENSSL_VERSION}.tar.gz"
    local openssl_url="https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz"

    mkdir -p "${SRC_DIR}" "${DEPS_DIR}"

    if [[ -f "${DEPS_DIR}/lib/libssl.a" ]]; then
        echo "OpenSSL already built, skipping..."
        return
    fi

    echo "Building OpenSSL ${OPENSSL_VERSION}..."

    if [[ ! -d "${SRC_DIR}/openssl-${OPENSSL_VERSION}" ]]; then
        curl -L -o "${SRC_DIR}/${openssl_tarball}" "${openssl_url}"
        tar -xzf "${SRC_DIR}/${openssl_tarball}" -C "${SRC_DIR}"
        rm "${SRC_DIR}/${openssl_tarball}"
    fi

    cd "${SRC_DIR}/openssl-${OPENSSL_VERSION}"
    make distclean 2>/dev/null || true

    local openssl_target
    case "$TARGET" in
        x86_64-linux*) openssl_target="linux-x86_64" ;;
        aarch64-linux*) openssl_target="linux-aarch64" ;;
        x86_64-macos) openssl_target="darwin64-x86_64-cc" ;;
        aarch64-macos) openssl_target="darwin64-arm64-cc" ;;
        *) echo "Unsupported target: $TARGET"; exit 1 ;;
    esac

    ./Configure "${openssl_target}" \
        --prefix="${DEPS_DIR}" \
        --openssldir="${DEPS_DIR}/ssl" \
        CC="${CC}" \
        AR="${AR}" \
        RANLIB="${RANLIB}" \
        no-shared \
        no-module \
        no-tests \
        no-ui-console \
        no-legacy \
        no-engine \
        no-dso \
        -Os

    make -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"
    make install_sw

    # OpenSSL installs to lib64 on Linux, symlink to lib for consistency
    if [[ -d "${DEPS_DIR}/lib64" && ! -d "${DEPS_DIR}/lib" ]]; then
        ln -s lib64 "${DEPS_DIR}/lib"
    elif [[ -d "${DEPS_DIR}/lib64" ]]; then
        cp -a "${DEPS_DIR}/lib64/"* "${DEPS_DIR}/lib/"
    fi

    cd "${SCRIPT_DIR}"
}

# Build PostgreSQL (psql only)
build_postgres() {
    echo "Building PostgreSQL psql..."

    mkdir -p "${BUILD_DIR}"
    cd "${SRC_DIR}/postgres-${PG_VERSION}"

    # Clean previous build if exists
    make distclean 2>/dev/null || true

    # Configure with minimal options
    local configure_opts=(
        --prefix="${BUILD_DIR}"
        --with-readline
        --with-ssl=openssl
        --with-zlib
        --without-icu
    )

    # Add cross-compilation host if not native
    if ! is_native; then
        case "$TARGET" in
            x86_64-linux*) configure_opts+=(--host=x86_64-linux-gnu) ;;
            aarch64-linux*) configure_opts+=(--host=aarch64-linux-gnu) ;;
        esac
    fi

    export CPPFLAGS="-I${DEPS_DIR}/include -I${DEPS_DIR}/include/ncurses"
    export LDFLAGS="-L${DEPS_DIR}/lib"
    export LIBS="-lreadline -lncurses -ltinfo -lssl -lcrypto -lz"

    ./configure "${configure_opts[@]}"

    # Build required components
    local nproc
    nproc="$(nproc 2>/dev/null || sysctl -n hw.ncpu)"

    make -j"${nproc}" -C src/port
    make -j"${nproc}" -C src/common
    make -j"${nproc}" -C src/interfaces/libpq all-static-lib
    make -j"${nproc}" -C src/fe_utils

    # Build psql object files only (avoid linking step in makefile)
    make -j"${nproc}" -C src/bin/psql \
        command.o common.o copy.o crosstabview.o describe.o help.o \
        input.o large_obj.o mainloop.o prompt.o psqlscanslash.o \
        sql_help.o startup.o stringutils.o tab-complete.o variables.o

    # Manually link psql with static libraries
    mkdir -p "${BUILD_DIR}/bin"

    local psql_objs="src/bin/psql/command.o src/bin/psql/common.o src/bin/psql/copy.o"
    psql_objs+=" src/bin/psql/crosstabview.o src/bin/psql/describe.o src/bin/psql/help.o"
    psql_objs+=" src/bin/psql/input.o src/bin/psql/large_obj.o src/bin/psql/mainloop.o"
    psql_objs+=" src/bin/psql/prompt.o src/bin/psql/psqlscanslash.o src/bin/psql/sql_help.o"
    psql_objs+=" src/bin/psql/startup.o src/bin/psql/stringutils.o src/bin/psql/tab-complete.o"
    psql_objs+=" src/bin/psql/variables.o"

    local link_flags="-s"
    if [[ "$TARGET" == *musl* ]]; then
        link_flags+=" -static"
    fi

    ${CC} ${link_flags} -o "${BUILD_DIR}/bin/psql" \
        ${psql_objs} \
        src/fe_utils/libpgfeutils.a \
        src/interfaces/libpq/libpq.a \
        src/common/libpgcommon.a \
        src/port/libpgport.a \
        "${DEPS_DIR}/lib/libreadline.a" \
        "${DEPS_DIR}/lib/libncurses.a" \
        "${DEPS_DIR}/lib/libtinfo.a" \
        "${DEPS_DIR}/lib/libssl.a" \
        "${DEPS_DIR}/lib/libcrypto.a" \
        "${DEPS_DIR}/lib/libz.a" \
        -lm

    cd "${SCRIPT_DIR}"
}

# Create release archive
create_archive() {
    local archive_name="psql-${TARGET}.tar.gz"
    echo "Creating archive ${archive_name}..."

    cd "${BUILD_DIR}"
    tar -czvf "${archive_name}" -C bin psql
    echo "Archive created: ${BUILD_DIR}/${archive_name}"
}

# Main
main() {
    echo "Building psql for ${TARGET}"
    echo "PostgreSQL version: ${PG_VERSION}"

    setup_compiler
    download_postgres
    build_ncurses
    build_zlib
    build_readline
    build_openssl
    build_postgres
    create_archive

    echo "Build complete!"
    echo "Binary: ${BUILD_DIR}/bin/psql"
}

main "$@"
