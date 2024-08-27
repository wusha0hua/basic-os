new_sector:

jmp new_start

str_hello_new db `---hello os i am in a new sector---`,0
str_end_new db `---end in new sector---`,0

new_start:
	mov ax,cs
	mov ds,ax
	mov si,str_hello_new
	call new_PrintStr
	call new_end
	jmp $

new_PrintStr:
	mov al,[si]
	cmp al,0
	je new_ret
	mov ah,0eh
	int 10h
	inc si
	jmp new_PrintStr
	call new_newline
	jmp new_ret

new_newline:
	mov ah,0eh
	mov al,0dh
	int 10h
	mov al,0ah
	int 10h
	jmp new_ret

new_ret:
	ret

new_end:
	mov si,str_end_new
	call new_PrintStr

