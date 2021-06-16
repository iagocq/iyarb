section .bss
bss_start:

ext_DAP:
    .size:      resb 2
    .inf_flags: resb 2

    .phy_sil:   resb 4
    .phy_heads: resb 4
    .phy_spt:   resb 4

    .nsectors:  resb 8
    .bpps:      resb 2
    .edd_ptr:   resb 4

drive_number:           resb 1
data_start:             resd 1
fat_start:              resd 1
psectors_per_cluster:   resd 1
bytes_per_psector:      resd 1
stage2_path:            resb 23

read_DAP:
    .size:      resb 1
    .unused:    resb 1
    .readn:     resb 2

    ; segment and offset pointing to the buffer
    .b_offset:  resb 2
    .b_segment: resb 2

    ; start sector (0 based)
    .st_sector: resb 8
bss_end:
