; ASMLE - Wordle in 512 bytes
; (c) Kat Purpy, 2022

; Cheers to Bisqwit and everyone else for help!

bits 16
%ifdef BOOT_SECTOR
org 0x7c00
%elif
org 100h
%endif
_start:
        call rng
        call load_word
        .loop:
        call input_answer
        call check_letters
        cmp dl,0
        jnz .loop
        
        ;reward player with a nice [CENSORED]
        mov al, char_beep
        call print_char
        
        jmp _start

; Putting copyright in the unitialized var space because why not
INPUT db 'KATPU'
GAME_WORD db 'RPY,2'
RNG_INDEX db '0'
WORD_ITER_CALLBACK db '22'

char_backspace equ 0x8
char_carete equ 0xD
char_beep equ 0x7
char_linefeed equ 0xA

input_answer:
        mov dx, 5
        .loop:
            mov ah, 00h
            int 16h ; read char

            xor al, 32
            cmp al, char_backspace | 32
            je .case_backspace
            
            call print_char
            
            mov bx, 5
            sub bx, dx

            mov [INPUT+bx], al
            
            dec dx
            cmp dx, 0
            jnz .loop
        
        ret
        
        .case_backspace:
            cmp dx, 5
            je .loop
            inc dx
            mov al, char_backspace
            call print_char
            
            mov bx, 0x0007
            mov al, ' '
            mov ah, 09h
            mov cx, 1
            int 10h
            
            jmp .loop


            
; AL - char to write
print_char:
            mov ah, 0Eh
            int 10h
            ret
        
; output: if DL equals 0 - word is guessed
; does: 
;   - check input
;   - print which letters are correct/wrong/in the word
;   - go to the new line
check_letters:
        mov ax, .loop
        call iterate_word
        
        mov al, char_linefeed ; go to the new line
        call print_char
        ret
    
    .loop:
        mov al, [INPUT+bx] ; input char
        mov dh, [GAME_WORD+bx+1] ; word char
        cmp al,dh
        jnz .letter_wrong
        
        .letter_correct:
            mov bx, 0x000A ; green color
            jmp .brk
        
        .letter_wrong:
            inc dl ;add mistake
            mov bx, 5
            .check:
                dec bx
                mov dh, [GAME_WORD+bx+1]
                cmp al, dh
                je .letter_is_in_word
                cmp bx, 0
                jnz .check
            ;letter is not in word 
            mov bl, 0x0C ; red color
            jmp .brk_wrong
        
        .letter_is_in_word:
        mov bl, 0x0E ; yellow color
        .brk_wrong:
        
        .brk:
        push ax
        mov al, char_backspace ; move the cursor one character back
        call print_char
        pop ax
        
        push cx
        mov ah, 09h
        mov cx, 1
        int 10h ; set char color
        pop cx
        ret

; Pardon the name, it just increases RNG_INDEX by one and loops around
rng:
    mov al, [RNG_INDEX]
    add al, 1
    mov si, ax
    and si, 63
    mov [RNG_INDEX], al
    ret
    
; SI - word to decode
load_word:
        mov ax, 3
        mul si
        mov si, ax
        add si, 20h
        add si, dictionary
    
    ; Unpack 4 bit values (charset and chars' indices) into GAME_WORD
    .unpack: 
        mov di, GAME_WORD
        cld
        mov cx, 3
        .pair:
            lodsb
            aam 16 ;magic instruction that extracts 2 nibbles
            stosw
        loop .pair
        
        mov ax, .decode
        call iterate_word
        ret
    
    ; Get the chars
    .decode: 
        ;dl - char index
        mov dl, [GAME_WORD+bx+1] ;get char index
        mov bl, [GAME_WORD] ;get dictinary id
        shl bl, 4 ;multiply by 16
        add bx, dictionary ;add gamedata address
        add bl, dl ;add char index
        mov dl, [bx] ;store decoded result
        mov bx, cx ;store word char number into bx
        mov [GAME_WORD+bx+1], dl ;store 
        ret
        
;AX - pointer to callback function
iterate_word:
    mov [WORD_ITER_CALLBACK], ax
    mov cx, 5
    .iteration:
    push cx
    dec cx
    mov bx, cx
    call [WORD_ITER_CALLBACK]
    pop cx
    loop .iteration
    ret    

dictionary equ $
incbin "dictionary.bin"
times 510-($-$$) db 0   ; Pad remainder of boot sector with 0s
dw 0xAA55               ; The standard PC boot signature