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

relocate_elf:
    xor     ebx, ebx
    mov     edx, ebx

    mov     ax, read_buffer_segment ;
    mov     ds, ax                  ; use ds as a helper for reading values from the elf
    mov     esi, [0x1c]             ; offset of the program header table
    mov     bp, si

    mov     cx, [0x2c]              ; number of entries in the program header table
    mov     di, cx                  ; save that number
    mov     ax, [0x2a]              ; size of an entry
    mov     bx, ax                  ; save the size
    mul     cx                      ; ax = entry_size * n_entries
                                    ; assuming the total size is not enormous
    mov     dx, di
    mov     cx, ax                  ; cx = ax

    mov     ax, es
    mov     gs, ax

    mov     di, prog_headers
    push    di
.save_ph:
    lodsb
    stosb
    loop    .save_ph

    mov     cx, dx
    pop     dx
    mov     ebp, (read_buffer_segment << 4)
.phe_loop:
    mov     eax, [gs:edx]           ; segment type
    cmp     eax, 0x00000001         ; loadable segment
    push    cx
    jne     .next
    xor     cx, cx

    mov     esi, [gs:edx+0x04]      ; offset of segment in image
    mov     edi, [gs:edx+0x0c]      ; physical address
    test    esi, esi                ; first entry is (hopefully) in the correct place
    jnz     .no_hack
    mov     esi, ebp                ; hack to skip first 0x500 bytes of file, otherwise bad things happen
    mov     edi, ebp                ;

    cmp     dx, prog_headers        ;
    jnz     .no_hack                ;
    mov     cx, bx                  ; skip first 0x500 bytes if it's the first section too
    neg     cx
.no_hack:
    add     esi, ebp                ; add an offset to esi because the image wasn't loaded at 0x0000

    mov     eax, esi                ;
    and     esi, 0x0000000f         ; esi = offset & 0x0000000f
    shr     eax, 4                  ; eax = offset >> 4
    mov     ds, ax

    mov     eax, edi                ;
    and     edi, 0x0000000f         ; edi = addr & 0x0000000f
    shr     eax, 4                  ; eax = addr >> 4
    mov     es, ax

    add     cx, [gs:edx+0x10]       ; segment size in image
    jz      .next
.relocate:
    lodsb
    stosb
    loop    .relocate
.next:
    pop     cx
    add     dx, bx
    loop    .phe_loop
.done:
    movzx   edx, BYTE [gs:drive_number]

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

stage2_path_far: db 'BOOT       STAGE2  ELF$'

times 512-($-$$) db 0x44

%include "boot/bss.asm"
prog_headers:   resb 256
