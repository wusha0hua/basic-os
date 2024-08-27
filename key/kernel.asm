jmp kernel

str_kernel db "hello kernel",0

kernel:
	mov ax,cs
	mov ds,ax
	mov si,str_kernel
	call PrintStr
	;call PrintLF
	call GetInputChar	
	jmp End

GetInputChar:
	call PrintLF
	mov ah,0
	int 0x16
	call GetAscii
	call PrintAscii
	jmp GetInputChar

GetAscii:
	mov bl,al	
	xor ax,ax
	xor dx,dx
	mov al,bl
	mov bl,0x10
	div bl
	mov dh,al
	mov dl,ah

	cmp dl,9
	jle DLNumber
	cmp dl,0xa
	jge DLLetter

DLNumber:
	add dl,0x30
	jmp DHDeal

DLLetter:
	add dl,0x37
	jmp DHDeal

DHDeal:
	cmp dh,9
	jle DHNumber
	cmp dh,0xa
	jge DHLetter

DHNumber:
	add dh,0x30
	jmp Return
DHLetter:
	add dh,0x37
	jmp Return

PrintAscii:
	mov ah,0xe
	mov al,dh
	int 0x10
	mov al,dl
	int 0x10
	

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

End:
	jmp $

