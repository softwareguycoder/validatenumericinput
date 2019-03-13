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

; Message to welcome the user to the program
    WELCOMEMSG db "validatenumericinput v1.0 by Brian Hart",10,0
               db 10,0
               db "This program tests the ValidateNumericInput procedure.  This procedure",10,0
               db "takes a text string as input and attempts to validate whether it can be",10,0
               db "successfully parsed as being the string representation of an integer.",10,0
               db "As we all know from math class, an integer is defined as a positive or",10,0
               db "negative whole number or zero.  If invalid input is typed, the program will",10,0
               db "die.  Otherwise, nothing else happens and control is returned to the main thread.",10,0
               db 10,0
    WELCOMEMSGLEN EQU $-WELCOMEMSG
    
; Prompt for the user to type an integer
    USERPROMPT1 db "> Please type an integer: > ",0
    USERPROMPT1LEN EQU $-USERPROMPT1                  
               
; Message to the user to tell them the value typed is not acceptable.
; Customize this to your liking.
    INVALIDVAL: db "ERROR! Invalid value.",10,0  
    INVALIDVALLEN equ $-INVALIDVAL   
    
    DONEMSG: db "Program executed successfully.",10,0
    DONEMSGLEN EQU $-DONEMSG            
    
    LF: db 10,0
    LFLEN EQU $-LF
    
SECTION .text                       ; Section containing the program's code

;------------------------------------------------------------------------------
; DisplayText:          Displays a text string on the STDOUT
; UPDATED:              03/12/2019
; IN:                   ECX = Address of the start of the output buffer
;                       EDX = Count of characters to be displayed
; RETURNS:              Nothing
; MODIFIED:             Nothing
; CALLS:                sys_write via INT 80h
; DESCRIPTION:          Writes whatever text is referenced by ECX and EDX to the
;                       STDOUT.  By default, writing to STDOUT causes text to be
;                       displayed on the user's console.
;
DisplayText:
    push eax                        ; Save caller's EAX
    push ebx                        ; Save caller's EBX
    mov eax, SYS_WRITE              ; Specify sys_write syscall
    mov ebX, STDOUT                 ; Specify File Descriptor 1: Standard Output
    int 80h                         ; Make kernel call; assume ECX and EDX already initialized
    pop ebx                         ; Restore caller's EBX
    pop eax                         ; Restore caller's EAX
    ret                             ; Return to caller
    
;------------------------------------------------------------------------------
; ExitProgram           Exits this program properly and returns control to the OS
; UPDATED:              03/13/2019
; IN:                   EBX = Numeric exit code of the program. Usually, zero means
;                       success, but it's arbitrary.
; RETURNS:              Nothing.  The program has terminated by the time this procedure
;                       is finished.  Calling this procedure is the kiss of death.
; MODIFIED:             EAX contains the code for the sys_exit syscall
; CALLS:                sys_exit via INT 80h
; DESCRIPTION:          Exits the program and returns control to the OS
;
ExitProgram:
    mov eax, SYS_EXIT               ; Specify the sys_exit syscall
    int 80h                         ; Make kernel call
    ret
        
;------------------------------------------------------------------------------
; GetText:              Reads in text from user input
; UPDATED:              03/12/2019
; IN:                   ECX = Address of the start of the output buffer
;                       EDX = Count of characters to be displayed
; RETURNS:              Nothing
; MODIFIED:             EAX contains number of bytes read (including carriage return)
; CALLS:                sys_write via INT 80h
; DESCRIPTION:          Reads user input from screen into a buffer
;
GetText:
    push ebx                        ; Save caller's EBX
    mov eax, SYS_READ               ; Specify sys_read syscall
    mov ebX, STDIN                  ; Specify File Descriptor 0: Standard Input
    int 80h                         ; Make kernel call; assume ECX and EDX already initialized
    pop ebx                         ; Restore caller's EBX
    ret                             ; Return to caller
    
GLOBAL _start                       ; Tell the linker where the program's entry point is

_start:                             ; This label is the program's entry point
    nop                             ; Keeps gdb happy
    
    mov ecx, WELCOMEMSG             ; Address of the welcome message
    mov edx, WELCOMEMSGLEN          ; Length of the welcome message
    call DisplayText                ; Display the welcome message to the user
    
    mov ecx, USERPROMPT1            ; Prompt for the user to enter an integer
    mov edx, USERPROMPT1LEN         ; Length of the user prompt message
    call DisplayText                ; Display the prompt to the user
    
    mov ecx, INPUT                  ; Input buffer for the user's input
    mov edx, INPUTLEN               ; Length of the input buffer
    call GetText                    ; Gets the input from the user

    mov ecx, LF                     ; A linefeed character
    mov edx, LFLEN                  ; Length of the message to display
    call DisplayText                ; Display the newline to the user

    ; TODO: Add new program code here
    nop                             ; Keeps gdb happy
    
    mov ecx, LF                     ; A linefeed character
    mov edx, LFLEN                  ; Length of the message to display
    call DisplayText                ; Display the newline to the user
    
    mov ecx, DONEMSG                ; Address of the "program finished successfully" message
    mov edx, DONEMSGLEN             ; Length of the message to display to the user
    call DisplayText                ; Display the message to the user.
    
    mov ebx, EXIT_OK                ; Specify EXIT_OK code for successful completion
    call ExitProgram                ; Exit the software gracefully
