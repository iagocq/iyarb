[default rel]
[bits 16]

%define read_buffer_segment     0x2000

%define STAGE2_NOT_FOUND_CODE   '2'

section .text

start:
    mov     ax, read_buffer_segment
    mov     fs, ax
    mov     [read_DAP.b_segment], ax


    ; Copy stage2 path string to bss
    mov     si, stage2_path_far
    mov     di, stage2_path
    push    di

    push    ds
    mov     ax, cs
    mov     ds, ax
    mov     cx, 23
    .copy:
        lodsb
        stosb
        loop    .copy
    pop     ds

    pop     di
    mov     eax, 2
    %include "boot/find.asm"

    ; prepare cx to be added to the buffer segment every iteration
    push    eax
    mov     eax, [bytes_per_psector]
    shr     eax, 4
    mul     DWORD [psectors_per_cluster]
    mov     cx, ax
    pop     eax
load_loop:
    call    read_cluster
    push    ax

    mov     ax, fs
    add     ax, cx

    mov     fs, ax
    mov     [read_DAP.b_segment], ax

    pop     ax

    call    next_cluster
    cmp     eax, 0x0FFFFFF7
    jb      load_loop

.done:
    mov     dl, [drive_number]
    mov     ax, read_buffer_segment
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    jmp     read_buffer_segment:0

not_found_die:
    mov     bl, STAGE2_NOT_FOUND_CODE
    jmp     die

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

times 512-($-$$) db 0x44

%include "boot/bss.asm"
