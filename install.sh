#!/bin/sh

set -euo pipefail

dd if=obj/stage1.bin of=test.img bs=1 conv=notrunc count=3
dd if=obj/stage1.bin of=test.img bs=1 conv=notrunc count=344 seek=96 skip=96
cp obj/stage1.5.bin dev.d/boot/stage1.5
cp stage2.bin dev.d/boot/stage2
sync -f dev.d/. && sync test.img
