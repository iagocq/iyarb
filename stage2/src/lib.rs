#![no_std]
#![cfg_attr(test, no_main)]
#![feature(asm, custom_test_frameworks)]
#![test_runner(crate::test_runner)]
#![reexport_test_harness_main = "test_main"]

pub mod vga_screen;
mod qemu;

#[no_mangle]
pub extern "C" fn _rust_entry() -> ! {
    println!("}}welcome to stage2");

    #[cfg(test)]
    test_main();

    loop {}
}

use core::panic::PanicInfo;
#[cfg(not(test))]
#[panic_handler]
pub fn panic_handler(info: &PanicInfo) -> ! {
    println!("Panic: {}\n", info);
    loop {}
}

pub fn test_runner(tests: &[&dyn Fn()]) {
    println!("Running {} tests", tests.len());

    for test in tests {
        test();
    }

    //qemu::exit(qemu::QemuExitCode::Success);
}

#[cfg(test)]
#[panic_handler]
pub fn test_panic_handler(info: &PanicInfo) -> ! {
    println!("[failed]\n");
    println!("Error: {}\n", info);
    loop {}
}

#[test_case]
fn trivial_assertion() {
    print!("trivial assertion... ");
    assert_eq!(1, 2);
    println!("[ok]");
}
