S2_ENTRY = 0x0;
BSS = 0xa000;

SECTIONS {
    . = S2_ENTRY;

    .text : {
        *(.text)
    }

    . = BSS;
    .bss : {
        *(.bss)
    }
}