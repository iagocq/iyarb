#![no_std]
#![feature(global_asm)]

global_asm!(include_str!("entry.s"));

#[no_mangle]
pub extern "C" fn test(_drive_number: u32) -> ! {
    unsafe {
        let vga = 0xb8000 as *mut u64;

        *vga = 0x2f592f412f4b2f4f;
    };

    loop {}
}

use core::panic::PanicInfo;
#[panic_handler]
pub fn panic_handler(_info: &PanicInfo) -> ! {
    loop {}
}
