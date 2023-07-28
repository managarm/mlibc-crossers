FROM ubuntu:22.04 AS source-fetched

ARG GCCREF=tags/managarm/gcc-13.2.0
ARG GCCBASE=https://github.com/managarm/gcc/archive/refs
ARG BINUREF=tags/managarm/binutils-2_40
ARG BINUBASE=https://github.com/managarm/binutils-gdb/archive/refs
ARG LINUXSER=v6.x
ARG LINUXVER=6.4.7

RUN apt-get update && apt-get -y upgrade && apt-get install -y ca-certificates
RUN apt-get -y install --no-install-recommends \
    build-essential git wget libgmp-dev libmpfr-dev libmpc-dev flex bison \
    meson rsync

RUN cd / && wget ${GCCBASE}/${GCCREF}.tar.gz
RUN cd / && wget ${BINUBASE}/${BINUREF}.tar.gz
RUN cd / && wget https://cdn.kernel.org/pub/linux/kernel/${LINUXSER}/linux-${LINUXVER}.tar.xz

RUN apt-get -y install --no-install-recommends \
    file texinfo cpio

ADD tool-checksums /tool-checksums
ADD build-many-tools.bash /build-many-tools.bash
ADD config.sub /config.sub
ADD config.guess /config.guess
RUN cd / && sha256sum --check --ignore-missing < tool-checksums
RUN cd / && ./build-many-tools.bash
