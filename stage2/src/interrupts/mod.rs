mod idt;

use crate::println;
use lazy_static::lazy_static;
use self::idt::{InterruptDescriptorTable, InterruptStackFrame};

use crate::colorln;
use crate::vga::{Color, ColorCode};
const INT_COLOR: ColorCode = ColorCode::new(Color::Yellow, Color::Black);

lazy_static! {
    pub static ref IDT: InterruptDescriptorTable = {
        let mut idt = InterruptDescriptorTable::new();
        idt[0] = Some(division_error);
        idt[3] = Some(breakpoint);
        idt[6] = Some(invalid_opcode);
        idt
    };
}

fn division_error(stack_frame: &mut InterruptStackFrame) {
    colorln!(INT_COLOR, "Division Error!");
    unsafe { stack_frame.as_mut() }.update(|v| v.eip += 2);
}

fn breakpoint(_stack_frame: &mut InterruptStackFrame) {
    colorln!(INT_COLOR, "Breakpoint!");
}

fn invalid_opcode(stack_frame: &mut InterruptStackFrame) {
    colorln!(INT_COLOR, "Invalid Opcode @ {:x}!", stack_frame.eip);
    loop {}
}
