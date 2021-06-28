#!/bin/sh

set -euo pipefail

cd ..
mkdir -p obj
cp "$3" obj/stage2.elf
objcopy -O binary obj/stage2.elf obj/stage2.bin
./install.sh
TIMEOUT=$1 ./run.sh $2
