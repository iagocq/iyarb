ENTRY(_entry)

SECTIONS {
    . = 0x500;

    .entry 0x500 : AT(0x500) {
        *(.entry*);
    }

    _phys_start = ADDR(.entry) + SIZEOF(.entry);
    .text 0x100000 : AT(_phys_start) {
        _reloc_start = .;
        *(.text* .data* .rodata*);
        . = ALIGN(8);
        _reloc_end = .;
    }
    _phys_end = _phys_start + SIZEOF(.text);

    _phys_stack_start = _phys_end;
    .stack 0x200000 : AT(_phys_stack_start) {
        _stack_bottom = .;
        . += 0xfffff;
        _stack_top = .;
    }

    .bss : ALIGN(8) {
        _bss_start = .;
        *(.bss);
        _bss_end = .;
    }

}
