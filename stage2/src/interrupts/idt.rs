#![allow(dead_code)]

use bit_field::BitField;
use lazy_static::lazy_static;
use volatile::Volatile;
use core::{mem::size_of, ops::{Deref, Index, IndexMut}};

use crate::{gdt::{self, SegmentSelector}, tables::{DescriptorTableRegister, lidt}};

/// A type that holds pointers to available interrupt routines.
///
/// Fields are of type Option<RoutineFn>, with present routines
/// being `Some(routine)` and missing routines being `None`.
///
/// Named routines are based on the names on
/// Table 6-1 of the Intel® 64 and IA-32 Architectures Software Developer’s Manual, Volume 3.
pub struct InterruptDescriptorTable {
    pub divide_error: Option<RoutineFn>,
    pub debug: Option<RoutineFn>,
    pub nmi: Option<RoutineFn>,
    pub breakpoint: Option<RoutineFn>,
    pub overflow: Option<RoutineFn>,
    pub bound_range_exceeded: Option<RoutineFn>,
    pub invalid_opcode: Option<RoutineFn>,
    pub device_not_available: Option<RoutineFn>,
    pub double_fault: Option<DivergingRoutineFn>,
    pub coprocessor_segment_overrun: Option<RoutineFn>,
    pub invalid_tss: Option<RoutineFn>,
    pub segment_not_present: Option<RoutineFn>,
    pub stack_fault: Option<RoutineFn>,
    pub general_protection: Option<RoutineFn>,
    pub page_fault: Option<RoutineFn>,
    pub x87_floating_point_error: Option<RoutineFn>,
    pub alignment_check: Option<RoutineFn>,
    pub machine_check: Option<DivergingRoutineFn>,
    pub simd_floating_point_exception: Option<RoutineFn>,
    pub virtualization_exception: Option<RoutineFn>,
    pub control_protection_exception: Option<RoutineFn>,

    /// User defined interrupts.
    interrupts: [Option<RoutineFn>; 256-32],

    /// Static reference to the real IDT.
    real_table: &'static RealInterruptDescriptorTable
}

/// A type that holds the real handlers of the interrupts.
///
/// Load this table with `RealInterruptDescriptorTable#load()`.
#[repr(C)]
struct RealInterruptDescriptorTable {
    entries: [Entry; 256]
}

pub enum InterruptNumber {

}

impl RealInterruptDescriptorTable {
    /// Load this interrupt descriptor table with lidt.
    fn load(&'static self) {
        let desc = DescriptorTableRegister::new(
            self as *const _ as u32, 
            size_of::<Self>() as u16
        );

        unsafe { lidt(desc) }
    }
}

impl InterruptDescriptorTable {
    /// Create a new table with all of its entries missing.
    pub fn new() -> Self {        
        InterruptDescriptorTable {
            divide_error: None,
            debug: None,
            nmi: None,
            breakpoint: None,
            overflow: None,
            bound_range_exceeded: None,
            invalid_opcode: None,
            device_not_available: None,
            double_fault: None,
            coprocessor_segment_overrun: None,
            invalid_tss: None,
            segment_not_present: None,
            stack_fault: None,
            general_protection: None,
            page_fault: None,
            x87_floating_point_error: None,
            alignment_check: None,
            machine_check: None,
            simd_floating_point_exception: None,
            virtualization_exception: None,
            control_protection_exception: None,
            interrupts: [None; 256-32],
            real_table: &REAL_IDT
        }
    }

    /// Put the underlying IDT into effect.
    pub fn load(&'static self) {
        self.real_table.load();
    }
}

impl Index<usize> for InterruptDescriptorTable {
    type Output = Option<RoutineFn>;

    /// Access any (non-diverging) routine from the table as if it were an array.
    fn index(&self, index: usize) -> &Self::Output {
        match index {
            0  => &self.divide_error,
            1  => &self.debug,
            2  => &self.nmi,
            3  => &self.breakpoint,
            4  => &self.overflow,
            5  => &self.bound_range_exceeded,
            6  => &self.invalid_opcode,
            7  => &self.device_not_available,
            9  => &self.coprocessor_segment_overrun,
            10 => &self.invalid_tss,
            11 => &self.segment_not_present,
            12 => &self.stack_fault,
            13 => &self.general_protection,
            14 => &self.page_fault,
            16 => &self.x87_floating_point_error,
            17 => &self.alignment_check,
            19 => &self.simd_floating_point_exception,
            20 => &self.virtualization_exception,
            21 => &self.control_protection_exception,
            i @ 32..=255 => &self.interrupts[i - 32],
            i @ 15 | i @ 31 | i @ 22..=29 => panic!("entry {} is reserved", i),
            i @ 8 | i @ 18 => panic!("entry {} is a diverging exception (must not return)", i),
            i => panic!("no entry with index {}", i),
        }
    }
}

