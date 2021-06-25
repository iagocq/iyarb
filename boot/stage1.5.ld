S15_ENTRY = 0x0;
BSS = 0x0;

SECTIONS {
    . = S15_ENTRY;

    .text : {
        *(.text)
    }

    . = BSS;
    .bss : {
        *(.bss)
    }
}
