#![no_std]
#![feature(global_asm, asm)]
#![feature(abi_x86_interrupt)]
#![feature(naked_functions)]
#![feature(const_fn_union, const_fn_trait_bound)]

mod gdt;
mod interrupts;
mod port;
mod vga;
mod tables;

global_asm!(include_str!("entry.s"));

#[no_mangle]
pub extern "C" fn rust_entry(_drive_number: u32) -> ! {
    vga::clear_screen();
    interrupts::IDT.load();
    colorln!(ColorCode::new(Color::Green, Color::Black), "drive_number = 0x{:x}", _drive_number);
    unsafe { asm!("int 3") }
    println!("test");
    unsafe { asm!("int 3") }
    unsafe { asm!("xor edx, edx; div edx", out("edx") _, out("eax") _)}
    println!("test 2");
    panic!("1");
}

use core::panic::PanicInfo;
use vga::{Color, ColorCode};
const PANIC_COLOR: ColorCode = ColorCode::new(Color::Red, Color::Black);

#[panic_handler]
pub fn panic_handler(info: &PanicInfo) -> ! {
    colorln!(PANIC_COLOR, "{}", info);
    loop {}
}