impl IndexMut<usize> for InterruptDescriptorTable {
    /// Get muttable access to any (non-diverging) routine from the table as if it were an array.
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        match index {
            0  => &mut self.divide_error,
            1  => &mut self.debug,
            2  => &mut self.nmi,
            3  => &mut self.breakpoint,
            4  => &mut self.overflow,
            5  => &mut self.bound_range_exceeded,
            6  => &mut self.invalid_opcode,
            7  => &mut self.device_not_available,
            9  => &mut self.coprocessor_segment_overrun,
            10 => &mut self.invalid_tss,
            11 => &mut self.segment_not_present,
            12 => &mut self.stack_fault,
            13 => &mut self.general_protection,
            14 => &mut self.page_fault,
            16 => &mut self.x87_floating_point_error,
            17 => &mut self.alignment_check,
            19 => &mut self.simd_floating_point_exception,
            20 => &mut self.virtualization_exception,
            21 => &mut self.control_protection_exception,
            i @ 32..=255 => &mut self.interrupts[i - 32],
            i @ 15 | i @ 31 | i @ 22..=29 => panic!("entry {} is reserved", i),
            i @ 8 | i @ 18 => panic!("entry {} is a diverging exception (must not return)", i),
            i => panic!("no entry with index {}", i),
        }

    }
}

/// An entry as it should be laid out on the IDT.
#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub struct Entry {
    /// Low 16 bits of the address of the interrupt handler.
    pointer_low: u16,
    /// Selector to the segment the handler is located in.
    gdt_selector: SegmentSelector,
    /// Configurable entry options.
    options: EntryOptions,
    /// High 16 bits of the address of the interrupt handler.
    pointer_high: u16,
}

impl Entry {
    /// Create a new entry with a given selector and handler function.
    fn new(gdt_selector: SegmentSelector, handler: HandlerFn) -> Self {
        let pointer = handler as u32;
        Entry {
            gdt_selector,
            pointer_low: pointer as u16,
            pointer_high: (pointer >> 16) as u16,
            options: EntryOptions::new()
        }
    }

    /// Create an empty entry.
    fn missing() -> Self {
        Entry {
            gdt_selector: SegmentSelector(0),
            pointer_low: 0,
            pointer_high: 0,
            options: EntryOptions::minimal()
        }
    }

    /// Modify this entry's selector and handler.
    fn set_handler_addr(&mut self, gdt_selector: SegmentSelector, addr: u32) -> &mut EntryOptions {
        self.pointer_low = addr as u16;
        self.pointer_high = (addr >> 16) as u16;

        self.gdt_selector = gdt_selector;

        self.options.set_present(true);
        &mut self.options
    }
}

/// Configurable entry options.
///
/// For more info, refer to section 6.11 of the Intel® 64 and IA-32
/// Architectures Software Developer’s Manual, Volume 3.
#[derive(Debug, Clone, Copy)]
#[repr(transparent)]
pub struct EntryOptions(u16);

impl EntryOptions {
    /// Create a minimal set of valid options
    fn minimal() -> Self {
        let mut options = 0;
        options.set_bits(9..=11, 0b111);
        EntryOptions(options)
    }

    /// Create a set of options that has the present bit enabled and that
    /// disables interrupts.
    fn new() -> Self {
        let mut options = Self::minimal();
        options.set_present(true).disable_interrupts(true);
        options
    }

    /// Set the present bit.
    pub fn set_present(&mut self, present: bool) -> &mut Self {
        self.0.set_bit(15, present);
        self
    }

    /// Passing true to this method effectively transforms this interrupt
    /// handler into a trap gate.
    pub fn disable_interrupts(&mut self, disable: bool) -> &mut Self {
        self.0.set_bit(8, !disable);
        self
    }

