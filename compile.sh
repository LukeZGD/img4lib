#!/usr/bin/env bash
set -x
# This script is for macOS. For Linux, see .github/workflows/makefile.yml

git submodule update --init --recursive
cd lzfse
git reset --hard
patch Makefile ../Makefile.patch
make clean
export MACOSX_DEPLOYMENT_TARGET=10.11
make universal

cd ..
make clean
make COMMONCRYPTO=1 universal
