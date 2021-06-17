; eax = cluster number
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

    ; we can just fall through to the function
    ;call    read_sectors
    ;
    ;ret

%include "boot/disk1.asm"