    /// Set the descriptor privilege level.
    pub fn set_privilege_level(&mut self, dpl: u16) -> &mut Self {
        self.0.set_bits(13..=14, dpl);
        self
    }
}

pub type HandlerFn = unsafe extern "C" fn();

pub type RoutineFn = fn(&mut InterruptStackFrame);
pub type DivergingRoutineFn = fn(&mut InterruptStackFrame) -> !;

/// A stack frame accessible from interrupt routines.
///
/// It stores many register values as indirect fields. `Deref` is impl'd for
/// this type with `Target = InterruptStackFrameValue`, so register values can
/// be read directly, but prohibiting direct modifications.
///
/// To modify the register values, use the `as_mut()` method, then one of the
/// methods provided by `Volatile`, like `update()` or `write()`.
#[repr(transparent)]
pub struct InterruptStackFrame {
    value: InterruptStackFrameValue
}

impl InterruptStackFrame {
    /// Get a `Volatile` mutable reference to the internal value field.
    pub unsafe fn as_mut(&mut self) -> Volatile<&mut InterruptStackFrameValue> {
        Volatile::new(&mut self.value)
    }
}

impl Deref for InterruptStackFrame {
    type Target = InterruptStackFrameValue;

    /// `Deref`'ing instances of this type will let you access the register fields.
    fn deref(&self) -> &Self::Target {
        &self.value
    }
}

#[derive(Clone, Copy)]
#[repr(C)]
pub struct InterruptStackFrameValue {
    pub gs: u32,
    pub fs: u32,
    pub es: u32,
    pub ds: u32,
    pub edi: u32,
    pub esi: u32,
    pub ebp: u32,
    _useless: u32,
    pub ebx: u32,
    pub edx: u32,
    pub ecx: u32,
    pub eax: u32,
    pub int_no: u32,
    pub err_code: u32,
    pub eip: u32,
    pub cs: u32,
    pub eflags: u32,
    pub esp: u32,
    pub ss: u32
}

/// Function that checks for the presence of an interrupt handler then executes it.
#[no_mangle]
extern "C" fn _isr_internal_handler(mut stack_frame: InterruptStackFrame) {
    match stack_frame.int_no {
        8 => (),
        18 => super::IDT.machine_check.unwrap()(&mut stack_frame),
        i => match super::IDT[i as usize] {
            Some(routine) => routine(&mut stack_frame),
            None => panic!("no routine for interrupt number {}", i)
        }
    };
}

use idt_generator::{generate_handlers, generate_handlers_array, generate_handlers_err};

// This section generates the interrupt handlers.
//
// Handlers that don't have error codes push an extra u32 so they have the same
// stack layout as ones that push error codes.
//
// Intel's manual says error codes aren't pushed with software interrupts so
// there's a good chance doing things like int 8 will probably crash the system
//
// TODO: find a way to block soft execution of those interrupts.
generate_handlers!(0, 7);
generate_handlers_err!(8, 8);
generate_handlers!(9, 9);
generate_handlers_err!(10, 14);
generate_handlers!(15, 16);
generate_handlers_err!(17, 17);
generate_handlers!(18, 20);
generate_handlers_err!(21, 21);
generate_handlers!(22, 255);

lazy_static! {
    static ref REAL_IDT: RealInterruptDescriptorTable = {
        let handlers = generate_handlers_array!(0, 255);
        let cs = gdt::cs();

        let mut entries = [Entry::missing(); 256];
        for i in 0..=255 {
            entries[i].set_handler_addr(cs, handlers[i]);
        }

        RealInterruptDescriptorTable {
            entries
        }
    };
}

global_asm!("
    .global _isr_internal_common_stub
    _isr_internal_common_stub:
    pushad
    xor eax, eax
    mov ax, ds
    push eax
    mov ax, es
    push eax
    mov ax, fs
    push eax
    mov ax, gs
    push eax

    cld
    call _isr_internal_handler

    pop eax
    mov ds, ax
    pop eax
    mov es, ax
    pop eax
    mov fs, ax
    pop eax
    mov gs, ax
    popad
    add esp, 8
    iretd
");

// generate_idt!(0..=7, err 8, 9, err 10, err 11..=14, 15, 16, err 17, 18..=20, err 21, 22..=255);
