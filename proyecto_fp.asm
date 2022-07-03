name: "Proyecto"
.model small     

.data 
; Constants      
null    equ 0000h        ; Null address
maxl    equ 41           ; Max length for a input
bytel   equ 2            ; sizeof(char) value   
wordl   equ 4            ; sizeof(char) * 2 value  

; Vars
dbgf    equ 1            ; Debug flag
wrd1    db  maxl dup(0)  ; Word 1 variable
w1len   db  00h          ; Word 1 length
wrd2    db  maxl dup(0)  ; Word 2 variable
w2len   db  00h          ; Word 2 length   
ptrs    dw  4 dup(1)     ; Array of word pointer 
wflag   db  00h          ; Flag for word num
twrd    dw  null         ; Target Word pointer 
tmsg    dw  null         ; Target Message pointer       
oalpha  db  1            ; [flag] Only validate alphanumeric
; -- String to show
msg1    db  'Ingrese palabra 1: $'
msg2    db  'Ingrese palabra 2: $'     
mnval   db  'No son anagramas :(', 0dh, 0ah, '$'
mval    db  'Son anagramas :)', 0dh, 0ah, '$'
mcont   db  'Desea continuar? [s/N] $'   
mend    db  'Bye!!$'      
eol     db  0dh,0ah,'$'             ; End of line chars

; Starting point of the program
.code                       
; This program run only once
; The trick is to switch the reference
; and do the same for the both words
; and in the last make the logic for 
; check if the inserted words are anagrams
;
; @Copyright Neoterux
.start                           

lea dx, ptrs            ; Load pointer array
lea ax, wrd1            ; Load word 1 address
lea bx, wrd2            ; Load word 2 address
mov word ptr ptrs, ax    ; Write word1 address
mov word ptr ptrs+2,bx   ; Write word2 address 
lea ax, msg1            ; Load message 1 address
lea bx, msg2            ; Loadd message 2 address
mov word ptr ptrs+4, ax  ; Write message1 address
mov word ptr ptrs+6, bx  ; Write message2 address 
; ptrs array has the next memory mapping:
; [ *word1, *word2, *msg1, *msg2 ]
; with the value of wflag the current msg/word
; are accessed by:
; target_word: ptrs[wflag]
; target_message: ptrs[wflag+2]
; 
; wflag only will have 1|0 values 
mov ax, 0000h       ; Clean ax register
mov bx, 0000h       ; Clean bx register
mov cx, 0000h       ; Clean cx register
mov dx, 0000h       ; Clean dx register
           
  

_progstart:         ; Start of the while true loop
mov ah, bytel               ; Set Offset value          
lea bx, ptrs                ; Load array address
add bl, wordl               ; Add offset for messages            
mov al, wflag               ; Move the discriminator           
mul ah                      ; Multiply by the disc offset
add bx, ax
; All above is int b = ptrs[4 + (2 * wflag)]
mov dx, [bx]                ; tmsg = &bx 
mov tmsg, dx                ; Move to register

mov ax, 0900h               ; Setup for print Strings  
;lea dx, msg1               ; Load string
int 21h                     ; SysCall                 
; Load the pointer of the target message variable
lea bx, ptrs                ; Load array address
mov al, wflag               ; Load discriminator
mov ah, bytel               ;
mul ah                      ; Calculate correct offset
add bx, ax                  ; Fix to the correct word
mov dx, [bx]                ; Load the word of the target word
mov twrd, dx                ; Save the pointer
  
jmp input

; Input subroutine           
; it's like a getch() function or
; std::cin on c++
input:      
   ; mov bx, twrd            ; Load the pointer of the target word
    mov cx, 0000h           ; Reset counter  
_istart:                          
    mov bx, twrd            ; Reset bx to the target word pointer
    mov ax, 0100h           ; Setup and reset for input
    int 21h                 ; Read character into al  
    cmp al, 0dh             ; Check if character is return
    jz  _endinput           ; Stop input 
    cmp al, 'Z'             ; Check if Mayus
    jle _lower              ; Go to minus   
    jmp _storechar          ; Else continue

