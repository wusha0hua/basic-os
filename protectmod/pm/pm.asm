%ifdef    debug
isdebug   equ   1
%else
isdebug   equ   0
%endif


DEF_INITSEG	equ	0x9000    ;MBR程序挪动后的目标地址
DEF_SYSSEG	equ	0x1000    ;SYSEM模块放置地址
DEF_SETUPSEG	equ	0x9020    ;SETUP模块放置地址


SETUPLEN equ 4                ;SETUP模块长度扇区数
BOOTSEG  equ 0x07c0           ;MBR启动地址
INITSEG  equ DEF_INITSEG      ;MBR程序挪动后的目标地址0x9000
SETUPSEG equ DEF_SETUPSEG     ;SETUP模块放置地址0x9020
SYSSEG   equ DEF_SYSSEG       ;SYSEM模块放置地址0x1000

SETUPSector   equ   2                    ;SETUP开始扇区号
SYSSector     equ   SETUPSector+SETUPLEN ;SYSTEM开始扇区号6
SYScylind     equ   7                    ;SYSTEM读到的柱面数(8*36>260扇区)


;root_dev定义在引导扇区508，509字节处
;当编译内核时，你可以在Makefile文件中指定自己的值。内核映像文件Image的
;创建程序tools/build会使用你指定的值来设置你的根文件系统所在设备号。

ROOT_DEV equ 0 ;根文件系统设备使用与系统引导时同样的设备(不指定)；
SWAP_DEV equ 0 ;交换设备使用与系统引导时同样的设备(不指定)；


;设备号=主设备号*256 + 次设备号（也即dev_no = (major<<8) + minor ）
;主设备号：1-内存,2-磁盘,3-硬盘,4-ttyx,5-tty,6-并行口,7-非命名管道）
;0x300 - /dev/hd0 - 代表整个第1个硬盘；
;0x301 - /dev/hd1 - 第1个盘的第1个分区；
;…
;0x304 - /dev/hd4 - 第1个盘的第4个分区；
;0x305 - /dev/hd5 - 代表整个第2个硬盘；
;0x306 - /dev/hd6 - 第2个盘的第1个分区；
;…
;0x309 - /dev/hd9 - 第2个盘的第4个分区；

;次设备号 = type*4 + nr，其中
;nr为0-3分别对应软驱A、B、C或D；type是软驱的类型（2:1.2MB或7:1.44MB等）。
;因为7*4+0=28=0x1c，所以/dev/PS0 指的是1.44MB A驱动器,其设备号是0x021c

jmp  start

start:
     mov   ax,0        ;BIOS把引导扇区加载到0x7c00时,ss=0x00,sp=0xfffe
     mov   ss,ax
     mov   sp,BOOTSEG  ;重新定义堆栈0x7c00

     mov   ax,BOOTSEG
     mov   ds,ax       ;为显示各种提示信息做准备
     mov   si, welcome
     call  showmsg     ;打印"Linux"

     ;0x021c :/dev/PS0 - 1.44Mb 软驱A盘
     mov   word  [root_dev],0x021c
     ;不指定,将软驱A设置成根文件系统设备保存在root_dev


        ;1.将bootsect程序从0x07c0复制到0x9000（共1个扇区512B）
        mov	ax, INITSEG
	mov	es,ax
	mov	cx, 256
	sub	si,si
	sub	di,di
	rep                  ;循环挪动次数=512B/16B
	movsw                ;一次挪动16B，
        jmp	INITSEG:go

;完成复制后，CPU将会跳转到这里
go:	mov	ax,cs        ;到新的段地址后重新设置DS
        mov     ds,ax        ;为显示各种提示信息做准备
        mov     si, msg1
        call    showmsg      ;打印必要信息

        mov   ax,cs        ;重新定义堆栈,栈顶:0x9ff00-12（参数表长度=0x9fef4
        mov   ss,ax        ;因为栈顶后面安排了一个长度12的自建驱动器参数表
        mov   sp,0xfef4    ;刨除掉SS段值0x9000*10后,SP的偏移量是0xfef4

        ;2.将setup程序装载到0x9020（共4个扇区4*512B）
        mov     si, msg2
        call    showmsg
        mov	ax, SETUPSEG            ;设置setup装载到的目标段地址
        mov	es,ax                   ;设置setup装载到的目标段地址
        mov     byte [sector+11],SETUPSector    ;设置开始读取的扇区号:2
        call    loadsetup


        ;3.将system程序装载到0x1000（共240个扇区4*512B）
        mov     si, msg3
        call    showmsg
        mov	ax, SYSSEG            ;设置system装载到的目标段地址
        mov	es,ax                 ;设置system装载到的目标段地址
        mov     byte [sector+11],SYSSector      ;设置开始读取的扇区号:6
        call    loadsystem
        ;jmp     $                    ;调试

        jmp     SETUPSEG:0            ;bootsect运行完毕，跳到setup:0x9020


