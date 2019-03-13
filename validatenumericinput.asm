;   Executable name         : validatenumericinput
;   Version                 : 1.0
;   Created date            : 03/13/2019
;   Last update             : 03/13/2019
;   Author                  : Brian Hart
;   Description             : A simple program to test a procedure that validates the user's input.  The procedure
;                             checks the text the user has typed to ensure that it's parsable into a positive or
;                             negative whole number or zero; if not, then the procedure kills the program gracefully
;                             after telling the user their input is invalid.
;                             
;
;   Run it this way:
;       ./validatenumericinput
;
;   Build using these commands:
;       nasm -f elf -F dwarf -g validatenumericinput.asm -l validatenumericinput.lst
;       ld -m elf_i386 -o validatenumericinput validatenumericinput.o
;
SECTION     .bss                    ; Section contaning uninitialized data

    INPUTLEN equ 1024               ; Length of buffer to store user input
    INPUT:   resb INPUTLEN          ; Text buffer itself to store user input
    
SECTION     .data                   ; Section containing initialized data

    SYS_WRITE   EQU 4               ; Code for the sys_write syscall
    SYS_READ    EQU 3               ; Code for the sys_read syscall
    SYS_EXIT    EQU 1               ; Code for the sys_exit syscall
    
    STDIN       EQU 0               ; Standard File Descriptor 0: Standard Input
    STDOUT      EQU 1               ; Standard File Descriptor 1: Standard Output
    STDERR      EQU 2               ; Standard File Descriptor 2: Standard Error
    
    EXIT_OK     EQU 0               ; Process exit code for successful termination
    EXIT_ERR    EQU -1              ; Process exit code for a general error condition

; Message to the user to tell them the value typed is not acceptable.
; Customize this to your liking.
    INVALIDVAL: db "ERROR! Invalid value.",10,0  
    INVALIDVALLEN equ $-INVALIDVAL   
    
    DONEMSG: db "Program executed successfully.",10,0
    DONEMSGLEN EQU $-DONEMSG            
    
SECTION .text                       ; Section containing the program's code

GLOBAL _start

_start:
    nop                             ; Keeps gdb happy
    
    ; TODO: Add new program code here
