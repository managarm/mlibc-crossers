FROM ubuntu:22.04 AS source-fetched

ENV TZ=Etc/UTC \
    DEBIAN_FRONTEND=noninteractive

ARG GCCREF=tags/managarm/gcc-13.2.0
ARG GCCBASE=https://github.com/managarm/gcc/archive/refs
ARG BINUREF=tags/managarm/binutils-2_40
ARG BINUBASE=https://github.com/managarm/binutils-gdb/archive/refs
ARG LINUXSER=v6.x
ARG LINUXVER=6.4.7
ARG LIBABIGAILVER=2.4

RUN apt-get update && apt-get -y upgrade && apt-get install -y ca-certificates
RUN apt-get -y install --no-install-recommends \
    build-essential git wget libgmp-dev libmpfr-dev libmpc-dev flex bison \
    meson rsync pkg-config libdw-dev libelf-dev libdebuginfod-dev libasm-dev \
    elfutils doxygen python3-sphinx libxml2-dev

RUN cd / && wget ${GCCBASE}/${GCCREF}.tar.gz
RUN cd / && wget ${BINUBASE}/${BINUREF}.tar.gz
RUN cd / && wget https://cdn.kernel.org/pub/linux/kernel/${LINUXSER}/linux-${LINUXVER}.tar.xz
RUN cd / && wget http://mirrors.kernel.org/sourceware/libabigail/libabigail-${LIBABIGAILVER}.tar.xz

RUN apt-get -y install --no-install-recommends \
    file texinfo cpio

ADD tool-checksums /tool-checksums
ADD build-many-tools.bash /build-many-tools.bash
ADD build-libabigail.bash /build-libabigail.bash
ADD config.sub /config.sub
ADD config.guess /config.guess
RUN cd / && sha256sum --check --ignore-missing < tool-checksums
RUN cd / && ./build-libabigail.bash
RUN cd / && ./build-many-tools.bash
