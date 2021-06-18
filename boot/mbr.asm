[bits 16]

global _start

%define NO_EXT_CODE             'E'
%define NO_ACTIVE_PART_CODE     'P'

%define O_PARTITION_TABLE       0x01BE

section .text

_start:

jmp start
nop

; skip BPB
times 90-($$-$) db 0x41

start:
    cli

    ; we'll copy 512 bytes from 0000:7c00 to 0000:0500
    ; then long jmp to 0000:(0500+.finish_relocation)
    ; so we can load a partition's VBR to 0000:7c00
    ;
    ; until the long jmp, this code believes it is running at 0000:0500
    ; so we can't do other long jmps to other parts of this code until we've relocated
    ; ourselves
    ;
    ; you could also just long jmp to 07c0:xxxx before anything else,
    ; but that would be one avoidable extra long jmp

    xor     ax, ax

    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, 0xfff0

    mov     si, 0x7c00
    mov     di, 0x0500

    mov     cx, 256

    cld
    .copy:
        lodsw
        stosw
        loop .copy

    jmp     0:.finish_relocation
.finish_relocation:
    xor     ax, ax

    ; clear BSS
    mov     di, bss_start
    mov     si, di
    mov     cx, bss_end-bss_start
    rep stosb

    ; save drive number
    mov     [si+drive_number-bss_start], dl

    mov     BYTE [si+read_DAP.size-bss_start], 0x10
    mov     WORD [si+read_DAP.b_segment-bss_start], 0x7c0

    ; read drive parameters
    mov     WORD [si], 0x1a
    mov     ah, 0x48
    int     0x13
    mov     bl, NO_EXT_CODE
    jc      die

    mov     cx, 4
    mov     si, O_PARTITION_TABLE
    add     si, 0x500

entry_loop:
    ; check if partition is flagged as bootable
    test    BYTE [si], 0x80
    jz      .next

    ; lba of the first sector
    mov     eax, [si+0x08]
    mov     bx, 1
    call    read_sectors

    mov     ebp, eax
    mov     bx, 0xe621
    mov     dl, [drive_number]

    jmp     0:0x7c00

.next:
    add     si, 0x10
    loop    entry_loop

    mov     bl, NO_ACTIVE_PART_CODE
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

%include "boot/disk1.asm"

times 440-($-$$) db 0x42
times 510-($-$$) db 0x43

; boot signature
db 0x55, 0xaa

%include "boot/bss.asm"
