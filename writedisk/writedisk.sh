nasm writedisk.asm -o writedisk.bin
dd if=writedisk.bin of=writedisk.img bs=512 count=1 conv=notrunc
xxd writedisk.img>writedisk.hex
