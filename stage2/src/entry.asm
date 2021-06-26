[bits 16]

global _entry

extern _rust_entry
extern _bss_start
extern _bss_end
extern enter_protected_mode

; this forces this section to be placed before everything (see stage2.ld)
section .entry

_entry:
    cli

    mov     esp, 0xfff0
    mov     ebp, esp

    ; the BIOS disk number is saved on edx
    ; it's pushed so the cdecl entry function can access it
    push    edx

    call    enter_protected_mode

[bits 32]

    ; clear bss
    xor     eax, eax        ; eax = 0
    mov     ecx, _bss_end   ;
    mov     edi, _bss_start ; edi = _bss_start
    sub     ecx, edi        ;
    add     ecx, 3          ;
    shr     ecx, 2          ; ecx = (_bss_end - _bss_start + 3) / 4
    rep stosd

    ; enter rust world
    call    _rust_entry
