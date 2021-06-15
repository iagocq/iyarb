find_loop:
    .cluster_loop:
        call    read_cluster
        xor     si, si

        mov     cx, bp
        mov     dx, 1
        shl     dx, cl
        mov     cx, dx
        .entry_loop:
            cmp     BYTE [fs:si], 0
            je      not_found_die

            pusha
            mov     cx, 11

            cld
            push    ds
            mov     ax, fs
            mov     ds, ax
            .compare:
                lodsb
                scasb
                loopz   .compare
                jnz     .not_equal
            .not_equal:
            pop     ds
            popa
            jz      .path_matches

            add     si, 0x20
            loop    .entry_loop
        call    next_cluster
        cmp     eax, 0x0FFFFFF8
        jb      find_loop
        jmp     not_found_die

    .path_matches:
    add     di, 11
    mov     ax, WORD [fs:si+0x14]
    shl     eax, 16
    mov     ax, WORD [fs:si+0x1a]
    cmp     BYTE [di], '$'
    jnz     find_loop