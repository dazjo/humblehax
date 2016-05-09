.macro set_lr,_lr
    .word COE_ROP_POP_R1PC ; pop {r1, pc}
        .word COE_ROP_NOP ; pop {pc}
    .word COE_ROP_POP_R4LR_BX_R1 ; pop {r4, lr} ; bx r1
        .word 0xDEADBABE ; r4 (garbage)
        .word _lr ; lr
.endmacro

.macro panic
    set_lr COE_ROP_NOP
    .word COE_ROP_POP_R0PC ; pop {r0, pc}
        .word 0x0
    .word COE_SVC_BREAK
    .word 0xDEAD0000
.endmacro

.macro svcSleepThread,nanosec_low,nanosec_high
    set_lr COE_ROP_NOP
    .word COE_ROP_POP_R0PC ; pop {r0, pc}
        .word nanosec_low ; r0
    .word COE_ROP_POP_R1PC ; pop {r1, pc}
        .word nanosec_high ; r1
    .word COE_SVC_SLEEPTHREAD
.endmacro

.macro svcCreateThread,handle_out,entry,arg,stacktop,priority,processor
    set_lr COE_ROP_POP_R4R5PC
    .word COE_ROP_POP_R0PC ; pop {r0, pc}
        .word handle_out ; r0
    .word COE_ROP_POP_R1PC ; pop {r1, pc}
        .word entry ; r1
    .word COE_ROP_POP_R2R3R4R5R6PC ; pop {r2, r3, r4, r5, r6, pc}
        .word arg ; r2
        .word stacktop ; r3
        .word 0xDEADBABE ; r4 (garbage)
        .word 0xDEADBABE ; r5 (garbage)
        .word 0xDEADBABE ; r6 (garbage)
    .word COE_SVC_CREATETHREAD
    .word priority
    .word processor
.endmacro

.macro memcpy,dst,src,size
    set_lr COE_ROP_NOP
    .word COE_ROP_POP_R0PC ; pop {r0, pc}
        .word dst ; r0
    .word COE_ROP_POP_R1PC ; pop {r1, pc}
        .word src ; r1
    .word COE_ROP_POP_R2R3R4R5R6PC ; pop {r2, r3, r4, r5, r6, pc}
        .word size ; r2 (addr)
        .word 0xDEADBABE ; r3 (garbage)
        .word 0xDEADBABE ; r4 (garbage)
        .word 0xDEADBABE ; r5 (garbage)
        .word 0xDEADBABE ; r6 (garbage)
    .word COE_MEMCPY
.endmacro

.macro flush_dcache,addr,size
    set_lr COE_ROP_NOP
    .word COE_ROP_POP_R0PC ; pop {r0, pc}
        .word COE_GSPGPU_HANDLE ; r0 (handle ptr)
    .word COE_ROP_POP_R1PC ; pop {r1, pc}
        .word 0xFFFF8001 ; r1 (process handle)
    .word COE_ROP_POP_R2R3R4R5R6PC ; pop {r2, r3, r4, r5, r6, pc}
        .word addr ; r2 (addr)
        .word size ; r3 (src)
        .word 0xDEADBABE ; r4 (garbage)
        .word 0xDEADBABE ; r5 (garbage)
        .word 0xDEADBABE ; r6 (garbage)
    .word COE_GSPGPU_FLUSHDATACACHE
.endmacro

.macro gspwn,dst,src,size
    set_lr COE_ROP_POP_R4R5R6R7R8R9R10R11PC
    .word COE_ROP_POP_R0PC ; pop {r0, pc}
        .word COE_GSPGPU_INTERRUPT_RECEIVER_STRUCT + 0x58 ; r0 (nn__gxlow__CTR__detail__GetInterruptReceiver)
    .word COE_ROP_POP_R1PC ; pop {r1, pc}
        .word @@gxCommandPayload ; r1 (cmd addr)
    .word COE_GSPGPU_GXTRYENQUEUE
        @@gxCommandPayload:
        .word 0x00000004 ; command header (SetTextureCopy)
        .word src ; source address
        .word dst ; destination address (standin, will be filled in)
        .word size ; size
        .word 0xFFFFFFFF ; dim in
        .word 0xFFFFFFFF ; dim out
        .word 0x00000008 ; flags
        .word 0x00000000 ; unused
.endmacro

