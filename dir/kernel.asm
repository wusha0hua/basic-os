jmp kernel

seg_kernel equ 0x800
seg_stack equ 0x800

str_kernel db "hello kernel",0
str_test db "hello kerner",0
str_error db "error",0
str_false db "false",0
str_true db "true",0

kernel:
	mov ax,seg_kernel
	mov ds,ax
	mov ss,ax
	xor sp,sp
	call Clear

	push str_kernel
	call PrintStr
	call PrintLF
	
	call LoadSectorDirectory

	jmp KernelEnd

Clear:
	mov ax,3
	int 0x10
	ret

PrintStr:
	push bp
	mov bp,sp

	mov si,[bp+4]
	mov ah,0xe

	PrintStrLoop:
		mov al,[si]
		cmp al,0
		je PrintStrEnd 
		int 0x10
		inc si
		jmp PrintStrLoop
	PrintStrEnd:

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

StrLen:
	push bp
	mov bp,sp

	mov si,[bp+4]
	xor cx,cx
	StrLenLoop:
		mov al,[si]
		cmp al,0
		je StrLenEnd
		inc si
		inc cx
		jmp StrLenLoop
	StrLenEnd:
	
	mov ax,cx

	mov sp,bp
	pop bp
	ret 2

StrCpy:
	push bp
	mov bp,sp

	mov si,[bp+4]
	mov di,[bp+6]
	

	StrCpyLoop:
		mov al,[si]
		cmp al,0
		je StrCpyEnd
		mov [di],al
		inc si
		inc di
		jmp StrCpyLoop
	StrCpyEnd:
	
	mov byte[di],0

	mov sp,bp
	pop bp
	ret 4

StrCmp:
	push bp
	mov bp,sp

	mov si,[bp+4]
	mov di,[bp+6]

	push si
	call StrLen
	mov cx,ax
	push di
	call StrLen
	cmp ax,cx
	jne StrCmpFalse

	mov si,[bp+4]
	mov di,[bp+6]
	StrCmpLoop:
		mov al,[si]
		cmp al,[di]
		jne StrCmpFalse
		cmp al,0
		je StrCmpTrue
		inc si
		inc di
		jmp StrCmpLoop
	

	StrCmpFalse:
		push str_false
		call PrintStr
		call PrintLF
		mov ax,0
		jmp StrCmpEnd

	StrCmpTrue:
		push str_true
		call PrintStr
		call PrintLF
		mov ax,1
		jmp StrCmpEnd

StrCmpEnd:

	mov sp,bp
	pop bp

	ret 4

LoadSectorDirectory:
	push bp
	mov bp,sp

	mov ax,0x840
	mov es,ax
	mov ch,0
	mov cl,

	mov sp,bp
	pop bp
	ret 2

ReadDisk:
	push bp
	mov bp,sp

	mov ax,0x860
	mov es,ax

	mov ax,[bp+4]
	mov bl,18
	div bl
	mov ch,al
	mov cl,ah


	mov ah,2
	mov al,1
	mov dh,0
	mov dl,0

	xor bx,bx
	int 0x13
	jc ReadDiskError
	jmp ReadDiskEnd

	ReadDiskError:
		push str_error
		call PrintStr
		call PrintLF
		jmp ReadDiskEnd

ReadDiskEnd:

	mov sp,bp
	pop bp
	ret 2

KernelEnd:
	jmp $	
