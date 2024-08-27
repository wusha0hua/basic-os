count=2880
bs=512

if [ $# -eq 1 ];
then
	count=$1
elif [ $# -eq 2 ];
then
	bs=$1
	count=$2
elif [ $# -eq 0 ];
then
	count=${count}
	bs=${bs}
else
	echo -e "\033[0mtoo many parameters\033[0m"
fi

filename=${0#*./}
filename=${filename%.sh*}

NasmLoaderCMD="nasm loader.asm -o loader.bin"
NasmKernelCMD="nasm kernel.asm -o kernel.bin"
CatLoaderCMD="cat loader.bin > ${filename}.bin"
CatKernelCMD="cat kernel.bin >> ${filename}.bin"
DDCMD="dd if=${filename}.bin of=${filename}.img bs=${bs} count=${count} conv=notrunc"
XXDCMD="xxd ${filename}.img > ${filename}.hex"



NasmOutput=`${NasmLoaderCMD} 2>&1` 
if [ -n "${NasmOutput}" ];
then
	echo -e "\033[33mCommand: ${NasmLoaderCMD}\033[0m"
	echo -e "\033[31mError: ${NasmOutput} \033[0m"
	exit
fi
NasmOutput=`${NasmKernelCMD} 2>&1`
if [ -n "${NasmOutput}" ]
then
	echo -e "\033[33mCommand: ${NasmKernelCMD}\033[0m"
	echo -e "\033[31mError: ${NasmOutput} \033[0m"
	rm loader.bin
	exit
fi

if [ ! -f "${filename}.img" ];
then
 	eval "bximage<<EOF
	1
	fd

	${filename}.img
EOF"
	
	if [ ! $? -eq 0 ];
	then
		echo -e "\033[33mCommand: bximge \033[0m"
		echo -e "\033[31mError: bximage can not create a floppy disk\033[0m"
		rm loader.bin kernel.bin
		exit
	fi
fi

BinOutput=`eval ${CatLoaderCMD} 2>&1`
if [ -n "${BinOutput}" ];
then
	echo -e "\033[33mCommand: ${CatLoaderCMD}\033[0m"
	echo -e "\033[31mError: ${BinOutput}\033[0m"
	rm loader.bin kernel.bin ${filename}.img
	exit
fi
BinOutput=`eval ${CatKernelCMD} 2>&1`
if [ -n "${BinOutput}" ];
then
	echo -e "\033[33mCommand: ${CatKernelCMD}\033[0m"
	echo -e "\033[31mError: ${BinOutput}\033[0m"
	rm loader.bin kernel.bin ${filename}.img ${filename}.bin
	exit
fi
DDOutput=`${DDCMD} 1>&/dev/null`
if [ ! $? -eq 0 ];
then
	echo -e "\033[33mCommand: ${DDCMD}\033[0m"
	echo -e "\033[31mError: ${DDOutput}\033[0m"
	rm loader.bin kernel.bin ${filename}.img ${filename}.bin
	exit
fi
XXDOutput=`eval ${XXDCMD} 2>&1`
if [ -n "${XXDOutput}" ];
then
	echo -e "\033[33mCommand: ${XXDCMD}\033[0m"
	echo -e "\033[31mError: ${XXDOutput}\033[0m"
	rm loader.bin kernel.bin ${filename}.img ${filename}.bin
	exit
fi

echo -e "\033[36mSucceed\033[0m"

