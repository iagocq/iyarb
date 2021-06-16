all: build
build: obj/bootsector.bin obj/stage1.5.bin

obj/bootsector.bin: obj/bootsector.elf
	objcopy -O binary $^ $@
obj/bootsector.elf: obj/bootsector.o
	ld -melf_i386 -T boot/bootsector.ld -o $@ $^
obj/bootsector.o: boot/bootsector.asm | obj
	nasm -f elf32 -g -F dwarf -Ox -o $@ $^

obj/stage1.5.bin: obj/stage1.5.elf
	objcopy -O binary $^ $@
obj/stage1.5.elf: obj/stage1.5.o
	ld -melf_i386 -T boot/stage1.5.ld -o $@ $^
obj/stage1.5.o: boot/stage1.5.asm | obj
	nasm -f elf32 -g -F dwarf -Ox -o $@ $^

current_dir = $(shell pwd)
obj/stage2.bin: $(current_dir)/stage2/target/i686-stage2/release/stage2 | obj
	touch obj/stage2.bin
$(current_dir)/stage2/target/i686-stage2/release/stage2:
	cd stage2 && cargo build --release

-include stage2/target/i686-stage2/release/stage2.d

clean:
	rm -rf obj
	cd stage2 && cargo clean

run: build
	./install.sh
	qemu-system-i386 -drive id=cd0,file=test.img,format=raw
debug: build
	./install.sh
	qemu-system-i386 -drive id=cd0,file=test.img,format=raw -s -S &
	sleep 1
	gdb -x gdb_commands
obj:
	mkdir -p obj

.PHONY: all build clean run debug