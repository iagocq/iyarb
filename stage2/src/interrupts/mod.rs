mod idt;

use crate::{port::Port, println};
use lazy_static::lazy_static;
use self::idt::{InterruptDescriptorTable, InterruptStackFrame};


lazy_static! {
    pub static ref IDT: InterruptDescriptorTable = {
        let mut idt = InterruptDescriptorTable::new();
        idt[0].set_handler(division_error);
        idt
    };
}

extern "x86-interrupt" fn division_error(stack_frame: InterruptStackFrame) {
    println!("Division Error!")
}
