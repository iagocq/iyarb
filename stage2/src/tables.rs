/// A type used for `lidtr`- and `lgdtr`-type instructions.
#[allow(dead_code)]
#[repr(packed)]
pub struct DescriptorTableRegister {
    limit: u16,
    base: u32
}

impl DescriptorTableRegister {
    /// Create a new register value from a `base` and `size` of the table.
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
