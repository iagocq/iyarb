global enter_protected_mode
global enter_real_mode

section .text

[bits 16]
enter_protected_mode:
    pop     cx
    push    eax

    xor     ax, ax
    mov     ds, ax
    lgdt    [gdt_desc]

    mov     eax, cr0
    or      eax, 1
    mov     cr0, eax
    jmp     0x08:.enter_pm
[bits 32]
.enter_pm:
    mov     ax, 0x10
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    pop     eax
    and     ecx, 0x0000FFFF
    push    ecx
    ret

[bits 32]
enter_real_mode:
    pop     ecx
    push    eax

    jmp     0x18:.enter_pm_16
[bits 16]
.enter_pm_16:
    mov     ax, 0x20
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    mov     eax, cr0
    and     al, 0xFE
    mov     cr0, eax

    lidt    [idt_desc]

    jmp     0:.real_mode
.real_mode:
    mov     ax, 0
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    pop     eax
    push    cx
    ret

section .data
gdt:

.null:              ; null selector
    times 8 db 0    ; must be all zeroes

.code:              ; selector 0x08
    dw 0xffff       ; limit [ 0:15]
    dw 0x0000       ; base  [ 0:15]
    db 0x00         ; base  [16:25]
    db 0b10011010   ; S + privilege + P + type (0b1010 => Execute/Read)
    db 0b11001111   ; granularity + D flag + limit [16:19]
    db 0x00         ; base  [26:31]

.data:              ; selector 0x10
    dw 0xffff       ; limit [ 0:15]
    dw 0x0000       ; base  [ 0:15]
    db 0x00         ; base  [16:25]
    db 0b10010010   ; S + privilege + P + type (0b0010 => Read/Write)
    db 0b11001111   ; granularity + D flag + limit [16:19]
    db 0x00         ; base  [26:31]

.code_16:           ; selector 0x18
    dw 0xffff       ; limit [ 0:15]
    dw 0x0000       ; base  [ 0:15]
    db 0x00         ; base  [16:25]
    db 0b10011010   ; S + privilege + P + type (0b1010 => Execute/Read)
    db 0b00001111   ; limit [16:19]
    db 0x00         ; base  [26:31]

.data_16:           ; selector 0x20
    dw 0xffff       ; limit [ 0:15]
    dw 0x0000       ; base  [ 0:15]
    db 0x00         ; base  [16:25]
    db 0b10010010   ; S + privilege + P + type (0b0010 => Read/Write)
    db 0b00001111   ; limit [16:19]
    db 0x00         ; base  [26:31]

.end:

gdt_desc:
    .limit: dw gdt.end-gdt-1
    .base:  dd gdt

idt_desc:
    .limit: dw 0x3FF
    .base:  dd 0
