#![no_std]
#![feature(global_asm, asm)]
#![feature(abi_x86_interrupt)]

mod gdt;
mod interrupts;
mod port;
mod vga;
mod tables;

global_asm!(include_str!("entry.s"));

#[no_mangle]
pub extern "C" fn rust_entry(_drive_number: u32) -> ! {
    interrupts::IDT.load();
    unsafe { asm!("int 3") }
    println!("test");

    loop {}
}

use core::panic::PanicInfo;
#[panic_handler]
pub fn panic_handler(_info: &PanicInfo) -> ! {
    loop {}
}
