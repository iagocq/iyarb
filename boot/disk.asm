; eax = cluster number, returns next cluster number
; eax, ebx, edx will be overwritten
next_cluster:
    ; cluster_off = cluster * 4 = cluster << 2
    ; each entry is 4 bytes long
    shl     eax, 2

    ; cluster_next_off = edx => cluster_off % bpps
    ; cluster_next_sec = eax => cluster_off / bpps
    div     DWORD [bytes_per_psector]
    add     eax, DWORD [fat_start]
    mov     bx, 1

    call    read_sectors

    mov     eax, [fs:edx]

    ret

; eax = cluster number
; eax, ebx, edx will be overwritten
read_cluster:
    ; cluster_sector = data_start + (cluster - root_cluster) * psectors_per_cluster
    sub     eax, 2
    mov     ebx, [psectors_per_cluster]
    mul     ebx
    add     eax, [data_start]

    call    read_sectors

    ret

; eax = sector number
; bx = number of sectors
read_sectors:
    pushad

    mov     [read_DAP.readn], bx
    mov     [read_DAP.st_sector], eax

    mov     dl, [drive_number]
    mov     ah, 0x42
    mov     si, read_DAP
    int     0x13

    popad
    ret