showmsg:                              ;打印字符串子程序
     call  newline
     call  printstr
     call  newline
     ret



;读软盘逻辑扇区2-5共4个扇区
loadsetup:
     call    read1sector
     MOV     AX,ES
     ADD     AX,0x0020                  ;一个扇区占512B=200H，刚好能被整除成完整的段
     MOV     ES,AX                      ;因此只需改变ES值，无需改变BX即可。
     inc     byte [sector+11]             ;读完一个扇区
     cmp     byte [sector+11],SETUPLEN+1+1 ;读到的结束扇区
     jne     loadsetup
     ret




;读软盘逻辑扇区6-8*36共282个扇区
loadsystem:
     call    read1sector
     MOV     AX,ES
     ADD     AX,0x0020           ;一个扇区占512B=200H，刚好能被整除成完整的段
     MOV     ES,AX               ;因此只需改变ES值，无需改变BX即可。
     inc   byte [sector+11]       ;读完一个扇区
     cmp   byte [sector+11],18+1  ;最大扇区编号18,
     jne   loadsystem
     mov   byte [sector+11],1
     inc   byte [header+11]       ;读完一个磁头
     cmp   byte [header+11],1+1   ;最大磁头编号1
     jne   loadsystem
     mov   byte [header+11],0
     inc   byte [cylind+11]        ;读完一个柱面
     cmp   byte [cylind+11],SYScylind+1
     jne   loadsystem

     ret


numtoascii:     ;将2位数的10进制数分解成ASII码才能正常显示。
                ;如柱面56 分解成出口ascii: al:35,ah:36
     mov ax,0
     mov al,cl  ;输入cl
     mov bl,10
     div bl
     add ax,3030h
     ret

readinfo:       ;实时显示当前读到哪个扇区、哪个磁头、哪个柱面
     mov si,cylind
     call  printstr
     mov si,header
     call  printstr
     mov si,sector
     call  printstr
     ret



read1sector:  ;读1扇区通用程序。扇区参数由 sector header  cylind控制

       mov   cl, [sector+11]   ;为了能实时显示读到的物理位置
       call  numtoascii
       mov   [sector+7],al
       mov   [sector+8],ah

       mov   cl,[header+11]
       call  numtoascii
       mov   [header+7],al
       mov   [header+8],ah

       mov   cl,[cylind+11]
       call  numtoascii
       mov   [cylind+7],al
       mov   [cylind+8],ah

       MOV        CH,[cylind+11]    ;柱面开始读
       MOV        DH,[header+11]    ;磁头开始读
       mov        cl,[sector+11]    ;扇区开始读

        call       readinfo        ;显示软盘读到的物理位置
        mov        di,0
retry:
        MOV        AH,02H    ; AH=0x02 : AH设置为0x02表示读取磁盘
        MOV        AL,1      ; 要读取的扇区数
        mov        BX,    0  ; ES:BX表示读到内存的地址
        MOV        DL,00H    ; 驱动器号,0表示软盘A,硬盘C:80H C 硬盘D:81H
        INT        13H       ; 调用BIOS 13号中断，磁盘相关功能
        JNC        READOK    ; 未出错则跳转到READOK，出错的话EFLAGS的CF位置1
           inc     di
           MOV     AH,0x00
           MOV     DL,0x00   ; A驱动器
           INT     0x13      ; 重置驱动器
           cmp     di, 5     ; 软盘很脆弱，同一扇区如果重读5次都失败就放弃
           jne     retry

           mov     si, Fyerror
           call    printstr
           call    newline
           jmp     exitread
READOK:    mov     si, FloppyOK
           call    printstr
           call    newline
exitread:
           ret




printstr:                  ;显示指定的字符串, 以'$'为结束标记
      mov al,[si]
      cmp al,'$'
      je disover
      mov ah,0eh
      int 10h
      inc si
      jmp printstr
disover:
      ret

newline:                     ;显示回车换行
      mov ah,0eh
      mov al,0dh
      int 10h
      mov al,0ah
      int 10h
      ret

welcome db '(i)Linux-bootsect!','$'

msg1 db '1.bootsect to 0x9000','$'
msg2 db '2.setup to 0x9020','$'
msg3 db '3.system  to 0x1000','$'

