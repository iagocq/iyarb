BS_ENTRY = 0x7c00;
BSS = 0xa000;

SECTIONS {
    . = BS_ENTRY;

    .text : {
        *(.text)
    }

    . = BSS;
    .bss : {
        *(.bss)
    }
}