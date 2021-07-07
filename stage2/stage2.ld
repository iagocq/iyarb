ENTRY(_entry)

SECTIONS {
    . = 0x500;

    .entry 0x500 : AT ( 0x500 ) {
        *(.entry*)
    }

    .text 0x100000 : AT ( ADDR(.entry) + SIZEOF(.entry) ) {
        *(.text*)
    }

    .data : ALIGN(8) {
        *(.data*)
    }

    .rodata : ALIGN(8) {
        *(.rodata*)
    }

    .bss : ALIGN(8) {
        _bss_start = .;
        *(.bss)
        _bss_end = .;
    }
}