cylind  db 'cylind:?? $',0    ; 设置开始读取的柱面编号
header  db 'header:?? $',0    ; 设置开始读取的磁头编号
sector  db 'sector:?? $',1,   ; 设置开始读取的扇区编号
FloppyOK db '-Floppy Read OK','$'
Fyerror db '-Floppy Read Error' ,'$'

times 512-2*3-($-$$) db 0     ;MBR程序中间部分用0填充

swap_dev:
	dw SWAP_DEV     ;2Byte,存放交换系统所在设备号(init/main.c中会用)。
root_dev:
	dw ROOT_DEV     ;2Byte,存放根文件系统所在设备号(init/main.c中会用)。

boot_flag: db 0x55,0xaa	  ;2Byte,MBR启动标记


3.setup.asm

;******************************************************
;****Linux操作系统Nasm引导程序:setup,制作者:Mr.Jiang***
;*************2020-10-20*******************************

%include "config.inc"

INITSEG  EQU DEF_INITSEG   ;全部同bootsect
SYSSEG   EQU DEF_SYSSEG
SETUPSEG EQU DEF_SETUPSEG

jmp      start

start:

     mov   ax,SETUPSEG
     mov   ds,ax        ;为显示各种提示信息做准备
     mov   si, welcome
     call  showmsg      ;打印"Welcome Linux"

     mov   ax,INITSEG
     mov   es,ax        ;将setup模块的各类数据保存在0x9000?处

;1.取扩展内存的大小值（KB）
     mov   si, msg1
     call  showmsg

     mov	ah,0x88
     int	0x15      ;通过调用BIOS中断实现
     mov	[es:2],ax    ;将扩展内存数值存在0x90002处（1个字）。



;2.检查显示方式（EGA/VGA）并取参数。
     mov   si, msg2
     call  showmsg

     	mov	ah,0x12
	mov	bl,0x10
	int	0x10
	mov	[es:8],ax
	mov	[es:10],bx     ;0x9000A =安装的显示内存；0x9000B=显示状态(彩/单色)
	mov	[es:12],cx     ;0x9000C =显示卡特性参数。

	mov ax,0x5019       ;在ax中预置屏幕默认行列值（ah = 80列；al=25行）。
	mov [es:14],ax         ;保存屏幕当前行列值（0x9000E，0x9000F）。

	mov	ah,0x03	    ;取屏幕当前光标位置
	xor	bh,bh
	int	0x10
	mov	[es:0],dx	    ;保存在内存0x90000处（2字节）


;3.取显示卡当前显示模式
        mov   si, msg3
        call  showmsg

      	mov	ah,0x0f
	int	0x10
	mov	[es:4],bx	    ;0x90004(1字)存放当前页
	mov	[es:6],ax	    ;0x90006存放显示模式；0x90007存放字符列数。

;4.取第一个硬盘的信息（复制硬盘参数表）。
      ;第1个硬盘参数表的首地址竟然是中断0x41的中断向量值
      ;而第2个硬盘参数表紧接在第1个表的后面，中断0x46的向量向量值
      ;也指向第2个硬盘的参数表首址。表的长度是16个字节。
        mov   si, msg4
        call  showmsg

        push    ds           ;由于复制数据要修改DS的值，因此暂存起来
      	mov	ax,0x0000
	mov	ds,ax
	lds	si,[4*0x41]
	mov	ax,INITSEG
	mov	es,ax
	mov	di,0x0080     ;0x90080处存放第1个硬盘的表
	mov	cx,0x10
	rep
	movsb

;5.取第2个硬盘的信息（复制硬盘参数表）。
        pop   ds             ;恢复DS为本段setup段地址，才能正常打印字符串
        mov   si, msg5
        call  showmsg

        push    ds           ;由于复制数据要修改DS的值，因此暂存起来
      	mov	ax,0x0000
	mov	ds,ax
	lds	si,[4*0x46]
	mov	ax,INITSEG
	mov	es,ax
	mov	di,0x0090     ;0x90090处存放第2个硬盘的表
	mov	cx,0x10
	rep
	movsb

;6.检查系统是否有第2个硬盘。如果没有则把第2个表清零。

        pop   ds              ;恢复DS的值，才能正常打印字符串
        mov   si, msg6
        call  showmsg

      	mov	ax,0x01500
	mov	dl,0x81
	int	0x13
	jc	no_disk1
	cmp	ah,3
	je	is_disk1
no_disk1:
	mov	ax,INITSEG
	mov	es,ax
	mov	di,0x0090
	mov	cx,0x10
	mov	ax,0x00
	rep
	stosb
is_disk1:

;7.现在要进入保护模式了
        mov   si, msg7
        call  showmsg

        mov   si, msg8
        call  showmsg

        mov   cx,14
line:   call  newline       ;循环换行,清除一些屏幕显示
        loop  line

        cli                 ;禁用16位中断

