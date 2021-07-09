//! Interface for communicating with x86 IO ports

pub struct Port(u16);

impl Port {
    pub fn new(number: u16) -> Port {
        Port(number)
    }

    /// Write an u8 into the port.
    pub fn write_u8(&self, byte: u8) {
        unsafe { asm!("out dx, al", in("al") byte, in("dx") self.0) }
    }
    
    /// Write an u16 into the port.
    pub fn write_u16(&self, word: u16) {
        unsafe { asm!("out dx, ax", in("ax") word, in("dx") self.0) }
    }

    /// Write an u32 into the port.
    pub fn write_u32(&self, dword: u32) {
        unsafe { asm!("out dx, eax", in("eax") dword, in("dx") self.0) }
    }

    /// Read an u8 from the port.
    pub fn read_u8(&self) -> u8 {
        let mut byte;
        unsafe { asm!("in al, dx", out("al") byte, in("dx") self.0) }
        byte
    }

    /// Read an u16 from the port.
    pub fn read_u16(&self) -> u16 {
        let mut word;
        unsafe { asm!("in ax, dx", out("ax") word, in("dx") self.0) }
        word
    }
    
    /// Read an u32 from the port.
    pub fn read_u32(&self) -> u32 {
        let mut dword;
        unsafe { asm!("in eax, dx", out("eax") dword, in("dx") self.0) }
        dword
    }
}
