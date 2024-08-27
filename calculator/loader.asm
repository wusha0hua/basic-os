jmp loader

str_hello db "hello os",0

loader:
	mov ax,0x7c0
	mov ds,ax
	mov ss,ax
	call Clear
	push str_hello
	call PrintStr
	call PrintLF
	Loop:
		call Calculator
	jmp Loop
	jmp $

Calculator:
	push bp
	mov bp,sp
	sub sp,0x10

	lea ax,[bp-0x10]
	push ax
	call GetInput
	
	lea ax,[bp-0x10]
	push ax
	call PrintStr
	call PrintLF
	
	add sp,0x10
	mov sp,bp
	pop bp
	ret 

GetInput:
	push bp
	mov bp,sp
	
	xor si,si
	LoopGetInpt:
		mov ah,0
		int 0x16
		cmp al,0xd
		je LoopGetInptEnd
		mov byte[bp+2+4+si],al
		inc si
		mov byte[bp+2+4+si],0
		jmp LoopGetInpt
	LoopGetInptEnd:

	mov sp,bp
	pop bp
	ret 2

Clear:
	mov ax,3
	int 0x10
	ret

PrintStr:
	push bp	
	mov bp,sp

	mov ah,0xe
	mov si,[bp+4]
	LoopPrintStr:
		mov al,[si]
		cmp al,0
		je LoopPrintStrEnd
		int 0x10
		inc si
		jmp LoopPrintStr
	LoopPrintStrEnd:

	mov sp,bp
	pop bp
	ret 2

PrintLF:
	mov ah,0xe
	mov al,0xd
	int 0x10
	mov al,0xa
	int 0x10
	ret

times 510-($-$$) db 0
db 0x55,0xaa
