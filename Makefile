all: build
build: obj/boot/stage1.bin obj/boot/stage1.5.bin obj/boot/mbr.bin obj/stage2.bin

obj/%.bin: obj/%.o
	ld -melf_i386 -T boot/$(notdir $(basename $<)).ld -o $<.elf $<
	objcopy -O binary $<.elf $@

obj/%.o: %.asm | obj/boot obj/stage2/asm
	nasm -MD $@.d -f elf32 -gdwarf -o $@ $<

-include obj/boot/*.d

obj/stage2.bin: obj/stage2.elf
	objcopy -O binary $^ $@
obj/stage2.elf: obj/libstage2asm.a obj/libstage2rust.a | obj
	ld --gc-sections -melf_i386 -T stage2/stage2.ld -o $@ $^

PROFILE := $(or $(PROFILE),debug)
CARGO_FLAGS := $(if $(subst release,,$(PROFILE)),,--release)

obj/libstage2rust.a: stage2/target/i686-stage2/$(PROFILE)/libstage2rust.a | obj
	cp $^ $@
stage2/target/i686-stage2/$(PROFILE)/libstage2rust.a:
	cd stage2 && cargo build $(CARGO_FLAGS)

obj/libstage2asm.a: obj/stage2/asm/bios_int.o obj/stage2/asm/entry.o obj/stage2/asm/mode_switch.o
	ar cr $@ $^

-include stage2/target/i686-stage2/$(PROFILE)/libstage2rust.d
-include obj/stage2/asm/*.d

obj obj/boot obj/stage2/asm:
	mkdir -p $@

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

test:
	cd stage2 && cargo test --tests

.PHONY: all build clean install run debug test
