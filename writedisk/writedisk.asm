jmp loader

flag db 0

seg_loader equ 0x7c0

str_hello db "hello os",0
str_flag db "flag:",0
str_error db "error",0

loader:
	mov ax,seg_loader
	mov ds,ax
	call Clear
	mov si,str_hello
	call PrintStr
	call PrintLF
	mov si,str_flag
	call PrintStr
	mov si,flag
	call PrintChar
	call PrintLF
	call GetChar
	;call PrintLF
	call WriteDisk
	jmp End

Clear:
	mov ax,3
	int 0x10
	jmp Return

PrintStr:
	mov ah,0xe
	mov al,[si]
	cmp al,0
	je Return
	int 0x10
	inc si
	jmp PrintStr

PrintLF:
	mov ah,0xe
	mov al,0xd
	int 0x10
	mov al,0xa
	int 0x10
	jmp Return

PrintChar:
	mov al,[si]
	mov ah,0xe
	int 0x10
	jmp Return

GetChar:
	mov ah,0
	int 0x16
	mov dl,al
	mov ah,0xe
	int 0x10
	mov si,flag
	mov byte[si],dl
	jmp Return

WriteDisk:
	mov bx,seg_loader
	mov es,bx
	xor bx,bx
	mov ah,0x3
	mov al,1
	mov ch,0
	mov cl,1
	mov dh,0
	mov dl,0
	int 0x13
	jc Error
	jmp Return

Error:
	mov si,str_error
	call PrintStr
	call PrintLF
	jmp Return

Return:
	ret

End:
	jmp $

times 510-($-$$) db 0
db 0x55,0xaa