.macro DSPDSP_UnloadComponent
    set_lr COE_ROP_NOP
    .word COE_ROP_POP_R0PC ; pop {r0, pc}
        .word COE_DSPDSP_HANDLE ; r0 (handle ptr)
    .word COE_DSPDSP_UNLOADCOMPONENT
.endmacro

.macro DSPDSP_RegisterInterruptEvents,handle,interrupt,channel
    set_lr COE_ROP_NOP
    .word COE_ROP_POP_R0PC ; pop {r0, pc}
        .word COE_DSPDSP_HANDLE ; r0 (handle ptr)
    .word COE_ROP_POP_R1PC ; pop {r1, pc}
        .word handle ; r1 (handle ptr)
    .word COE_ROP_POP_R2R3R4R5R6PC ; pop {r2, r3, r4, r5, r6, pc}
        .word interrupt ; r2
        .word channel ; r3
        .word 0xFFFFFFFF ; r4 (garbage)
        .word 0xFFFFFFFF ; r5 (garbage)
        .word 0xFFFFFFFF ; r6 (garbage)
    .word COE_DSPDSP_REGISTERINTERRUPTEVENTS
.endmacro

ARCHIVE_SAVEDATA equ 0x4
PATH_EMPTY equ 0x1
PATH_ASCII equ 0x3
FS_OPEN_READ equ 0x1

.macro FSUSER_OpenFileDirectly,fileHandle,transaction,archiveId,archivePathType,archivePath,archivePathLength,filePathType,filePath,filePathLength,openflags,attributes
    set_lr attributes
    .word COE_ROP_POP_R0PC
        .word COE_FSUSER_HANDLE

    .word COE_ROP_POP_R1PC
        .word archivePathLength

    .word COE_ROP_POP_R2R3R4R5R6PC
        .word transaction
        .word archiveId
        .word 0xF00FF00F
        .word 0xF00FF00F
        .word 0xF00FF00F

    .word COE_ROP_POP_R4R5R6R7R8R9R10R11R12PC
        .word 0xF00FF00F        ;r4
        .word archivePath       ;r5
        .word filePath          ;r6
        .word 0xF00FF00F        ;r7
        .word 0xF00FF00F        ;r8
        .word archivePathType   ;r9
        .word filePathType      ;r10
        .word openflags         ;r11
        .word filePathLength    ;r12

    .word COE_FSUSER_OPENFILEDIRECTLY+0x24
        .word 0xF00FF00F
        .word fileHandle
        .word 0xF00FF00F
        .word 0xF00FF00F
        .word 0xF00FF00F
        .word 0xF00FF00F
        .word 0xF00FF00F
        .word 0xF00FF00F
        .word 0xF00FF00F
        .word 0xF00FF00F
        .word 0xF00FF00F
        .word 0xF00FF00F
        .word 0xF00FF00F
.endmacro

.macro FSFILE_GetSize,filehandle,size_out
    set_lr COE_ROP_NOP
    .word COE_ROP_POP_R0PC
        .word filehandle
    .word COE_ROP_POP_R1PC
        .word size_out
    .word COE_FSFILE_GETSIZE
.endmacro

.macro FSFILE_Read,filehandle,bytesread,offset_l,offset_h,buffer,size_ptr
    memcpy @@readfile_size,size_ptr,4

    .word COE_ROP_POP_R0PC
        .word filehandle
    .word COE_ROP_POP_R1PC
        .word buffer
    .word COE_ROP_POP_R2R3R4R5R6PC
        .word offset_l
        .word offset_h
        .word 0xF00FF00F
        .word 0xF00FF00F
        .word 0xF00FF00F
    .word COE_ROP_POP_R4R5R6R7R8R9R10R11R12PC
        .word 0xF00FF00F        ;r4
        .word bytesread         ;r5
        .word 0xF00FF00F        ;r6
        .word 0xF00FF00F        ;r7
        .word 0xF00FF00F        ;r8
        .word 0xF00FF00F        ;r9
        .word 0xF00FF00F        ;r10
        .word 0xF00FF00F        ;r11
@@readfile_size:
        .word 0xF00FF00F        ;r12, to be overwritten
    .word COE_FSFILE_READ+0x10
        .word 0xF00FF00F
        .word 0xF00FF00F
        .word 0xF00FF00F
.endmacro

.macro FSFILE_Close,filehandle
    set_lr COE_ROP_NOP
    .word COE_ROP_POP_R0PC
        .word filehandle
    .word COE_FSFILE_CLOSE
.endmacro
