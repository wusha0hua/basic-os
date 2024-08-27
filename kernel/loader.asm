;0x000000007c54
mov ax,seg_start 
mov ds,ax
jmp start

str:
	str_hello db `---hello os---`,0
	str_error db `---error---`,0
	str_end db `---end---`,0
	str_sucess db `---sucess---`,0
	str_longjmp db `---long jump---`,0
sgm:
	seg_start equ 7c0h
	seg_nxt equ 800h
	
num:
	num_start_sector equ 1
	num_start_header equ 0
	num_start_cylind equ 0

	num_nxt_sector equ 2
	num_nxt_header equ 0
	num_nxt_cylind equ 0


start:
	call clear
	call hello
	call readsector	
	mov si,str_longjmp
	call PrintStr
	jmp seg_nxt:0
	jmp end 

clear:
	mov ax,3
	int 10h
	jmp return

hello:
	mov si,str_hello
	call PrintStr
	jmp return

PrintStr:
	mov al,[si]
	cmp al,0
	je return
	mov ah,0eh
	int 10h
	inc si
	jmp PrintStr
	call newline
	jmp return

readsector:
	mov ax,seg_nxt
	mov es,ax
	mov ah,2
	mov al,1
	mov bx,0
	mov dh,num_nxt_header
	mov cl,num_nxt_sector
	mov ch,num_nxt_cylind
	mov dl,0
	int 13h
	jnc sucess
	mov si,str_error
	call PrintStr
	jmp end
sucess:	
	mov si,str_sucess
	call PrintStr
	jmp return

newline:
	mov ah,0eh
	mov al,0dh
	int 10h
	mov al,0ah
	int 10h
	jmp return

return:
	ret

end:
	mov si,str_end
	call PrintStr
	jmp $

times 510-($-$$) db 0
db 55h,0aah



