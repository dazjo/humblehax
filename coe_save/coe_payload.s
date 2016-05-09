payload:
    ; Create thread with a better stack
    memcpy COE_ROP_BASE, (COE_COPYTO_ADDR+0x2000), 0x1000
    svcCreateThread thread_handle, COE_ROP_NOP, 0x0, COE_ROP_BASE, 0x18, -2

    ; Exit this thread
    .word COE_SVC_EXITTHREAD

thread_handle:
    .word 0x0
