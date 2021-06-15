[default rel]
[bits 16]

global _start

%define read_buffer_segment     0x1000

%define NO_EXT_CODE             'E'
%define STAGE15_NOT_FOUND_CODE  '1'

%define O_BYTES_PER_LSECTOR     (_start+0x0b)
%define O_LSECTORS_PER_CLUSTER  (_start+0x0d)
%define O_RESERVED_LSECTORS     (_start+0x0e)
%define O_NFATS                 (_start+0x10)
%define O_LSECTORS_PER_FAT      (_start+0x24)
%define O_ROOT_CLUSTER          (_start+0x2c)

section .text

_start:

jmp start
nop

; skip BPB
times 90-($$-$) db 0x41

start:
    cli

    jmp     0:.clear_cs     ; clear segment registers
.clear_cs:                  ;
    xor     ax, ax          ;
    mov     ds, ax          ;
    mov     es, ax          ;
    mov     ss, ax          ;

    mov     ax, read_buffer_segment
    mov     fs, ax

    ; clear BSS
    mov     di, bss_start
    mov     cx, bss_end-bss_start
    rep stosb

    mov     [read_DAP.b_segment], ax

    ; stack @ 0000:7ff0
    mov     sp, 0x7ff0

    ; save drive number
    mov     [drive_number], dl

    mov     BYTE [read_DAP.size], 0x10
    
    ; read drive parameters
    mov     si, ext_DAP
    mov     WORD [si], 0x1A
    mov     ah, 0x48
    int     0x13
    jc      no_ext_die

    ; calculate and cache useful values

    ; psectors_per_lsector_lg = log2(bytes_per_lsector / bytes_per_psector)
    ;                         = log2(bpls) - log2(bpps)
    mov     di, WORD [si+24] ; ext_DAP.bpps
    mov     [bytes_per_psector], di
    bsr     di, di
    bsr     cx, [O_BYTES_PER_LSECTOR]
    sub     cx, di

    movzx   eax, BYTE [O_LSECTORS_PER_CLUSTER]
    shl     eax, cl
    mov     [psectors_per_cluster], eax

    ; entries = bytes_per_cluster / 0x20 =>
    ; log2(entries) = log2(bpc / 32)
    ;               = log2(bpc) - log2(32)
    ;               = log2(bpc) - 5
    ; bpc = psectors_per_cluster * bytes_per_psector
    ; log2(bpc) = log2(psectors_per_cluster) + log2(bpps)
    ; log2(entries) = log2(psectors_per_cluster) + log2(bpps) - 5
    bsr     ebp, eax
    add     bp, di
    sub     bp, 5

    ; data_start = ((nfats * lsectors_per_fat) + reserved_lsectors) << psectors_per_lsector_lg

    ; nfats * lsectors_per_fat
    movzx   eax, BYTE [O_NFATS]
    mul     DWORD [O_LSECTORS_PER_FAT]
    
    ; + reserved_lsectors
    movzx   edx, WORD [O_RESERVED_LSECTORS]
    add     eax, edx

    ; save fat_start
    shl     edx, cl
    mov     [fat_start], edx

    ; << psectors_per_lsector_lg
    shl     eax, cl

    mov     [data_start], eax

    ; mov eax, 2 but with a single byte saved
    xor     eax, eax
    inc     ax
    inc     ax

    mov     di, stage15_path

    %include "boot/find.asm"

    ; stage2 entry was found
    call    read_cluster
    jmp     read_buffer_segment:0

not_found_die:
    mov     bl, STAGE15_NOT_FOUND_CODE
    jmp     die
no_ext_die:
    mov     bl, NO_EXT_CODE

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

stage15_path: db 'BOOT       STAGE1  5  $'

times 440-($-$$) db 0x42
db 0xff
times 510-($-$$) db 0x43

; boot signature
db 0x55
db 0xAA

%include "boot/bss.asm"