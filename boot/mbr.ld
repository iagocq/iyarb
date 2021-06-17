MBR_ENTRY = 0x0500;
BSS = 0xa000;

SECTIONS {
    . = MBR_ENTRY;

    .text : {
        *(.text)
    }

    . = BSS;
    .bss : {
        *(.bss)
    }
}
