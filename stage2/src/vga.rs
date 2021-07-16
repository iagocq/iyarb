//! Interface for the VGA screen buffer and cursor.
//!
//! Provides utilities to manipulate the screen,
//! like printing strings and clearing and scrolling the screen

use spin::Mutex;

lazy_static! {
    pub static ref WRITER: Mutex<Writer> = {
        let writer = Writer {
            col: 0,
            row: 0,
            color: ColorCode::new(Color::LightGray, Color::Black),
            blank: ScreenCell {
                color: ColorCode::new(Color::LightGray, Color::Black),
                character: 0
            },
            buffer: unsafe { &mut *(0xb8000 as *mut Buffer) }
        };
        Mutex::new(writer)
    };
}

#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => ($crate::vga::_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! println {
    () => ($crate::print!("\n"));
    ($($arg:tt)*) => ($crate::print!("{}\n", format_args!($($arg)*)));
}

#[macro_export]
macro_rules! colorln {
    ($color:expr, $($arg:tt)*) => {{
        let old_color = $crate::vga::WRITER.lock().color;
        $crate::vga::WRITER.lock().color = $color;
        println!($($arg)*);
        $crate::vga::WRITER.lock().color = old_color;
    }}
}

#[doc(hidden)]
pub fn _print(args: fmt::Arguments) {
    use core::fmt::Write;
    WRITER.lock().write_fmt(args).unwrap();
}

/// Enum of all VGA colors
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum Color {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    Pink = 13,
    Yellow = 14,
    White = 15,
}

impl From<u8> for Color {
    fn from(b: u8) -> Self {
        let b = b & 0x0f;
        match b {
            0 => Color::Black,
            1 => Color::Blue,
            2 => Color::Green,
            3 => Color::Cyan,
            4 => Color::Red,
            5 => Color::Magenta,
            6 => Color::Brown,
            7 => Color::LightGray,
            8 => Color::DarkGray,
            9 => Color::LightBlue,
            10 => Color::LightGreen,
            11 => Color::LightCyan,
            12 => Color::LightRed,
            13 => Color::Pink,
            14 => Color::Yellow,
            _ => Color::White,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(transparent)]
pub struct ColorCode(u8);

impl ColorCode {
    pub const fn new(foreground: Color, background: Color) -> ColorCode {
        let color = (background as u8) << 4 | (foreground as u8);
        ColorCode(color)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(C)]
struct ScreenCell {
    character: u8,
    color: ColorCode
}

use core::ops::Deref;
impl Deref for ScreenCell {
    type Target = ScreenCell;

    fn deref(&self) -> &Self::Target {
        self
    }
}

use core::ops::DerefMut;
impl DerefMut for ScreenCell {
    fn deref_mut(&mut self) -> &mut Self::Target {
        self
    }
}

const BUFFER_WIDTH: usize = 80;
const BUFFER_HEIGHT: usize = 25;

use lazy_static::lazy_static;
use volatile::Volatile;

#[repr(transparent)]
struct Buffer {
    chars: [[Volatile<ScreenCell>; BUFFER_WIDTH]; BUFFER_HEIGHT]
}

pub struct Writer {
    col: usize,
    row: usize,
    pub color: ColorCode,
    blank: ScreenCell,
    buffer: &'static mut Buffer
}

const VGA_CRTC_REG_ADDR: u16 = 0x3D4;
const VGA_CRTC_REG_DATA: u16 = 0x3D5;

impl Writer {

    /// Write a byte to the screen buffer and advance the cursor
    pub fn write_byte(&mut self, byte: u8) {
        match byte {
            b'\n' => self.new_line(),
            b'\r' => self.carriage_return(),
            byte => {
                if self.col >= BUFFER_WIDTH {
                    self.new_line();
                }

                self.buffer.chars[self.row][self.col].write(ScreenCell {
                    character: byte,
                    color: self.color
                });

                self.col += 1;
            }
        }
        self.update_cursor();
    }
    
    /// Clear the entire screen.
    pub fn clear_screen(&mut self) {
        for i in 0..BUFFER_HEIGHT {
            self.clear_row(i);
        }
        self.col = 0;
        self.row = 0;
        self.update_cursor();
    }

    /// Write the string `s` to the screen.
    pub fn write_string(&mut self, s: &str) {
        let mut escape = false;
        for byte in s.bytes() {
            match byte {
                0x20..=0x7e | b'\n' | b'\r' if !escape => self.write_byte(byte),
                0x1b => escape = true,
                code if escape => {
                    self.escape_code(code);
                    escape = false;
                },
                _ => self.write_byte(0xfe)
            }
        }
    }

    /// Change the current color used to print new text.
    /*
    pub fn set_color(&mut self, color: ColorCode) {
        self.color = color;
    }
    */

    /// Move the cursor to a new line, scrolling the screen as necessary.
    fn new_line(&mut self) {
        self.col = 0;
        self.row += 1;
        if self.row >= BUFFER_HEIGHT {
            self.scroll(1);
            self.row = BUFFER_HEIGHT - 1;
        }
    }

    /// Move the cursor to the beginning of the current line.
    fn carriage_return(&mut self) {
        self.col = 0;
    }

    /// Scroll `n` lines of the screen upwards and clear the last `n` lines.
    fn scroll(&mut self, n: usize) {
        for i in 0..(BUFFER_HEIGHT-n) {
            for j in 0..BUFFER_WIDTH {
                self.buffer.chars[i][j].write(self.buffer.chars[i+n][j].read())
            }
        }

        for i in (BUFFER_HEIGHT-n)..BUFFER_HEIGHT {
            self.clear_row(i);
        }
    }

    /// Clear a line.
    fn clear_row(&mut self, line: usize) {
        for i in 0..BUFFER_WIDTH {
            self.buffer.chars[line][i].write(self.blank);
        }
    }

    /// React to an escape code byte.
    fn escape_code(&mut self, byte: u8) {
        let foreground: Color = byte.into();
        let background: Color = (byte >> 4).into();

        self.color = ColorCode::new(foreground, background);
    }

    /// Tell the VGA hardware to update the cursor position to our internal one.
    fn update_cursor(&self) {
        unsafe { self.set_cursor_position(self.col, self.row); }
    }

    fn calc_offset(&self, col: usize, row: usize) -> u16 {
        (row * BUFFER_WIDTH + col) as u16
    }

    /// Set the hardware cursor position directly
    unsafe fn set_cursor_position(&self, col: usize, row: usize) {
        let addr = crate::port::Port::new(VGA_CRTC_REG_ADDR);
        let data = crate::port::Port::new(VGA_CRTC_REG_DATA);
        let offset = self.calc_offset(col, row);

        // Save the current index to restore before returning
        let last_index = addr.read_u8();

        // Select the Cursor Location High Register
        addr.write_u8(0x0e);
        data.write_u8((offset >> 8) as u8);
    
        // Select the Cursor Location Low Register
        addr.write_u8(0x0f);
        data.write_u8((offset & 0xff) as u8);

        addr.write_u8(last_index);
    }
}

pub fn clear_screen() {
    WRITER.lock().clear_screen();
}

use core::fmt;

impl fmt::Write for Writer {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.write_string(s);
        Ok(())
    }
}
