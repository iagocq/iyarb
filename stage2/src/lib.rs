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
    unsafe { asm!("int 3") }
    println!("test");
    unsafe { asm!("int 3") }
    unsafe { asm!("xor edx, edx; div edx", out("edx") _, out("eax") _)}
    println!("test 2");
    loop {}
}

use core::panic::PanicInfo;
#[panic_handler]
pub fn panic_handler(info: &PanicInfo) -> ! {
    use vga::{ColorCode, Color};
    colorln!(ColorCode::new(Color::LightRed, Color::Black), "{}", info);
    loop {}
}
