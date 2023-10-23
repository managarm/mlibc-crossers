#!/bin/bash
: "${PARALLELISM:=$(nproc)}"
set -xe

mkdir libabigail
cd libabigail
tar -xvf /libabigail-*.tar.xz --strip-components=1
mkdir _build
cd _build
../configure
make -O -j"${PARALLELISM}"
make -O -j"${PARALLELISM}" install
cd /
rm -rf /libabigail*