_lower:
    cmp al, 'A'             ; Check if is in range
    jl  _storechar          ; Continue
    add al, 20h             ; Convert to minus   
    jmp _storechar
; Apply backspace for the word 
; (Not affect video memory only String)
_bckspace:        
    cmp cl, 00h             ; If cl is 0 do nothing
    jz  _istart
    mov al, null            ; Set as null 
    mov byte ptr [bx-1], al ; Set current char as null
    sub cl, 01h             ; Decrement cl
    jmp _istart             ; Next
    
_storechar:         ; Store character into String    
    cmp oalpha, 1           ; If only alpha delete non-alpha chars
    jz  _rst
    jnz _addchar
_rst:       
    cmp al, 'a'
    jl _fx
    cmp al, 'z'
    jg _fx   
    jmp _addchar
_fx:
    mov al, 00h  
    
_addchar:
    add bx, cx              ; add offset    
    cmp al, 08h             ; Check if backspace
    jz  _bckspace           ; Apply backspace
    mov byte ptr[bx], al    ; save character
    inc cl                  ; Add 1 to char counter    
    cmp cl, maxl-1          ; Check if reached maximum
    jz  _endinput           ; Go to end
    jnz _istart             ; Else read next Character 
  
_endinput: 
    mov bx, dx              ; Move address
    add bl, cl              ; Offset
    mov byte ptr[bx], '$'   ; End Character
    mov ax, 0900h
    lea dx, eol
    int 21h
    jmp check               ; Go to check                  

check:          
inc wflag
cmp wflag, 02h              ; Check if word 2 is already entered
je  validation              ; Go to validation 
jmp _progstart              ; Go to the next word

validation:  
mov wflag, 00h              ; Reset flag
mov cx, 0000h               ; Reset counter for loop
mov ax, 0000h               ; Reset accumulator for validation
lea bx, wrd1                ; Load word 1 into BX
lea bp, wrd2                ; Load word 2 into BP                    

_vloop:        ; Validation loop       
    mov si, cx              ; Load index into SI 
    cmp oalpha, 1           ; if Only alpha is checked  
    add al, [bx+si]         ; Add i-th character
    sub al, [bp+si]         ; Substract i-th character                               
    inc cx                  ; Increase counter   
    cmp cl, maxl
    jge _result           ; Continue to the end message
    jl  _vloop              ; Continue if lower than max
_result:
    cmp ax, 0000h           ; Check if has the same chars
    jz _vmsg                ; Go to valid message
    jnz _errmsg             ; Go to invalid message

_vmsg:
    lea dx, mval            ; Load string address
    jmp _continue
_errmsg:
    lea dx, mnval           ; Load string address
    jmp _continue
    
_continue:
mov ax, 0900h               ; Setup for printing
int 21h                     ; Show to console
lea dx, mcont               ; Show if continue   
mov ax, 0900h               ;
int 21h                     ; SysCall
mov ah, 01h                 ; Prepare for input
int 21h                     ; Input
or  al, 20h                 ; for lowercase  
mov bl, al                                           
lea dx, eol                 ; Load EOL
mov ax, 0900h               ; Prepare for print
int 21h                     ; print
cmp bl, 's'                 ; check if continue
jnz end  


clean:
    mov cx, 0000h           ; Clean counter register
_loop:        
    lea bx, wrd1                    ; Load word 1 address
    add bx, cx                      ; Set to the respective index
    mov byte ptr [bx], null         ; Set to null
    mov byte ptr [bx+maxl+1], null  ; Set to null in Word 2   
    inc cx
    cmp cx, maxl
    jne _loop 
    
    jmp _progstart                  ; Return to the program
    
    
end:  
    lea dx, mend        ; load end message
    mov ax, 0900h       ; Prepare for show
    int 21h
