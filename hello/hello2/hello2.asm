section .data
hello db `hello os\n`
hello_len equ $-hello

section .bss
cs_val resb 4

section .text
global _start
_start:
	mov eax,1

