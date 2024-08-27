nasm loader.asm -o loader.bin
nasm kernel.asm -o kernel.bin
cat kernel.bin >> loader.bin
dd if=loader.bin of=loader.img bs=512 count=2 conv=notrunc
xxd loader.img > loader.hex
