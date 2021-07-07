#![no_std]
#![feature(global_asm)]

global_asm!(include_str!("entry.s"));

#[no_mangle]
pub extern "C" fn test() -> ! {
    loop {}
}

use core::panic::PanicInfo;
#[panic_handler]
pub fn panic_handler(_info: &PanicInfo) -> ! {
    loop {}
}
