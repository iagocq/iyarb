use bit_field::BitField;
use core::{marker::PhantomData, mem::size_of, ops::{Deref, Index, IndexMut}};

use crate::{gdt::{self, SegmentSelector}, tables::{DescriptorTableRegister, lidt}};

pub struct InterruptDescriptorTable {
    pub divide_error: Entry<HandlerFn>,
    pub debug: Entry<HandlerFn>,
    pub nmi: Entry<HandlerFn>,
    pub breakpoint: Entry<HandlerFn>,
    pub overflow: Entry<HandlerFn>,
    pub bound_range_exceeded: Entry<HandlerFn>,
    pub invalid_opcode: Entry<HandlerFn>,
    pub device_not_available: Entry<HandlerFn>,
    pub double_fault: Entry<DivergingHandlerFnWithCode>,
    pub coprocessor_segment_overrun: Entry<HandlerFn>,
    pub invalid_tss: Entry<HandlerFnWithCode>,
    pub segment_not_present: Entry<HandlerFnWithCode>,
    pub stack_fault: Entry<HandlerFnWithCode>,
    pub general_protection: Entry<HandlerFnWithCode>,
    pub page_fault: Entry<HandlerFnWithCode>,
    _reserved_1: Entry<HandlerFn>,
    pub x87_floating_point_error: Entry<HandlerFn>,
    pub alignment_check: Entry<HandlerFnWithCode>,
    pub machine_check: Entry<DivergingHandlerFn>,
    pub simd_floating_point_exception: Entry<HandlerFn>,
    pub virtualization_exception: Entry<HandlerFn>,
    pub control_protection_exception: Entry<HandlerFnWithCode>,
    _reserved_2: [Entry<HandlerFn>; 9],
    interrupts: [Entry<HandlerFn>; 256-32]
}

impl InterruptDescriptorTable {
    pub fn new() -> Self {
        InterruptDescriptorTable {
            divide_error: Entry::missing(),
            debug: Entry::missing(),
            nmi: Entry::missing(),
            breakpoint: Entry::missing(),
            overflow: Entry::missing(),
            bound_range_exceeded: Entry::missing(),
            invalid_opcode: Entry::missing(),
            device_not_available: Entry::missing(),
            double_fault: Entry::missing(),
            coprocessor_segment_overrun: Entry::missing(),
            invalid_tss: Entry::missing(),
            segment_not_present: Entry::missing(),
            stack_fault: Entry::missing(),
            general_protection: Entry::missing(),
            page_fault: Entry::missing(),
            _reserved_1: Entry::missing(),
            x87_floating_point_error: Entry::missing(),
            alignment_check: Entry::missing(),
            machine_check: Entry::missing(),
            simd_floating_point_exception: Entry::missing(),
            virtualization_exception: Entry::missing(),
            control_protection_exception: Entry::missing(),
            _reserved_2: [Entry::missing(); 9],
            interrupts: [Entry::missing(); 256-32],
        }
    }

    pub fn load(&'static self) {
        let desc = DescriptorTableRegister::new(
            self as *const _ as u32, 
            size_of::<Self>() as u16);

        unsafe { lidt(desc) }
    }
}

impl Index<usize> for InterruptDescriptorTable {
    type Output = Entry<HandlerFn>;

    fn index(&self, index: usize) -> &Self::Output {
        match index {
            0 => &self.divide_error,
            1 => &self.debug,
            2 => &self.nmi,
            3 => &self.breakpoint,
            4 => &self.overflow,
            5 => &self.bound_range_exceeded,
            6 => &self.invalid_opcode,
            7 => &self.device_not_available,
            9 => &self.coprocessor_segment_overrun,
            16 => &self.x87_floating_point_error,
            19 => &self.simd_floating_point_exception,
            20 => &self.virtualization_exception,
            i @ 32..=255 => &self.interrupts[i - 32],
            i @ 15 | i @ 31 | i @ 21..=29 => panic!("entry {} is reserved", i),
            i @ 8 | i @ 10..=14 | i @ 17 | i @ 30 => {
                panic!("entry {} is an exception with error code", i)
            }
            i @ 18 => panic!("entry {} is an diverging exception (must not return)", i),
            i => panic!("no entry with index {}", i),
        }

    }
}

