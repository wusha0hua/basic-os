bits 32
jmp kernel

str_kernel db "hello kernel",0

kernel:
	mov ax,0x10
	mov ds,ax

	mov ecx,0x10
	xor ebx,ebx
	xor edx,edx
	mov ebx,0xb8000+1*160
	mov al,'a'
	
	s:
	mov byte [ebx+edx],al
	mov byte [ebx+edx+1],0xc
	inc al
	add edx,2
	loop s
	
	jmp $

