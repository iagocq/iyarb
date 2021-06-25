# IYARB
Iago's yet another Rust bootloader.

Another year, yet another attempt at trying to write a kinda usable bootloader.
This time, stage2 is going to be written in Rust, so I can get more familiar
with the language.

## Changes to IYASB's bootsector code
There are many improvements to the last iteration's bootsector code. This one is
more structured and compact, letting us read a file contained in a folder (like
/boot/stage1.5) from the bootsector. The problem is that I wasn't able to make
the code compact enough.

I need to use stage1.5 to do a small number of extra operations to properly read
an entire file. stage1.5 also needs to be smaller than the smallest possible
cluster on a reasonably sized disk (512B, or a single normal sector). Another
restriction is that a cluster shouldn't be bigger than a segment, so only
filesystems with clusters <=64KiB actually (theoretically) work.

stage1.5 can properly load an entire file, as long as it isn't too big and
starts overwriting other stuff. The file starts being written to 0x00500, and
can be written to up to 0x6ff00 without messing with other things
(https://wiki.osdev.org/Memory_Map_(x86) and stage1.5 stuff). That gives us
446.5KiB of headroom for a stage2.
