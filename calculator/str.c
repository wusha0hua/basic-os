#include<stdio.h>

void GetStr(char *s)
{
	s[0]='a';
	s[1]='b';
	s[2]='c';
	s[3]='d';
	s[4]='e';
}

int main()
{
	char s[16];
	int a=0x1234;
	GetStr(s);
	int b=0x1234;

}
