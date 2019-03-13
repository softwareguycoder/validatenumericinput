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
    
    EOF         EQU 0               ; End-of-file result from sys_read

; Message to welcome the user to the program
    WELCOMEMSG db "validatenumericinput v1.0 by Brian Hart",10,0
               db 10,0
               db "Type an integer at the prompt.  We'll tell you if it's valid input or not.",10,0
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
    
    VALOK: db "Validation successful.",10,0
    VALOKLEN EQU $-VALOK
    
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
    
;------------------------------------------------------------------------------
; ValidateNumericInput: Validates that user input is indeed a number.
; UPDATED:              03/13/2019
; IN:                   ESI = Count of characters of user input
;                       EDI = Address of user input buffer
; RETURNS:              Nothing
; MODIFIED:             Nothing
; CALLS:                Nothing
; DESCRIPTION:          Validates the contents of the user input buffer to ensure
;                       that the contents of said buffer are parsable as a positive
;                       or negative integer.  If not, then jumps to this program's
;                       ERROR label; if so, then the function simply returns control
;                       to the caller.
ValidateNumericInput:
    pushad                          ; Save all 32-bit GP registers
    xor eax, eax                    ; Clear EAX to be zero
    xor ebx, ebx                    ; Clear EBX to be zero
    xor ecx, ecx                    ; Clear ECX to be zero
    xor edx, edx                    ; Clear EDX to be zero
    .Scan:
        cmp byte [edi+ecx], 0       ; Test input char for null-terminator
        je .Next                    ; Skip to next char if so
        cmp byte [edi+ecx], 0Ah     ; Test input char for null-terminator
        je .Next                    ; Skip to next char if so
        cmp byte [edi+ecx], 20h     ; Test input char for a nonprinting char
        jna Error                   ; All nonprinting chars are invalid
        cmp byte [edi+ecx], 2Dh     ; Test input char for hyphen (might be a minus sign)
        je .mightBeMinus            ; If currentChar == '-' then test whether it's the first char
        cmp byte [edi+ecx], 2Ch     ; Test input char for a thousands separator (comma)
        je .Next                    ; Ignore commas
        cmp byte [edi+ecx], 2Eh     ; Test input char for a decimal point
        je Error                    ; Invalid value; floating-point numbers not supported
        cmp byte [edi+ecx], 30h     ; Test input char against '0'
        jb Error                    ; If below '0' in ASCII chart, not a digit
        cmp byte [edi+ecx], 39h     ; Test input char against '9'
        ja Error                    ; If above '9' in ASCII chart, not a digit
        jmp .Next                   ; Skip to Next iteration now, because we are good to go
        .mightBeMinus:
            cmp ecx, 0              ; Check whether ECX==0, i.e., we are on the first iteration
            jne Error               ; If ECX != 0 and we are here, a hyphen occurred in the middle of the input
        .Next:
            inc ecx                 ; Like i++; increment our loop counter
            cmp ecx, esi            ; Is ecx==esi?
            jne .Scan               ; If ecx!=esi, then loop to next iteration  
    .Done:        
        popad                       ; Restore all 32-bit GP registers
    ret 
    
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
    
; Once GetText has been called, EAX now contains the number of chars inputted
; Check for EOF (zero chars inputted), and, in this case, jump to the Done label
    cmp eax, EOF                    ; Check whether EAX == EOF
    je Done                         ; If EAX == EOF, then jump to Done label
    
; If we are here, copy the value in EAX to ESI and the address of the INPUT
; into EDI, since then we can call ValidateNumericInput.  If we are still
; in this thread when ValidateNumericInput returns control to us, then we should
; announce to the user that validation passed    

    mov esi, eax                    ; Copy EAX value to ESI
    mov edi, INPUT                  ; Copy address of INPUT buffer to EDI
    call ValidateNumericInput       ; Validate the numeric input.
    
    mov ecx, VALOK                  ; Address of the VALOK message announcing that validation passed
    mov edx, VALOKLEN               ; Length of the validation succeeded message
    call DisplayText                ; Display the message to the user.
    
Done:    
;    mov ecx, DONEMSG                ; Address of the "program finished successfully" message
;    mov edx, DONEMSGLEN             ; Length of the message to display to the user
;    call DisplayText                ; Display the message to the user.
    
    mov ebx, EXIT_OK                ; Specify EXIT_OK code for successful completion
    call ExitProgram                ; Exit the software gracefully
    
; Handle the case where this program has to die because an error occurred    
Error:    
    mov ecx, INVALIDVAL             ; Invalid value typed messgae address
    mov edx, INVALIDVALLEN          ; Length of the invalid value typed message
    call DisplayText                ; Display the message to the user
    
    mov ebx, EXIT_ERR               ; Specify EXIT_ERR code for error
    call ExitProgram                ; Exit the software gracefully

    nop                             ; Keeps gdb happy
