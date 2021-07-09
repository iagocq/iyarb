#![no_std]
#![feature(global_asm, asm)]

mod port;
mod vga;

global_asm!(include_str!("entry.s"));

#[no_mangle]
pub extern "C" fn rust_entry(_drive_number: u32) -> ! {
    println!("oi");

    loop {}
}

use core::panic::PanicInfo;
#[panic_handler]
pub fn panic_handler(_info: &PanicInfo) -> ! {
    loop {}
}
