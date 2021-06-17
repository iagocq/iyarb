; eax = sector number
; bx = number of sectors
read_sectors:
    pushad

    mov     si, read_DAP
    mov     [si+read_DAP.readn-read_DAP], bx
    mov     [si+read_DAP.st_sector-read_DAP], eax

    mov     dl, [si+drive_number-read_DAP]
    mov     ah, 0x42
    int     0x13

    popad
    ret
