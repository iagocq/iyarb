[default rel]
[bits 16]

%define read_buffer_segment     0x50

%define STAGE2_NOT_FOUND_CODE   '2'

section .text

start:
    ; copy bss from 0000:a000 to 6ff0:0000
    mov     cx, (bss_end-bss_start+1)/2
    mov     si, 0xa000
    xor     di, di
    mov     ax, 0x6ff0
    mov     es, ax
    push    ax      ; save bss segment

    .copy_bss:
        lodsw
        stosw
        loop    .copy_bss

    pop     ds      ; load bss segment to ds

    mov     ax, read_buffer_segment
    mov     fs, ax
    mov     [read_DAP.b_segment], ax

    ; copy stage2 path string to bss
    mov     si, stage2_path_far
    mov     di, stage2_path
    push    di

    push    ds
    mov     ax, cs
    mov     ds, ax
    mov     cx, 23
    .copy_path:
        lodsb
        stosb
        loop    .copy_path
    pop     ds

    pop     di      ; load stage2_path
    mov     eax, 2  ; root directory cluster
    %include "boot/find.asm"

    ; prepare cx to be added to the buffer segment every iteration
    push    eax
    mov     eax, [bytes_per_psector]
    shr     eax, 4
    mul     DWORD [psectors_per_cluster]
    mov     cx, ax
    pop     eax
load_loop:
    push    eax
    call    read_cluster

    mov     ax, fs
    add     ax, cx
    mov     fs, ax
    mov     [read_DAP.b_segment], ax

    pop     eax
    call    next_cluster
    cmp     eax, 0x0FFFFFF7
    jb      load_loop

.done:
    xor     edx, edx
    mov     dl, [drive_number]

    lgdt    [cs:gdt_desc]   ; load gdt

    mov     eax, cr0        ; set PE bit
    or      al, 1           ;
    mov     cr0, eax        ;

    jmp     0x08:enter_pm
[bits 32]
enter_pm:
    mov     ax, 0x18
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    push    edx
    jmp     0x10:(read_buffer_segment << 4)
[bits 16]

not_found_die:
    mov     bl, STAGE2_NOT_FOUND_CODE

die:
    mov     bh, 0x4f
direct_die:
    mov     ax, 0xb800
    mov     es, ax
    mov     [es:0], bx

    ; die, but not on a busy loop
    cli
.loop_forever:
    hlt
    jmp     .loop_forever

%include "boot/disk.asm"

stage2_path_far: db 'BOOT       STAGE2     $'

gdt:

.null:              ; selector 0x00
    times 8 db 0    ; must be all zeroes

.code_high:         ; selector 0x08
    dw 0xffff       ; limit [ 0:15]
    dw 0x0000       ; base  [ 0:15]
    db 0x07         ; base  [16:25]
    db 0b10011010   ; S + privilege + P + type (0b1010 => Execute/Read)
    db 0b11001111   ; granularity + D flag + limit [16:19]
    db 0x00         ; base  [26:31]

.code_low:          ; selector 0x10
    dw 0xffff       ; limit [ 0:15]
    dw 0x0000       ; base  [ 0:15]
    db 0x00         ; base  [16:25]
    db 0b10011010   ; S + privilege + P + type (0b1010 => Execute/Read)
    db 0b11001111   ; granularity + D flag + limit [16:19]
    db 0x00         ; base  [26:31]

.data_low:          ; selector 0x18
    dw 0xffff       ; limit [ 0:15]
    dw 0x0000       ; base  [ 0:15]
    db 0x00         ; base  [16:25]
    db 0b10010010   ; S + privilege + P + type (0b0010 => Read/Write)
    db 0b11001111   ; granularity + D flag + limit [16:19]
    db 0x00         ; base  [26:31]

.end:

gdt_desc:
    .limit: dw gdt.end-gdt-1
    .base:  dd 0x70000+gdt

times 512-($-$$) db 0x44

%include "boot/bss.asm"
