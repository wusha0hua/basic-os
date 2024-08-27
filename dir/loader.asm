jmp loader

seg_loader equ 0x7c0
seg_kernel equ 0x800

sector equ 2

hello db "hello os",0
str_error db "error",0

loader:
	mov ax,seg_loader
	mov ds,ax
	call loader_clear
	mov si,hello
	call loader_PrintStr
	call loader_PrintLF
	call readdisk
	jmp seg_kernel:0

readdisk:
	mov ax,seg_kernel
	sub ax,0x20
	mov es,ax
	mov cl,1
read:
	inc cl
	mov dx,es
	add dx,0x20
	mov es,dx
	mov dh,0
	mov dl,0
	mov ah,2
	mov al,1
	mov ch,0
	xor bx,bx
	int 0x13
	jc error
	cmp cl,sector
	je loader_return
	jmp read

error:
	mov si,str_error
	call loader_PrintStr
	call loader_PrintLF
	jmp loader
	

loader_PrintStr:
	mov ah,0xe
	mov al,[si]
	cmp al,0
	je loader_return
	int 0x10
	inc si
	jmp loader_PrintStr

loader_PrintLF:
	mov ah,0xe
	mov al,0xd
	int 0x10
	mov al,0xa
	int 0x10
	jmp loader_return

loader_clear:
	mov ax,3
	int 0x10
	jmp loader_return

loader_return:
	ret

times 510-($-$$) db 0
db 0x55,0xaa



