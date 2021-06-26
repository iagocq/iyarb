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
    movzx   edx, BYTE [drive_number]

    xor     ax, ax
    mov     ds, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    mov     ss, ax

    push    edx
    jmp     0:(read_buffer_segment << 4)

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

times 512-($-$$) db 0x44

%include "boot/bss.asm"
