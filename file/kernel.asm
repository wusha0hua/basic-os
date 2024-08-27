jmp kernel

str_kernel db "hello kernel",0

cmd_ls db "ls",0
cmd_touch db "touch",0
cmd_rm db "rm",0
cmd_error db "no command",0

sector_record equ 0x840

error_rm_no db "no such file",0


kernel:
	mov ax,0x800
	mov ds,ax
	mov ss,ax
	xor sp,sp
	push str_kernel
	call PrintStr
	call PrintLF 
	call LoadRecord
	call Console
	jmp $

WriteDisk:
	push bp
	mov bp,sp

	mov bx,0x20
	mov ax,[bp+4]
	mul bx
	add ax,0x840
	mov es,ax
	xor bx,bx
	mov ah,0x3
	mov al,1
	mov ch,0
	mov cl,4
	mov dh,0
	mov dl,0
	int 0x13

	mov sp,bp
	pop bp


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

PrintSpace:
	mov ah,0xe
	mov al,0x20
	int 0x10
	ret

Console:
	push bp
	mov bp,sp
	ConsoleLoop:
		call ReadCMD
		call Analysis

		jmp ConsoleLoop
	ConsoleEnd:
	mov sp,bp
	pop bp
	ret


ReadCMD:
	push bp
	mov bp,sp

		mov di,cmd
		mov cx,32
		ReadLoop:
			mov ah,0
			int 0x16
			cmp al,0xd
			je ReadEnd
			mov byte[di],al
			mov ah,0xe
			int 0x10
			inc di
			mov byte[di],0
			loop ReadLoop
		ReadEnd:
	call PrintLF	


	mov si,cmd
	mov di,op
	GetOPLoop:
		mov al,[si]
		cmp al,0x20
		je GetOPEnd
		cmp al,0
		je NoParam
		mov [di],al
		inc di
		inc si
		mov byte[di],0
		jmp GetOPLoop
	GetOPEnd:
	
	mov di,parameter
	inc si
	GetParamLoop:
		mov al,[si]
		cmp al,0
		je GetParamEnd
		mov [di],al
		inc si
		inc di
		mov byte[di],0
		jmp GetParamLoop
	GetParamEnd:
		
	jmp ReadCMDEnd

	NoParam:
		mov di,parameter
		mov byte[di],0
	

	ReadCMDEnd:
	;jmp ReadLoop
	mov sp,bp
	pop bp
	ret

Analysis:
	
	IsLs :
		mov si,cmd_ls
		mov di,op
		IsLsLoop:
			mov al,[di]	
			cmp al,byte[si]
			jne IsLsEnd
			cmp al,0
			je Ls
			inc si
			inc di
			jmp IsLsLoop
	IsLsEnd:
	
	IsTouch:
		mov si,cmd_touch
		mov di,op
		IsTouchLoop:
			mov al,[di]
			cmp al,byte[si]
			jne IsTouchEnd
			cmp al,0
			je Touch
			inc si
			inc di
			jmp IsTouchLoop
	
	IsTouchEnd:
	

	IsRm:
		mov si,cmd_rm
		mov di,op
		IsRmLoop:
			mov al,[di]
			cmp al,[si]
			jne IsRmEnd
			cmp al,0
			je Rm
			inc si
			inc di
			jmp IsRmLoop
	IsRmEnd:
	
	push cmd_error
	call PrintStr
	call PrintLF

	jmp AnalysisEnd


	Ls:
		mov ax,sector_record
		mov es,ax
		xor bx,bx
		mov cx,es:bx
		cmp cx,0
		je ListEnd
		add bx,32
		ListLoop:
			LsSearchLoop:
				mov al,byte es:bx
				cmp al,0
				jne LsSearchEnd
				add bx,32
				jmp LsSearchLoop
			LsSearchEnd:
			mov si,bx
			inc si
			mov ax,ds
			mov dx,es
			sub dx,ax
			shl dx,4
			mov ax,si
			add ax,dx
			push ax
			call PrintStr
			call PrintSpace
			add bx,0x20
			loop ListLoop
		ListLoopEnd:
			call PrintLF
		ListEnd:
		jmp AnalysisEnd

	Touch:
		mov ax,sector_record	
		mov es,ax
		xor bx,bx
		mov cx,es:bx
		add bx,32
		xor dx,dx
		inc dl
		TouchSearchLoop:
			mov al,byte es:bx
			cmp al,0
			je TouchTouchEnd
			add bx,32
			inc dl
			jmp TouchSearchLoop
		TouchTouchEnd:
		mov es:bx,dl
		inc bx
		mov ax,es
		mov dx,ds
		shl ax,4
		shl dx,4
		sub ax,dx
		add ax,bx
		push ax
		push parameter
		call WriteStr
		
		xor bx,bx
		inc byte es:bx

		jmp AnalysisEnd


	Rm:
		mov ax,sector_record
		mov es,ax
		xor bx,bx
		mov cx,es:bx
		xor dx,dx
		add bx,32
		RmSearchLoop:
			cmp dx,cx
			je RmSearchFail
			RmSearchLoop2:
				mov al,es:bx
				cmp al,0
				jne RmSearchEnd
				add bx,0x20
				jmp RmSearchLoop2
			RmSearchEnd:
			mov si,bx
			inc si
			mov di,parameter
			RmCmpName:
				mov al,byte es:si
				cmp al,[di]
				jne RmCmpNameEnd
				cmp al,0
				je RmSearched
				inc si
				inc di
				jmp RmCmpName
			RmCmpNameEnd:
			add bx,0x20
			inc dx
			jmp RmSearchLoop

		jmp AnalysisEnd

		RmSearched:
			mov byte es:bx,0
			dec word es:0
			jmp AnalysisEnd

		RmSearchFail:
			push error_rm_no
			call PrintStr
			call PrintLF
			jmp AnalysisEnd
	
		AnalysisEnd:

	
	ret

WriteStr:
	push bp
	mov bp,sp

	mov si,[bp+4]
	mov di,[bp+6]

	WriteStrLoop:
		mov al,[si]
		cmp al,0
		je WriteStrEnd
		mov [di],al
		inc di
		inc si
		jmp WriteStrLoop
	WriteStrEnd:

	mov sp,bp
	pop bp
	
	ret 4

LoadRecord:
	mov ax,0x820
	mov es,ax
	xor bx,bx
	mov ah,2
	mov al,1
	mov dh,0
	mov cl,3
	mov ch,0
	mov dl,0
	int 0x13

	mov ax,sector_record
	mov es,ax
	mov ah,2
	mov al,1
	mov dh,0
	mov cl,4
	mov ch,0
	mov dl,0
	int 0x13

	ret

cmd db 128 dup(0)
op db 32 dup(0)
parameter db 96 dup(0)

times 512*2-($-$$) db 0

RootDescriptor:
dw 0
times 32-($-RootDescriptor) db 0

times 512*2880-($-$$) db 0
