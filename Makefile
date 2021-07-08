all: build
build: obj/boot/stage1.bin obj/boot/stage1.5.bin obj/boot/mbr.bin obj/stage2.bin

obj/%.bin: obj/%.o $(notdir $(basename %)).ld
	ld -melf_i386 -T boot/$(notdir $(basename $<)).ld -o $<.elf $<
	objcopy -O binary $<.elf $@

obj/%.o: %.asm | obj/boot obj/stage2/asm
	nasm -MD $@.d -f elf32 -gdwarf -o $@ $<

-include obj/boot/*.d

obj/stage2.bin: obj/stage2.elf
	objcopy -O binary $< $@
obj/stage2.elf: obj/libstage2.a stage2/stage2.ld | obj
	ld --gc-sections -melf_i386 -T stage2/stage2.ld -o $@ $<

PROFILE := $(or $(PROFILE),debug)
CARGO_FLAGS := $(if $(subst release,,$(PROFILE)),,--release)
CARGO_ENV := CARGO_BUILD_DEP_INFO_BASEDIR="$(shell pwd)"

obj/libstage2.a: stage2/target/i686-stage2/$(PROFILE)/libstage2.a | obj
	cp $^ $@

stage2/target/i686-stage2/$(PROFILE)/libstage2.a:
	cd stage2 && $(CARGO_ENV) cargo build $(CARGO_FLAGS)

-include stage2/target/i686-stage2/$(PROFILE)/libstage2.d

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