;8.将system模块移到正确的位置。
        ;bootsect引导程序会把 system 模块读入到内存 0x10000（64KB）开始的位置
        ;下面这段程序是再把整个system模块从 0x10000移动到 0x00000位置。即把从
        ;0x10000到0x8ffff 的内存数据块（512KB）整块地向内存低端移动了64KB字节。
        call  mov_system    ;会覆盖实模式下的中断区，BIOS中断再也无法使用



;9.装载寄存器IDTR和GDTR
	mov	ax,SETUPSEG	;ds指向本程序(setup)段
	mov	ds,ax
	lidt	[idt_48]	;加载IDTR
	lgdt	[gdt_48]	;加载GDTR

;10.现开启A20地址线

       call empty_8042          ;8042状态寄存器，等待输入缓冲器空。
                                ;只有当输入缓冲器为空时才可以对其执行写命令。
       mov al,0xD1              ;0xD1命令码-表示要写数据到
       out 0x64,al              ;8042的P2端口。P2端口位1用于A20线的选通。
       call empty_8042          ;等待输入缓冲器空，看命令是否被接受。
       mov al,0xDF              ;A20 on ! 选通A20地址线的参数。
       out 0x60,al              ;数据要写到0x60口。
       call empty_8042          ;若此时输入缓冲器为空，则表示A20线已经选通。

;11.设置8259A中断芯片,即int 0x20--0x2F
       call  set_8259A

;12.打开保护模式PE开关
       mov	ax,0x0001	;保护模式比特位(PE)
       lmsw	ax		;就这样加载机器状态字!



;13.跳转触发到32位保护模式代码
       ;jmp dword 1*8:inprotect+SETUPSEG*0x10 ;保护模式下的段基地址:0x90200
                               ;这句是调试验证进入保护模式后系统是否正常
       jmp dword 1*8:0         ;setup程序到此结束
                               ;跳转到0x00000,也即system程序(head.asm)


;把整个system模块从 0x10000移动到 0x00000位置。
mov_system:
        mov	ax,0x0000
	cld			;'direction'=0, movs moves forward
do_move:
	mov	es,ax		;es:di是目的地址(初始为0x0:0x0)
	add	ax,0x1000
	cmp	ax,0x9000       ;已把最后一段（从0x8000段开始的64KB）移动完？
	jz	end_move
	mov	ds,ax		;ds:si是源地址(初始为0x1000:0x0)
	sub	di,di
	sub	si,si
	mov 	cx,0x8000      ;移动0x8000字（64KB字节）。
	rep
	movsw
	jmp	do_move
end_move:  ret


;设置8259A中断芯片
set_8259A:
        mov	al,0x11
	out	0x20,al
	dw	0x00eb,0x00eb	;jmp $+2, jmp $+2
	out	0xA0,al
	dw	0x00eb,0x00eb
	mov	al,0x20        ;Linux系统硬件中断号被设置成从0x20开始
	out	0x21,al
	dw	0x00eb,0x00eb
	mov	al,0x28		;start of hardware int's 2 (0x28)
	out	0xA1,al
	dw	0x00eb,0x00eb
	mov	al,0x04		;8259-1 is master
	out	0x21,al
	dw	0x00eb,0x00eb
	mov	al,0x02		;8259-2 is slave
	out	0xA1,al
	dw	0x00eb,0x00eb
	mov	al,0x01		;8086 mode for both
	out	0x21,al
	dw	0x00eb,0x00eb
	out	0xA1,al
	dw	0x00eb,0x00eb
	mov	al,0xFF		;屏蔽主芯片所有中断请求。
	out	0x21,al
	dw	0x00eb,0x00eb
	out	0xA1,al         ;屏蔽从芯片所有中断请求。
        ret

empty_8042:                     ;只有当输入缓冲器为空时（状态寄存器位1 = 0）
                                ;才可以对其执行写命令。
	dw	0x00eb,0x00eb
	in	al,0x64	        ;读AT键盘控制器状态寄存器。
	test	al,2		;测试位1，输入缓冲器满？
	jnz	empty_8042	;yes - loop
	ret


idt_48:  dw 0x800              ;这里不能像书上设置成0,否则VMWARE调试会出错！
         dw 0,0                ;IDT全部中断都设置成无效
gdt_48:  dw 0x800              ;GDT长度设置为 2KB（0x7ff）表中共可有 256项。
         dw 512+gdt,0x9        ;GDT物理地址：0x90200 + gdt



