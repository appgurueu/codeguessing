#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#define mapass(v,f,...) v=f(v,##__VA_ARGS__)
enum C {Z,O,E};
const char L=-1,R=1;
typedef struct {char m;enum C w;int n;} T;
const T sts[7][3]={{
	{L,E,1},
	{L,E,1},
	{L,E,5},
},{
	{L,O,4},
	{L,Z,1},
	{R,E,2},
},{
	{R,O,3},
	{R,O,2},
	{R,O,0},
},{
	{R,Z,3},
	{R,Z,2},
	{R,Z,0},
},{
	{L,Z,4},
	{L,O,4},
	{R,E,6},
},{
	{L,Z,5},
	{L,O,5},
	{R,E,-1},
},{
	{R,E,2},
	{R,E,2},
	{R,E,2},
}};
char *dostuff(char *t)
{
	int s=0;
	++t;
	do {
		T tr=sts[s][*t];
		*t=tr.w; t+=tr.m; s=tr.n;
	} while (s!=-1);
	return t;
}
main()
{
	char c,*t=malloc(1);
	t[0]=E;
	int nt=1,ct=1;
	while (EOF!=(c=getchar())) {
		if (nt==ct) assert(mapass(t,realloc,ct<<=1));
		t[nt++]=Z;
	}
	if (nt+2>ct) assert(mapass(t,realloc,ct+2));
	t[nt++]=E;
	t[nt++]=E;
	assert(feof(stdin));
	mapass(t,dostuff);
	for(char *e=t+nt;t!=e&&*t!=E;++t)
		assert(EOF!=putchar('0'+*t));
}
