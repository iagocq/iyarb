.section .entry.text, "awx"
.global _entry
.code16

_entry:
    xor     ax, ax
    mov     ds, ax

    lgdt    [gdt_desc]
    mov     eax, cr0
    or      al, 1
    mov     cr0, eax

    ljmp    0x08, offset enter_pm
.code32
enter_pm:
    mov     ax, 0x10
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    in      al, 0x92    # enable A20 line via Fast A20
    test    al, 2       #
    jnz     after       #
    or      al, 2       #
    and     al, 0xFE    #
    out     0x92, al    #
    after:              #

    mov     esi, offset _phys_start
    mov     edi, offset _reloc_start
    mov     ecx, offset _phys_end
    sub     ecx, esi
    add     ecx, 3
    shr     ecx, 2
.reloc_loop:
    lodsd
    stosd
    loop    .reloc_loop

    xor     eax, eax
    mov     edi, offset _bss_start
    mov     ecx, offset _bss_end
    add     ecx, 3
    shr     ecx, 2
    rep stosd

    jmp     test

.section .entry.rodata, "a"

gdt_desc:
    .limit: .word gdt_end - gdt_start - 1
    .base:  .word gdt_start

gdt_start:
gdt_null:               # selector 0x00
    .quad 0             # must be all zeroes
gdt_code:               # selector 0x08
    .word 0xffff        # limit [ 0:15]
    .word 0x0000        # base  [ 0:15]
    .byte 0x00          # base  [16:25]
    .byte 0b10011010    # S + privilege + P + type (0b1010 => Execute/Read)
    .byte 0b11001111    # granularity + D flag + limit [16:19]
    .byte 0x00          # base  [26:31]
gdt_data:               # selector 0x10
    .word 0xffff        # limit [ 0:15]
    .word 0x0000        # base  [ 0:15]
    .byte 0x00          # base  [16:25]
    .byte 0b10010010    # S + privilege + P + type (0b0010 => Read/Write)
    .byte 0b11001111    # granularity + D flag + limit [16:19]
    .byte 0x00          # base  [26:31]
gdt_end:
