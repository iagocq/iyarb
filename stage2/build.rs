extern crate nasm_rs;

fn main() {
    nasm_rs::compile_library_args("stage2asm",
                            &["src/entry.asm", "src/bios_int.asm", "src/mode_switch.asm"],
                             &["-felf32", "-gdwarf"]).unwrap();
}
