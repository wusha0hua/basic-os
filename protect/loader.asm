jmp loader

str_hello db "hello os",0

GDTSize dw 32-1
GDTBase dd 0x8400

loader:
	mov ax,0x7c0	
	mov ds,ax
	call Clear
	mov si,str_hello
	call PrintStr
	call LoadKernel
	call ProtectMod

	jmp $

Clear:
	mov ax,3
	int 0x10
	ret

PrintStr:
	mov ah,0xe
	mov al,[si]
	cmp al,0
	je PrintStrEnd
	int 0x10
	inc si
	jmp PrintStr
PrintStrEnd:
	ret

LoadKernel:
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
	ret

ProtectMod:
	lgdt [GDTSize]

	mov ax,0x840
	mov es,ax

	mov dword[es:0],0
	mov dword[es:4],0
	
	mov dword[es:0x8],0x8000ffff
	mov dword[es:0xc],0x00409800

	mov dword[es:0x10],0x0000ffff
	mov dword[es:0x14],0x00c09200

	mov dword[es:0x18],0x00007a00
	mov dword[es:0x1c],0x00409600
	
	in al,0x92
	or al,2
	out 0x92,al
	cli

	mov eax,cr0
	or eax,1
	mov cr0,eax

	jmp 0x0008:0

	ret

times 510-($-$$) db 0
db 0x55,0xaa
