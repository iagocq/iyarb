## How it's built

There's a main Makefile in the root of the project, defining useful targets and how to build them.
The most important phony ones are `build`, `test`, `run`, and `debug`.

### The `build` target

`build` takes care of building all of the project's binaries, being them `stage1.bin`, `stage2.bin`, `mbr.bin`, and `stage2.elf`.

- `stage1.bin`, `stage2.bin`, and `mbr.bin` are built straightforwardly,
  with two recipes to generate object files from asm source,
  then linked to a proper .elf, then dumped to a raw binary.
  Makefile includes are also generated, so there's a line to
  include them from the obj folder if they exist.

- ~~`stage2.bin` depends on an asm lib and a Rust lib.
  Both are linked together (with an extra `--gc-sections` flag, because the Rust library includes *a lot* of unused code).
  It is this way so the Rust code is simpler, focusing on higher level details.
  However, I intend to remove the dependency on the separate asm part and just do everything on Rust-land in the future.~~
  - ~~`libstage2asm.a`'s source code is turned into objects with the same rule as stage1.bin and co. The final file is then created with `ar`~~
  - ~~`libstage2rust.a` has a lot of quirks. I need the final file to depend on the lib file cargo generates in the target subdirectory, otherwise
    the Makefile dependency include does not work. So I build it with cargo then cp it to where it's supposed to be.~~

- `stage2.elf` is partly generated from cargo as a static library, then linked with ld and a linker script.
  Later I might just make cargo generate the elf by linking it with a helper script.

### The `test` target

Currently, tests do not work.

### The `run` and `debug` targets

Both depend on the `install` target, that just installs stage1 and stage1.5 to an existing and formatted file.

`run` just runs qemu through the convoluted `run.sh` with no extra options.
`debug` passes some extra options to enable remote debugging and also opens gdb.


## How it's organized

TODO

## What's left to do

- [ ] Add more notes to NOTES.md.
- [x] Move all stage2 code to cargo-land.
- [ ] Implement a vm8086 monitor to run real mode interrupts instead of dropping to real mode to do it.
- [ ] Reimplement a lot of things from the x86_64 crate because their explicit target is only x86_64 platforms
  (even though most of it would work fine on x86).
- [ ] Implement 2-level paging.

## ld

- relocation address: where code and data expect to be at runtime.
- load address: where code and data will be loaded in memory.

stage1.5's short lived elf loader was removed because I got so confused
I didn't realize objcopy already put stuff in the flat binary where it should be
relative to load addresses. Lesson learned.

### The `test` target -- outdated

`test` basically runs cargo test, but the devil is in the details.

cargo is not aware of our build process, and `cargo test` needs to generate runnable binaries instead of libraries that will be linked later.
This presents two problems: to link the library from outside the Makefile so we can have an executable, and to run the tests themselves.

After searching around cargo's documentation, I find there's a way to override the runner in `.cargo/config.toml`.
It points to `run-cargo.sh`, that takes some arguments such as a timeout value and extra arguments to qemu.
That script only runs a .elf cargo passes to it.

The other problem is fixed with another helper script, `stage2/link.sh`.
This one builds the asm library then links it with whatever objects cargo throws at it.
It's made visible to cargo's build process in `stage2/i686-stage2.bin` as a custom linker.

This allows cargo to build and run its own tests. 
The only drawback being that I can't use `cargo run` to run the main code,
because there's a hardcoded timeout option that will kill qemu after some time.