gdt:
	dw	0,0,0,0		;0#描述符，它是空描述符

	dw	0x07FF		;8Mb - limit=2047 (2048*4096=8Mb)
	dw	0x0000		;base address=0
        dw	0x9A00		;code read/exec 代码段为只读、可执行
	dw	0x00C0		;granularity=4096, 386 颗粒度为4096，32位模式

	dw	0x07FF		;8Mb - limit=2047 (2048*4096=8Mb)
	dw	0x0000		;base address=0
	dw	0x9200		;data read/write  数据段为可读可写
	dw	0x00C0		;granularity=4096, 386颗粒度为4096，32位模式

showmsg:
     call  newline
     call  printstr
     ret

printstr:                  ;显示指定的字符串, 以'$'为结束标记
      mov al,[si]
      cmp al,'$'
      je disover
      mov ah,0eh
      int 10h
      inc si
      jmp printstr
disover:
      ret

newline:                     ;显示回车换行
      mov ah,0eh
      mov al,0dh
      int 10h
      mov al,0ah
      int 10h
      ret

welcome db '(ii) Welcome Linux---setup!',0x0d,0x0a,'$'

msg1 db '1.Get memory size','$'
msg2 db '2.Check for EGA/VGA and some config parameters','$'
msg3 db '3.Get video-card data','$'
msg4 db '4.Get hd0 data','$'
msg5 db '5.Get hd1 data','$'
msg6 db '6.Check that there IS a hd1','$'
msg7 db '7.Move system from 0x10000 to 0x00000','$'
msg8 db '8.Now Ready to Protect Mode!','$'


[bits 32]
inprotect:                          ;测试进入保护模式后是否正常
mov eax,2*8 ;加载数据段选择子(0x10)
mov ds,eax

mov  esi,sysmsg+SETUPSEG*0x10   ;保护模式DS=0,数据需跨过段基址用绝对地址访问
mov  edi, 0xb8000+18*160        ;显示在第18行,显卡内存地址也需用绝对地址访问
call printnew

mov  esi,promsg+SETUPSEG*0x10
mov  edi, 0xb8000+20*160        ;显示在第20行
call printnew

mov  esi,headmsg+SETUPSEG*0x10
mov  edi, 0xb8000+22*160        ;显示在第22行
call printnew

jmp  $


printnew:                       ;保护模式下显示字符串, 以'$'为结束标记
        mov  bl ,[ds:esi]
        cmp  bl, '$'
        je   printover
        mov  byte [ds:edi],bl
        inc  edi
        mov  byte [ds:edi],0x0c  ;字符红色
        inc  esi
        inc  edi
        jmp  printnew
printover:
        ret



sysmsg  db '(iii) Welcome Linux---system!','$'
promsg  db '1.Now Already in Protect Mode','$'
headmsg db '2.Run head.asm in system program','$'

times 512*4-($-$$) db 0    ;控制setup最终的机器代码长度为4个扇区


4.head.asm

;*********************************************************
;****Linux操作系统Nasm引导程序:head,制作者:Mr.Jiang***
;*************2020-10-27**********************************

%include "config.inc"

SETUPSEG equ DEF_SETUPSEG  ;全部同bootsect和setup
SYSSEG   equ DEF_SYSSEG

_pg_dir  equ  0x0000     ;页目录地址,大小4KB.

pg0      equ  0x1000     ;第1个页表地址,大小4KB.
pg1      equ  0x2000     ;第2个页表地址,大小4KB.
pg2      equ  0x3000     ;第3个页表地址,大小4KB.
pg3      equ  0x4000     ;第4个页表地址,大小4KB.

_tmp_floppy_area   equ  0x5000   ;软盘缓冲区地址.
len_floppy_area   equ  0x400     ;软盘缓冲区大小1KB

[bits 32]                        ;指定代码为32位保护模式

jmp start

;这条伪指令不会执行任何操作，只在编译的时候起填充数字作用。
times _tmp_floppy_area+len_floppy_area-($-$$) db 0  ;
;一个语句实现页目录和页表地址区域清0，省去程序后面Linux源代码中的清0部分
;使head程序从0x5000+0x400位置开始放置（仅除第一条jmp指令外）。


;这里已经处于32位运行模式,首先设置ds,es,fs,gs为setup.s中构造的内核数据段
;并将堆栈放置在stack_start指向的user_stack数组区，然后使用本程序后面定义的
;新中断描述符表和全局段描述表。新全局段描述表中初始内容与setup.s中的基本一样，
;仅段限长从8MB修改成了16MB。stack_start定义在kernel/sched.c。它指向user_stack
;数组末端的一个长指针。设置这里使用的栈，姑且称为系统栈。但在移动到任务0执行
;（init/main.c中137行）以后该栈就被用作任务0和任务1共同使用的用户栈了。

