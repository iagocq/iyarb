#!/bin/sh

set -euo pipefail

dd if=obj/mbr.bin of=test.img bs=1 conv=notrunc count=3
dd if=obj/mbr.bin of=test.img bs=1 conv=notrunc count=344 seek=96 skip=96
dd if=obj/bootsector.bin of=test.img bs=1 conv=notrunc count=3 seek=$((512*2048+3))
dd if=obj/bootsector.bin of=test.img bs=1 conv=notrunc count=344 seek=$((512*2048+96)) skip=96
cp obj/stage1.5.bin dev.d/boot/stage1.5 && sync -f dev.d/. && sync test.img
