#!/bin/sh

make -C .. obj/libstage2asm.a > /dev/null
ld -melf_i386 -T stage2.ld ../obj/libstage2asm.a "$@"
