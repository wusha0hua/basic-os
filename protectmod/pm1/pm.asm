%macro Descriptor 3
	dw %2 & 0ffffh
	dw %1 & 0ffffh
	db (%1>>16) & 0ffh
	dw ((%2>>8) &0f00h)
	db (%1>>24) & 0ffh
%endmacro

DA_C equ 98h
DA_32 equ 4000h
DA_DRW equ 92h

org 0100h
jmp LABEL_BEGIN

section .gdt
LABEL_GDT: Descriptor 0,0,0
LABEL_DESC_CODE32: Descriptor 0,SegCode32Len-1,DA_C+DA_32
LABEL_DESC_VIDEO: Descriptor 0B8000h,0ffffh,DA_DRW
GdtLen equ $-LABEL_GDT
GdtPtr	dw GdtLen
		dd 0

SelectorCode32 equ LABEL_DESC_CODE32-LABEL_GDT
SelectorVideo equ LABEL_DESC_VIDEO-LABEL_GDT

section .s16
bits 16
LABEL_BEGIN:
mov ax,cs
mov ds,ax
mov es,ax
mov ss,ax
mov sp,0100h

mov ax,3
int 0x10

xor eax,eax
mov ax,cs
shl eax,4
add eax,LABEL_SEG_CODE32
mov word [LABEL_DESC_CODE32+2],ax
shr eax,16
mov byte [LABEL_DESC_CODE32+4],al
mov byte [LABEL_DESC_CODE32+7],ah

xor eax,eax
mov ax,ds
shl eax,4
add eax,LABEL_GDT
mov dword [GdtPtr+2],eax

lgdt  [GdtPtr]

cli

in al,92h
or al,00000010b
out 92h,al

mov eax,cr0
or eax,1
mov cr0,eax

jmp dword SelectorCode32:0

section .s32
bits 32

LABEL_SEG_CODE32:
mov ax,SelectorVideo
mov gs,ax

mov edi,(80*10+0)*2
mov ah,0ch
mov al,'P'
mov [gs:edi],ax

jmp $

SegCode32Len equ $-LABEL_SEG_CODE32
