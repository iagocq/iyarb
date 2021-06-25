all: build
build: obj/stage1.bin obj/stage1.5.bin obj/mbr.bin obj/stage2.bin

obj/stage1.bin: obj/stage1.elf
	objcopy -O binary $^ $@
obj/stage1.elf: obj/stage1.o
	ld -melf_i386 -T boot/stage1.ld -o $@ $^
obj/stage1.o: boot/stage1.asm | obj
	nasm -f elf32 -g -F dwarf -Ox -o $@ $^

obj/stage1.5.bin: obj/stage1.5.elf
	objcopy -O binary $^ $@
obj/stage1.5.elf: obj/stage1.5.o
	ld -melf_i386 -T boot/stage1.5.ld -o $@ $^
obj/stage1.5.o: boot/stage1.5.asm | obj
	nasm -f elf32 -g -F dwarf -Ox -o $@ $^

obj/mbr.bin: obj/mbr.elf
	objcopy -O binary $^ $@
obj/mbr.elf: obj/mbr.o
	ld -melf_i386 -T boot/mbr.ld -o $@ $^
obj/mbr.o: boot/mbr.asm | obj
	nasm -f elf32 -g -F dwarf -Ox -o $@ $^

current_dir = $(shell pwd)
obj/stage2.bin: obj/stage2.elf
	objcopy -O binary $^ $@
obj/stage2.elf: $(current_dir)/stage2/target/i686-stage2/release/stage2 | obj
	cp $^ $@
$(current_dir)/stage2/target/i686-stage2/release/stage2:
	cd stage2 && cargo build --release

-include stage2/target/i686-stage2/release/stage2.d

clean:
	rm -rf obj
	cd stage2 && cargo clean

install: build
	./install.sh
run: install
	./run.sh
debug: install
	./run.sh -s -S &
	sleep 1
	gdb -x gdb_commands
obj:
	mkdir -p obj

install-no-build:
	./install.sh
run-no-install:
	./run.sh

test:
	cd stage2 && cargo test

.PHONY: all build clean install run debug install-no-build run-no-install
