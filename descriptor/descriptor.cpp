#include<stdio.h>
#include<stdlib.h>
#include<string.h>

typedef struct
{
	unsigned short Limit16;
	unsigned short Base16;
	unsigned char BaseLow;
	unsigned char Attr;
	unsigned char AttrLimit;
	unsigned char BaseHigh;
}Descriptor;

void FillDescriptor(Descriptor *des,unsigned int base,unsigned int attrlimit )
{
	memset(des,0,sizeof(Descriptor));
	des->Limit16=attrlimit & 0xffff;
	des->Base16=base & 0xffff;
	des->BaseLow=(base>>16) & 0xff;
	des->BaseHigh=(base>>24) & 0xff;
	des->Attr=(attrlimit>>20) & 0xff;
	des->AttrLimit=((attrlimit>>24) & 0xf0)|((attrlimit>>24) & 0x0f);
}

void PrintDescriptor(Descriptor *des)
{
	unsigned char *p=(unsigned char*)(void*)des;
	for(int i=0;i<8;i++)
	{
		for(int j=7;j>=0;j--)
		{
			printf("%d ",(p[i]>>j)&1);
		}
	}
	puts("");

	unsigned int base,limit;
	bool G,D,AVL,P,DPL[2],S,TYPE[4];

	base=((unsigned int)des->BaseHigh & 0xff000000)|((unsigned int)des->BaseLow & 0x00ff0000)|((unsigned int)des->Base16 & 0x0000ffff);
	limit=(((unsigned int)des->AttrLimit & 0xff)<<16)|((unsigned int)des->Limit16 & 0xffff);
	G=(des->AttrLimit>>7)&1;
	D=(des->AttrLimit>>6)&1;
	AVL=(des->AttrLimit>>4)&1;
	P=(des->Attr>>7)&1;
	DPL[1]=(des->Attr>>6)&1;
	DPL[0]=(des->Attr>>5)&1;
	S=(des->Attr>>4)&1;
	TYPE[3]=(des->Attr>>3)&1;
	TYPE[2]=(des->Attr>>2)&1;
	TYPE[1]=(des->Attr>>1)&1;
	TYPE[0]=(des->Attr)&1;

	printf("base:%08x\n",base);
	printf("limit:%05x\n",limit);
	printf("G:%d\n",G);
	printf("D:%d\n",D);
	printf("AVL:%d\n",AVL);
	printf("DPL:");
	for(int i=1;i>=0;i--)
	{
		printf("%d",DPL[i]);
	}
	printf("\nP:%d\n",P);
	printf("DPL:");
	for(int i=3;i>=0;i--)
	{
		printf("%d",DPL[i]);
	}
	printf("\nS:%d\n",S);
	printf("TYPE:");
	for(int i=3;i>=0;i--)
	{
		printf("%d",TYPE[i]);
	}
	printf("\n");
}

unsigned short GetAttr(bool G,bool D,bool AVL,bool P,unsigned char DPL,bool S,unsigned char TYPE)
{
	unsigned short attr=0;
	attr=((unsigned int)G<<11)|((unsigned int )D<<10)|((unsigned int)AVL<<8)|((unsigned int )P<<7)|((unsigned int)(DPL&2)<<6)|((unsigned int)(DPL&1)<<5)|((unsigned int)S<<4)|((unsigned int)(TYPE&8)<<3)|((unsigned int)(TYPE&4)<<2)|(((unsigned int)(TYPE&2)<<1))|((unsigned int)(TYPE&1)&1);
	return attr;
}

int main()
{
	Descriptor *des;
	des=(Descriptor *)malloc(sizeof(Descriptor));
	unsigned int attr=GetAttr(1,1,0,1,0,1,8);
	unsigned int attrlimit=(unsigned int)attr<<20|(0xfffff & ((1<<20)-1));
	FillDescriptor(des,0x8000, attrlimit);
	PrintDescriptor(des);
	return 0;
}