start:
mov eax,2*8                     ;加载数据段选择子(0x10)
mov ds,eax                      ;把所有数据类段寄存器全部指向GDT的数据段地址
mov es,eax
mov fs,eax
mov gs,eax
mov ss,eax


mov  esi,sysmsg                 ;保护模式DS=0,数据用绝对地址访问
mov  cl, 0x0c                   ;颜色红
mov  edi, 0xb8000+13*160        ;显示在第18行,显卡内存地址也需用绝对地址访问
call printnew

mov  esi,promsg
mov  cl, 0x0c
mov  edi, 0xb8000+15*160        ;显示在第20行
call printnew

mov  esi,headmsg
mov  cl, 0x0c
mov  edi, 0xb8000+16*160        ;显示在第22行
call printnew

mov  esp,0x1e25c                ; 重新设置堆栈，暂时设置值参见书
                                ;《Linux内核设计的艺术_图解Linux操作系统架构
                                ; 设计与实现原理》P27
                                ; Linus源程序中是lss _stack_start,%esp
                                ; _stack_start,。定义在kernel/sched.c，82-87行
                                ; 它是指向 user_stack数组末端的一个长指针
call setup_idt
call setup_gdt

jmp  1*8:newgdt                   ;改变CS的值来触发新GDT表生效
     nop
     nop
newgdt:                         ;如能正常打印则表明程序正常运行,新GDT表无问题
mov  esi,gdtmsg                 ;保护模式DS=0,数据用绝对地址访问
mov  cl, 0x09                   ;颜色蓝
mov  edi, 0xb8000+17*160        ;显示在第18行,显卡内存地址也需用绝对地址访问
call printnew


;call test_keyboard            ;开键盘中断并按键测试,显示外部中断体系正常

sti ;开中断
int 00h                        ;手工系统中断调用,测试显示内部中断体系也正常
cli ;关掉中断


call  A20open
mov  esi,a20msg                 ;保护模式DS=0,数据用绝对地址访问
mov  cl, 0x09                   ;蓝色
mov  edi, 0xb8000+19*160        ;显示在第18行,显卡内存地址也需用绝对地址访问
call printnew


;前面3个入栈0值分别表示main函数的参数envp、argv指针和argc，但main()没有用到。
;push _main入栈操作是模拟调用main时将返回地址入栈的操作，所以如果main.c程序
;真的退出时，就会返回到这里的标号L6处继续执行下去，也即死循环。push _main将
;main.c的地址压入堆栈。这样，在设置分页处理（setup_paging）结束后执行'ret'
;返回指令时就会将main.c;程序的地址弹出堆栈，并去执行main.c程序了。

push 0 ;These are the parameters to main :-)
push 0 ;这些是调用main程序的参数（指init/main.c）。
push 0
push L6 ;return address for main, if it decides to.
push _main ;'_main'是编译程序对main的内部表示方法。
jmp  setup_paging   ;这里用的JMP而不是call，就是为了在setup_paging结束后的
                    ;ret指令能去执行C程序的main()
L6:
jmp L6 ;main程序绝对不应该返回到这里。不过为了以防万一，
     ;所以添加了该语句。这样我们就知道发生什么问题了。





_main:      ;这里暂时模拟出C程序main()
     mov  esi,mainmsg                ;保护模式DS=0,数据用绝对地址访问
     mov  cl, 0x09                   ;蓝色
     mov  edi, 0xb8000+22*160        ;指定显示在某行,显卡内存地址需用绝对地址
     call printnew                   ;0xb8000为字符模式下显卡映射到的内存地址
     ret


test_keyboard:       ; 测试键盘中断
mov al, 11111101b  ; 开启键盘中断开关
out 021h, al       ; 主8259, OCW1.
dw  0x00eb,0x00eb   ;时延
mov al, 11111111b   ; 屏蔽从芯片所有中断请求
out 0A1h, al       ; 从8259, OCW1.
dw	0x00eb,0x00eb  ;时延
ret


;Linux将内核的内存页表直接放在页目录之后，使用了4个表来寻址16 MB的物理内存。
;如果你有多于16 Mb的内存，就需要在这里进行扩充修改。
;每个页表长为4KB（1页内存页面），而每个页表项需要4个字节，因此一个页表共可存
;1024个表项。一个页表项寻址4KB的地址空间，则一个页表就可以寻址4MB的物理内存。
setup_paging:

;首先对5页内存（1页目录 + 4页页表）清零。由于在程序第一行已经实现，此处可省。
;mov ecx,10
;xor eax,eax
;xor edi,edi  ;页目录从0x000地址开始。
;cld          ;edi按递增方向
;rep
;stosd         ;eax内容存到es:edi所指内存位置处，且edi增4。

