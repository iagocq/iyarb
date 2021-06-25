#!/bin/sh

set -euo pipefail

mkdir -p ../obj
cp "$1" ../obj/stage2.elf
cd ..
make obj/stage2.bin
make install-no-build
make run-no-install
