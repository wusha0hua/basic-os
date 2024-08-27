jmp kernel


str_kernel db "kernel",0
str_load_directory_error db "load directoy sector error",0

cmd_mkdir db "mkdir",0
cmd_ls db "ls",0

seg_directory equ 0x820
seg_file equ 0x840

kernel:
	mov ax,cs
	;sub ax,0x20
	mov ds,ax
	mov si,str_kernel
	call PrintStr
	call PrintLF
	call LoadDirectorySectoer
	call Echo
	jmp $

LoadDirectorySectoer:
	mov ax,seg_directory
	mov es,ax
	mov cl,3
	mov dh,0
	mov dl,0
	mov ah,2
	mov al,1
	mov ch,0
	xor bx,bx
	jc LoadDirectorySectoerError
	jmp Return

LoadDirectorySectoerError:
	mov si,str_load_directory_error
	call PrintStr
	call PrintLF
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

Echo:
	xor bx,bx
	;call PrintLF
	mov di,buffer
Read:
	mov ah,0
	int 0x16
	cmp al,0xd
	;je Print
	je Judge
	mov ah,0xe
	int 0x10
	mov [di],al
	inc di
	mov byte[di],0
	jmp Read

Judge:
	call PrintLF
	call GetInput

	mov si,cmd
	
	mov di,cmd_mkdir
isMkdir:
	cmp byte[di],0
	je Mkdir
	mov al,byte[si]
	cmp al,[di]
	jne JudgeEnd
	inc di
	inc si
	jmp isMkdir

	mov di,cmd_ls
isLs:
	

JudgeEnd:
	jmp Echo

Mkdir:
	call PrintLF
	
	mov si,param
	mov ax,seg_directory
	mov es,ax

	xor di,di
	xor cx,cx
	inc cl

	mov ax,seg_directory
	mov dx,ds
	mov es,ax
GetDirectoryAddress:
	mov ch,0
	cmp ch,byte [di]
	je GetDirectoryAddressEnd
	add di,0x10
	inc cl
	jmp GetDirectoryAddress
GetDirectoryAddressEnd:
	mov byte[di],cl
	inc di

	cmp byte[si],0
	je Echo
	mov al,byte[di]
	mov byte[di],al
	inc si
	inc dx
	mov byte[di],0

	jmp Echo


Print:
	;call PrintLF
	mov si,buffer
	call PrintStr
	jmp Echo

GetInput:
	xor bx,bx
	mov si,buffer
	mov di,cmd

GetNextCMDChar:
	mov dl,[si]
	cmp dl,0
	je NoParam
	cmp dl,0x20
	je InputEnd
	mov [di],dl
	inc di
	inc si
	mov byte[di],0
	jmp GetNextCMDChar


NoParam:
	mov si,param
	mov byte[si],0
	jmp Return

InputEnd:
	inc si
	mov di,param
GetNextParamChar:
	mov dl,[si]
	cmp dl,0
	je Return
	mov [di],dl
	inc di
	inc si
	mov byte[di],0
	jmp GetNextParamChar


PrintCMD:
	mov si,cmd
	call PrintStr
	call PrintLF
	mov si,param
	call PrintStr
	call PrintLF
	jmp Echo

Return:
	ret

buffer db 128 dup(0)
cmd db 32 dup(0)
param db 64 dup(0)

times 512*3-($-$$) db 0

directoy:

times 512*4-($-$$) db 0

file:

times 512*5-($-$$) db 0

