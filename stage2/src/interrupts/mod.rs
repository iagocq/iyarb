mod idt;

use crate::println;
use lazy_static::lazy_static;
use self::idt::{InterruptDescriptorTable, InterruptStackFrame};


lazy_static! {
    pub static ref IDT: InterruptDescriptorTable = {
        let mut idt = InterruptDescriptorTable::new();
        idt[0] = Some(division_error);
        idt[3] = Some(breakpoint);
        idt
    };
}

fn division_error(stack_frame: &mut InterruptStackFrame) {
    unsafe { stack_frame.as_mut() }.update(|v| v.eip += 2);
    println!("Division Error!");
}

fn breakpoint(_stack_frame: &mut InterruptStackFrame) {
    println!("Breakpoint!");
}
