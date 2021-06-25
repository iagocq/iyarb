#!/bin/sh

qemu-system-i386 -drive file=test.img,format=raw "$@"
