#!/bin/bash
targets=(
    riscv64-linux-mlibc
    x86_64-linux-mlibc
    aarch64-linux-mlibc
    i686-linux-mlibc
)

set -xe

: "${PARALLELISM:=$(nproc)}"

unpack() (
    [[ $3 ]] && { echo >&2 too many tars; exit 2; }
    cd "$1"
    tar -xf "$2" --strip-components=1
)

mkdir tool-src binutils gcc
unpack binutils "$(pwd)"/binutils-*.tar*
unpack gcc "$(pwd)"/gcc-*.tar*
( cd binutils && find . -print0 | cpio -0updlm ../tool-src )
( cd gcc && find . -print0 | cpio -0pdlm ../tool-src )

# Recover more up-to-date at time of writing ansidecl
( cd gcc && find include -print0 | cpio -0updlm ../tool-src )

mlibc_src="$(pwd)/mlibc-src"
git clone ${MLIBC-https://github.com/managarm/mlibc.git} "${mlibc_src}"

mkdir linux
unpack linux "$(pwd)"/linux-*.tar*

cp config.{guess,sub} tool-src
host="$(./config.guess)"

for target in "${targets[@]}"; do (
    sysroot="$(pwd)/sysroots/${target}"
    mkdir "${target}"
    cd "${target}"

    arch="${target%%-*}"
    case "$arch" in
        aarch64) arch="arm64" ;;
        riscv64) arch="riscv" ;;
        i686)    arch="i386"  ;;
    esac
    make -C ../linux O="${sysroot}" ARCH="${arch}" headers_install

    mkdir mlibc-build
    pushd mlibc-build
    meson setup \
          --prefix=/usr \
          -Dheaders_only=true \
          -Dlinux_kernel_headers="${sysroot}/usr/include" \
          . \
          "${mlibc_src}"
    DESTDIR="${sysroot}" ninja install
    popd

    workarounds=(
        # Stop a link-time test for the futex syscalls.
        --disable-linux-futex
    )
    ../tool-src/configure \
        --enable-languages=c,c++,lto \
        --with-pkgversion=managarm \
        --with-bugurl=https://github.com/managarm/mlibc-crossers/issues/ \
        --target="${target}" \
        --host="${host}" \
        --build="${host}" \
        --with-sysroot="${sysroot}" \
        --without-headers \
        --without-newlib \
        --disable-threads \
        --disable-multilib \
        --disable-shared \
        --disable-libstdcxx-hosted \
        --disable-libstdcxx-backtrace \
        --disable-wchar_t \
        --disable-{libssp,libsanitizer,libquadmath,gdb,gold,gprof,gprofng} \
        --disable-{libdecnmumber,readline,sim,libctf,libgomp,libatomic} \
        --disable-{libffi,libitm,libvtv} \
        "${workarounds[@]}" \
        ${MANYTOOLS_CONF_EXTRA}
    make -O -j"${PARALLELISM}"
    make -O -j"${PARALLELISM}" install
    rm -rf "${sysroot}"/*

    # Clean up
    cd ..
    rm -rf "${target}"
); done

# Clean up source dirs
rm -rf gcc binutils tool-src tool-checksums *.tar* config.{sub,guess} \
   tool-checksums linux mlibc-src

# Local Variables:
# indent-tabs-mode: nil
# End:
