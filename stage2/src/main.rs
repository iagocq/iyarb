#![no_std]
#![no_main]

#![feature(lang_items, start)]
#![feature(asm)]

use core::panic::PanicInfo;

#[link(name = "stage2asm", kind = "static")]
extern "C" {
    pub fn _entry() -> !;
}

#[no_mangle]
pub extern "C" fn _rust_entry() -> ! {
    loop {}
}

#[panic_handler]
fn panic_handler(_info: &PanicInfo) -> ! {
    loop {}
}