;下面4句设置页目录表中的项。因为内核共有4个页表，所以只需设置4项(索引)。
;页目录项的结构与页表中项的结构一样，4个字节为1项。
;例如"pg0+7"表示：0x00001007，是页目录表中的第1项。
;则第1个页表所在的地址 = 0x00001007 & 0xfffff000 = 0x1000；
;第1个页表的属性标志 = 0x00001007&0x00000fff = 0x07,表示该页存在、用户可读写。
;一句指令就把页表的地址和属性完全完整定义了，这个写法设计得有点巧妙。
mov dword [_pg_dir],pg0+7       ;页表0索引 将直接覆盖0地址处的3字节长度jmp指令
mov dword [_pg_dir+4],pg1+7     ;页表1索引
mov dword [_pg_dir+8],pg2+7     ;页表2索引
mov dword [_pg_dir+12],pg3+7    ;页表3索引


;下面填写4个页表中所有项的内容，共有：4(页表)*1024(项/页表)=4096项(0-0xfff)，
;也即能映射物理内存 4096*4Kb = 16Mb。
;每项的内容是：当前项所映射的物理内存地址 + 该页的标志（这里均为7）。
;填写使用的方法是从最后一个页表的最后一项开始按倒退顺序填写。
;每一个页表中最后一项在表中的位置是1023*4 = 4092.
;此最后一页的最后一项的位置就是pg3+4092。
mov edi,pg3+4092;edi->最后一页的最后一项。
mov eax,0xfff007;16Mb - 4096 + 7 (r/w user,p) */
;最后1项对应物理内存页面的地址是0xfff000，
;加上属性标志7，即为0xfff007。
std ;方向位置位，edi值递减(4字节)。
goon:
stosd
sub eax,0x1000;每填写好一项，物理地址值减0x1000。
jge goon ;如果小于0则说明全添写好了。  jge是大于或等于转移指令


;现在设置页目录表基址寄存器cr3，指向页目录表。cr3中保存的是页目录表的物理地址
;再设置启动使用分页处理（cr0的PG标志，位31）
xor eax,eax ;pg_dir is at 0x0000 */ # 页目录表在0x0000处。
mov cr3,eax ;cr3 - page directory start */
mov eax,cr0
or eax,0x80000000  ;添上PG标志。
mov cr0,eax ; set paging (PG) bit */

# 软盘缓冲区: 共保留1024项，填充数值0。在程序第一行已经实现，此处可省。
;mov ecx,1024/4;
;xor eax,eax
;mov edi,_tmp_floppy_area  ;软盘缓冲区从0x5000地址开始。
;cld                      ;edi按递增方向
;rep
;stosd                    ;eax内容存到es:edi所指内存位置处，且edi增4。


mov  esi,pagemsg                ;保护模式DS=0,数据用绝对地址访问
mov  cl, 0x09                   ;蓝色字体
mov  edi, 0xb8000+20*160        ;指定显示在某行,显卡内存地址也需用绝对地址访问
call printnew

mov  esi,asmmsg                 ;保护模式DS=0,数据用绝对地址访问
mov  cl, 0x09                   ;蓝色字体
mov  edi, 0xb8000+21*160        ;指定显示在某行,显卡内存地址也需用绝对地址访问
call printnew

ret  ;setup_paging这里用的是返回指令ret。
;该返回指令的另一个作用是将压入堆栈中的main程序的地址弹出，
;并跳转到/init/main.c程序去运行。本程序到此就真正结束了。

;用于测试A20地址线是否已经开启。采用的方法是向内存地址0x000000处写入任意
;一个数值，然后看内存地址0x100000(1M)处是否也是这个数值。如果一直相同的话，
;就一直比较下去，也即死循环表示地址A20线没有选通，就不能使用1MB以上内存。
A20open:
       xor   eax, eax
       inc   eax
       mov   [0x000000],eax
       cmp   eax,[0x100000]
       je    A20open
       ret

printnew:                       ;保护模式下显示字符串, 以'$'为结束标记
        mov  bl ,[ds:esi]
        cmp  bl, '$'
        je   printover
        mov  byte [ds:edi],bl
        inc  edi
        mov  byte [ds:edi],cl  ;字符颜色
        inc  esi
        inc  edi
        jmp  printnew
printover:
        ret

