#![allow(dead_code)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u32)]
pub enum QemuExitCode {
    Success = 0x10,
    Failed = 0x11,
}

pub fn exit(exit_code: QemuExitCode) {
    unsafe { asm!("out 0xf4, eax", in("eax") exit_code as u32) };
}
