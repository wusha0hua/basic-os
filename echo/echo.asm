jmp sector1_start

seg_mbr equ 0x7c0
seg_kernel equ 0x800

sector_max equ 3
sector_now db 2

str_hello db "hello os",0

sector1_start:
	mov ax,seg_mbr
	mov ds,ax
	call clear
	mov si,str_hello
	call PrintStr
	call PrintLF
	call readdisk
	jmp seg_kernel:0 
clear:
	mov ax,3
	int 0x10
	jmp return

PrintStr:
	mov ah,0xe
	mov al,[si]
	cmp al,0
	je zero
	inc si
	int 0x10
	jmp PrintStr
zero:
	jmp return 

PrintLF:
	mov ah,0xe
	mov al,0xd
	int 0x10
	mov al,0xa
	int 0x10

readdisk:
	mov ax,seg_kernel
	mov es,ax
reply:	
	mov ah,0x2
	mov al,1
	mov ch,0
	mov cl,2
	mov dh,0
	mov dl,0
	mov bx,0
	int 0x13
	jmp return	

return:
	ret


times 510-($-$$) db 0
db 0x55
db 0xaa



jmp sector2_start

str_hello_new db "kernel start",0
buffer equ 0x8200

sector2_start:
	mov ax,es
	sub ax,0x20
	mov ds,ax
	mov si,str_hello_new
	call PrintStrnew
	call PrintLFnew

	call echo

	jmp end

PrintStrnew:
	mov ah,0xe
	mov al,[si]
	cmp al,0
	je returnnew
	int 0x10
	inc si
	jmp PrintStrnew

PrintLFnew:
	mov ah,0xe
	mov al,0xd
	int 0x10
	mov al,0xa
	int 0x10
	jmp returnnew

echo:
	xor bx,bx
	call PrintLFnew
	mov di,buffer
Read:
	mov ah,0
	int 0x16
	cmp al,0xd
	je Print
	mov ah,0xe
	int 0x10
	mov [di],al
	inc di
	mov byte[di],0
	jmp Read

Print:
	call PrintLFnew
	mov si,buffer
	mov ah,0xe
printnext:
	mov al,byte[si]
	cmp al,0
	je echo 
	int 0x10
	inc si
	jmp printnext
	

returnnew:
	ret

end:
	jmp $
times 512*2-($-$$) db 0

