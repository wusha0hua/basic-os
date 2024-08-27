jmp loader

str_hello db "hello os",0

loader:
	mov ax,0x7c0
	mov ds,ax
	mov si,str_hello
	call PrintStr
	call PrintLF
	call ReadDisk
	jmp 0x800:0

ReadDisk:
	mov ax,0x800
	mov es,ax
	xor bx,bx
	mov ah,2
	mov al,1
	mov dh,0
	mov cl,2
	mov ch,0
	mov dl,0
	int 0x13
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

Return:
	ret

times 510-($-$$) db 0
db 0x55,0xaa
