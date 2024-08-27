jmp loader

str_hello db "hello os",0

loader:
	mov ax,0x7c0
	mov ds,ax
	call Clear
	mov si,str_hello
	call PrintStr
	call PrintLF
	call LoadDisk
	jmp 0x800:0

LoadDisk:
	mov ax,0x800
	mov es,ax
	mov ah,2
	mov al,1
	mov ch,0
	mov cl,2
	mov dh,0
	mov dl,0
	xor bx,bx
	int 0x13

	mov ax,0x820
	mov es,ax
	mov ah,2
	mov al,1
	mov ch,0
	mov cl,3
	mov dh,0
	mov dl,0
	xor bx,bx
	int 0x13

	ret


Clear:
	mov ax,3
	int 0x10
	ret

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
	ret

Return:
	ret

times 510-($-$$) db 0
db 0x55,0xaa