setup_idt:
          ;暂时将所有的中断全部指向一个中断服务程序:ignore_int
          lea  edx,[ignore_int]   ;将ignore_int的有效地址（偏移值）值送edx
          mov  eax,0x00080000  ;将选择符0x0008置入eax的高16位中。
          mov  ax,dx           ;selector = 0x0008 = cs */
                               ;偏移值的低16位置入eax的低16位中。此时eax含有门
                               ;描述符低4字节的值。
          mov dx,0x8E00        ;interrupt gate - dpl=0, present
                               ;此时edx含有门描述符高4字节值,偏移地址高16位是0
          lea edi,[_idt]       ;_idt是中断描述符表的地址。
          ;以上为单独一个中断描述符的设置方法

          mov ecx,256          ;IDT表中创建256个中断描述符
;将上面的中断描述符重复放置256次，让所有的中断全部指向一个中断服务程序:哑中断
 rp_sidt:
          mov [edi],eax       ;将哑中断门描述符存入表中。
          mov [edi+4],edx     ;edx内容放到 edi+4 所指内存位置处。
          add  edi,8           ; edi指向表中下一项。
          loop rp_sidt

          lidt [idt_descr]       ;加载中断描述符表寄存器值。
          ret


;让所有的256中断都指向这个统一的中断服务程序
ignore_int:
           cli               ;首先应禁止中断,以免中断嵌套
           pushad            ;进入中断服务程序首先保存32位寄存器

           push ds           ;再保存所有的段寄存器
	   push es
	   push fs
	   push gs
	   push ss
	   mov  eax,2*8      ;进入断服务程序后所有数据类段寄存器都转到内核段
           mov ds,eax
           mov es,eax
           mov fs,eax
           mov gs,eax
           mov ss,eax

	  mov  esi,intmsg                ;保护模式DS=0,数据用绝对地址访问
          mov  cl, 0x09                  ;蓝色
          mov  edi, 0xb8000+18*160       ;指定显示在某行,显卡内存需用绝对地址
          call printnew

           pop ss             ;恢复所有的段寄存器
	   pop gs
	   pop fs
	   pop es
	   pop ds

           popad              ; 所有32位寄存器出栈恢复
           iret                ;中断服务返回指令


align 2 ;按4字节方式对齐内存地址边界。
dw    0 ;这里先空出2字节，这样_idt长字是4字节对齐的。

;下面是加载中断描述符表寄存器idtr的指令lidt要求的6字节操作数。
;前2字节是idt表的限长，后4字节是idt表在线性地址空间中的32位基地址。
idt_descr:
         dw 256*8-1 ;idt contains 256 entries # 共256项，限长=长度 - 1。
         dd _idt
         ret



setup_gdt:

        lgdt [gdt_descr] ;加载全局描述符表寄存器。
        ret


align 2 ;按4字节方式对齐内存地址边界。
dw    0 ;这里先空出2字节，这样_gdt长字是4字节对齐的。

;加载全局描述符表寄存器gdtr的指令lgdt要求的6字节操作数。前2字节是gdt表的限长，
;后4字节是gdt表的线性基地址。因为每8字节组成一个描述符项，所以表中共可有256项。
;符号_gdt是全局表在本程序中的偏移位置。
gdt_descr:
        dw 256*8-1
        dd _gdt




sysmsg  db '(iii) Welcome Linux---system!','$'
promsg  db '1.Now Already in Protect Mode','$'
headmsg db '2.Run head.asm in system program','$'
gdtmsg  db '3.Reset GDT success:New CS\EIP normal','$'
intmsg  db '4.Reset IDT success:Unknown interrupt','$'
a20msg  db '5.Check A20 Address Line Stdate:Open','$'
pagemsg db '6.Memory Page Store:Page Tables is set up','$'
asmmsg  db '7.Pure Asm Program:bootsect->setup->head(system) is Finished','$'
mainmsg db '8.Now Come to C program entry:Main()','$'


;IDT表和GDT表放在程序head的最末尾

;中断描述符表：256个，全部初始化为0。
_idt:    times 256  dq 0  ;idt is uninitialized # 256项，每项8字节，填0。


;全局描述符表。其前4项分别是：空项、代码段、数据段、系统调用段描述符，
;后面还预留了252项的空间，用于放置新创建任务的局部描述符(LDT)和对应的
;任务状态段TSS的描述符。
;(0-nul,1-cs,2-ds,3-syscall,4-TSS0,5-LDT0,6-TSS1,7-LDT1,8-TSS2 etc...)
_gdt: dq 0x0000000000000000 ;NULL descriptor */
      dq 0x00c09a0000000fff ;16Mb */ # 0x08，内核代码段最大长度16MB。
      dq 0x00c0920000000fff ;16Mb */ # 0x10，内核数据段最大长度16MB。
      dq 0x0000000000000000 ;TEMPORARY - don't use */
      times 252 dq 0        ;space for LDT's and TSS's etc */ # 预留空间。
