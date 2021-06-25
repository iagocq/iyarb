#![no_std]
#![no_main]

#![feature(asm)]

use core::panic::PanicInfo;

#[no_mangle]
pub extern "C" fn _start() -> ! {
    unsafe {
        asm!(
            "nop",
            "mov eax, 1"
        );
    }

    loop {}
}

#[panic_handler]
fn panic_handler(_info: &PanicInfo) -> ! {
    loop {}
}
