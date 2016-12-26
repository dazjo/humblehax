.include "constants/constants.s"

COE_ROP_BASE equ               (0x08300000)
PAYLOAD_VA equ                 (0x00280000)
COE_CODEBIN_BUFFER equ         (COE_LINEAR_BASE)
COE_LINEAR_BUFFER equ          (COE_CODEBIN_BUFFER + COE_CODEBIN_SIZE)
COE_SCANLOOP_STRIDE equ        (0x1000)
