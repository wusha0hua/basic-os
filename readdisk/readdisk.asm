jmp start

seg_start equ 0x7c0

max_sector equ 4
max_cylind equ 1
max_header equ 1

now_sector db 0
now_cylind db 0
now_header db 0

str_hello db "hello os",0
str_end db "os end",0

read db "start read : ",0
str_sector db " sector ",0
str_cylind db " cylind ",0
str_header db " header ",0

str_error db "error!",0

flag db 1 ,2 ,3 ,4 ,5 ,6 ,7 ,8 ,9 ,10 ,11 ,12 ,13 ,14 ,15 ,16 ,17 ,18 ,19 ,20 ,21 ,22 ,23 ,24 ,25 ,26 ,27 ,28 ,29 ,30 ,31 ,32 ,33 ,34 ,35 ,36 ,37 ,38 ,39 ,40 ,41 ,42 ,43 ,44 ,45 ,46 ,47 ,48 ,49 ,50 ,51 ,52 ,53 ,54 

start:
	mov ax,seg_start
	mov ds,ax
	call clear
	mov si,str_hello
	call PrintStr
	call PrintLF
	call loaddisk_init
	call test
	jmp end

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
	jmp return

loaddisk_init:
	mov si,now_sector
	mov byte[si],1
	mov si,now_header
	mov byte[si],0
	mov si,now_header
	mov byte[si],0

	mov ax,seg_start
	mov es,ax
	
	call loaddisk_start
	jmp return

loaddisk_start:;at the beginning , now_sector=1,now_cylind=0,now_cylind=0,max_header=2,max_cylind=80,max_sector=19
;if_heaer:
;if(now_header<max_header)
;{
;if_cylind:
;	if(now_cylind<max_cylind)
;	{
;	if_sector:
;		if(now_sector<max_sector)
;		{
;			call readsector
;			inc now_sector
;			mov ax,es
;			add ax,0x20
;			mov es,ax
;			jmp if_sector
;		}
;		else
;		{	
;			mov now_sector,1
;			inc now_cylind
;			jmp if_cylind
;		}
;	}
;	else
;	{
;		mov now_cylind,0
;		mov now_sector,0
;		inc now_header
;		jmp if_heaer
;	}
;}
;else
;{
;	jmp return
;}

if_header:
	mov si,now_header
	mov ah,max_header
	mov al,byte[si]
	cmp al,ah
	jnc return 
if_cylind:
	mov si,now_cylind
	mov al,byte[si]
	mov ah,max_cylind
	cmp al,ah
	jnc next_header
if_sector:
	mov si,now_sector
	mov al,byte[si]
	mov ah,max_sector
	cmp al,ah
	jnc next_cylind

	mov ax,es
	add ax,0x20
	mov es,ax
	call readsector
	mov si,now_sector
	inc byte[si]
	jmp if_sector
	

next_header:
	mov si,now_cylind
	mov byte[si],0
	mov si,now_sector
	mov byte[si],1
	mov si,now_header
	inc byte[si]
	jmp if_header

next_cylind:
	mov si,now_sector
	mov byte[si],1
	mov si,now_cylind
	inc byte[si]
	jmp if_cylind

	jmp return



readsector:
	mov si,now_header
	mov dh,byte[si]
	mov si,now_cylind
	mov ch,byte[si]
	mov si,now_sector
	mov cl,byte[si]
	call PrintReadInfo
	mov ah,0x2
	mov al,1
	mov bx,0
	mov dl,0
	int 0x13

	jnc return
	
	mov si,str_error
	call PrintStr
	call PrintLF

	jmp return


PrintReadInfo:
	mov si,read
	call PrintStr
	mov si,str_header	
	call PrintStr
	mov si,now_header
	call PrintChar
	mov si,str_cylind
	call PrintStr
	mov si,now_cylind
	call PrintChar
	mov si,str_sector
	call PrintStr
	mov si,now_sector
	call PrintChar
	call PrintLF

	jmp return

PrintChar:
	mov al,[si]
	add al,0x30
	mov ah,0xe
	int 0x10

	jmp return

return:
	ret

end:
	mov si,str_end
	call PrintStr
	call PrintLF
	jmp $

str_right db "right",0

test:
	mov ax,ds
	mov es,ax
	xor di,di

s:
	mov ax,es
	add ax,0x20
	mov es,ax
	mov bx,flag
	mov al,byte[bx+di]
	mov ah,byte[es:0]
	cmp al,ah
	jnz error
	mov si,str_right
	call PrintStr
	call PrintLF
	cmp dx,max_sector
	jz return
	inc di

error:
	mov si,str_error
	call PrintStr
	call PrintLF
	jmp s 

times 510-($-$$) db 0
db 0x55,0xaa

db 0xff
times 512*2-($-$$) db 0

db 0xff
times 512*3-($-$$) db 0