impl IndexMut<usize> for InterruptDescriptorTable {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        match index {
            0 => &mut self.divide_error,
            1 => &mut self.debug,
            2 => &mut self.nmi,
            3 => &mut self.breakpoint,
            4 => &mut self.overflow,
            5 => &mut self.bound_range_exceeded,
            6 => &mut self.invalid_opcode,
            7 => &mut self.device_not_available,
            9 => &mut self.coprocessor_segment_overrun,
            16 => &mut self.x87_floating_point_error,
            19 => &mut self.simd_floating_point_exception,
            20 => &mut self.virtualization_exception,
            i @ 32..=255 => &mut self.interrupts[i - 32],
            i @ 15 | i @ 31 | i @ 21..=29 => panic!("entry {} is reserved", i),
            i @ 8 | i @ 10..=14 | i @ 17 | i @ 30 => {
                panic!("entry {} is an exception with error code", i)
            }
            i @ 18 => panic!("entry {} is an diverging exception (must not return)", i),
            i => panic!("no entry with index {}", i),
        }

    }
}

#[derive(Debug, Clone, Copy)]
#[repr(C)]
pub struct Entry<F> {
    pointer_low: u16,
    gdt_selector: SegmentSelector,
    options: EntryOptions,
    pointer_high: u16,
    phantom: PhantomData<F>
}

impl<F> Entry<F> {
    fn new(gdt_selector: SegmentSelector, handler: HandlerFn) -> Self {
        let pointer = handler as u32;
        Entry {
            gdt_selector,
            pointer_low: pointer as u16,
            pointer_high: (pointer >> 16) as u16,
            options: EntryOptions::new(),
            phantom: PhantomData::default()
        }
    }

    fn missing() -> Self {
        Entry {
            gdt_selector: SegmentSelector(0),
            pointer_low: 0,
            pointer_high: 0,
            options: EntryOptions::minimal(),
            phantom: PhantomData::default()
        }
    }

    fn set_handler_addr(&mut self, addr: u32) -> &mut EntryOptions {
        self.pointer_low = addr as u16;
        self.pointer_high = (addr >> 16) as u16;

        self.gdt_selector = gdt::cs();

        self.options.set_present(true);
        &mut self.options
    }
}

#[derive(Debug, Clone, Copy)]
#[repr(transparent)]
pub struct EntryOptions(u16);

impl EntryOptions {
    fn minimal() -> Self {
        let mut options = 0;
        options.set_bits(9..=11, 0b111);
        EntryOptions(options)
    }

    fn new() -> Self {
        let mut options = Self::minimal();
        options.set_present(true).disable_interrupts(true);
        options
    }

    pub fn set_present(&mut self, present: bool) -> &mut Self {
        self.0.set_bit(15, present);
        self
    }

    /// Effectively transform this interrupt handler into a trap gate
    pub fn disable_interrupts(&mut self, disable: bool) -> &mut Self {
        self.0.set_bit(8, !disable);
        self
    }

    pub fn set_privilege_level(&mut self, dpl: u16) -> &mut Self {
        self.0.set_bits(13..=14, dpl);
        self
    }
}

pub type HandlerFn = extern "x86-interrupt" fn(InterruptStackFrame);
pub type HandlerFnWithCode = extern "x86-interrupt" fn(InterruptStackFrame, u32);
pub type DivergingHandlerFn = extern "x86-interrupt" fn(InterruptStackFrame) -> !;
pub type DivergingHandlerFnWithCode = extern "x86-interrupt" fn(InterruptStackFrame, u32) -> !;

macro_rules! impl_set_handler {
    ($h:ty) => {
        impl Entry<$h> {
            pub fn set_handler(&mut self, handler: $h) -> &mut EntryOptions {
                self.set_handler_addr(handler as u32)
            }
        }
    }
}

impl_set_handler!(HandlerFn);
impl_set_handler!(HandlerFnWithCode);
impl_set_handler!(DivergingHandlerFn);
impl_set_handler!(DivergingHandlerFnWithCode);

#[repr(transparent)]
pub struct InterruptStackFrame {
    value: InterruptStackFrameValue
}

impl Deref for InterruptStackFrame {
    type Target = InterruptStackFrameValue;

    fn deref(&self) -> &Self::Target {
        &self.value
    }
}

#[repr(C)]
pub struct InterruptStackFrameValue {
    pub instruction_pointer: u32,
    pub code_segment: u16,
    pub eflags: u32
}
