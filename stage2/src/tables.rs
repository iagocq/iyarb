#[allow(dead_code)]
#[repr(packed)]
pub struct DescriptorTableRegister {
    limit: u16,
    base: u32
}

impl DescriptorTableRegister {
    pub fn new(base: u32, size: u16) -> Self {
        DescriptorTableRegister {
            base,
            limit: size - 1
        }
    }
}

pub unsafe fn lidt(d: DescriptorTableRegister) {
    asm!("lidt [{}]", in(reg) &d);
}
