#![allow(dead_code)]

#[derive(Debug, Clone, Copy)]
#[repr(transparent)]
pub struct SegmentSelector(pub u16);

macro_rules! segment_selector {
    ($selector:ident) => {
        /// Get the current value of the selector register.
        pub fn $selector() -> SegmentSelector {
            let mut s: u16;
            unsafe { asm!(concat!("mov ax, ", stringify!($selector)), out("ax") s) }
            SegmentSelector(s)
        }
    }
}

segment_selector!(cs);
segment_selector!(ds);
segment_selector!(es);
segment_selector!(fs);
segment_selector!(gs);
segment_selector!(ss);
