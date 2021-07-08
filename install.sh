#!/bin/sh

exec > /dev/null
exec 2>&1

set -euo pipefail

dd if=obj/boot/stage1.bin of=test.img bs=1 conv=notrunc count=3
dd if=obj/boot/stage1.bin of=test.img bs=1 conv=notrunc count=344 seek=96 skip=96
cp obj/boot/stage1.5.bin dev.d/boot/stage1.5
cp obj/stage2.bin dev.d/boot/stage2
sync -f dev.d/. && sync test.img
