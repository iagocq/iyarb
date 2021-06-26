ENTRY(_entry)

SECTIONS {
    . = 0x500;

    .text : ALIGN(8) {
        *(.entry)
        *(.text .text.*)
    }

    .data : ALIGN(8) {
        *(.data .data.*)
    }

    .rodata : ALIGN(8) {
        *(.rodata .rodata.*)
    }

    .bss : ALIGN(8) {
        _bss_start = .;
        *(.bss)
        _bss_end = .;
    }
}
