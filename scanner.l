%{
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include "y.tab.h"

#define LIST			strcat(buf,yytext)
#define token(t)		{LIST; printf("<'%s'>\n",t);}
#define tokenKeyword(t)		{LIST; printf("<%s>\n",t);}
#define tokenInteger(t, i)	{LIST; printf("<%s:%d>\n",t,i);}
#define tokenFloat(t,f)		{LIST; printf("<%s:%f>\n",t,f);}
#define tokenString(t,s)	{LIST; printf("<%s:%s>\n",t,s);}

#define MAX_LINE_LENG 256

// to access pointer element in a struct, use -> operator
int preleng;

int linenum = 1;
char buf[MAX_LINE_LENG];
// SYMBOL TABLE definition
char* strupr(char*);
char* strdel(int, char*);
char* removeQuote(char*);
char* removeDoubleQuote(char*, int);
%}

identifier	[a-zA-Z][0-9a-zA-Z]*
number		[0-9]*
real		[+|-]?[0-9]+[\.[0-9]+]?
letter		[a-zA-Z0-9]
%x	COMMENT

%%
int		{tokenKeyword("INT"); yylval.string = "int"; return(INT);}
float		{tokenKeyword("FLOAT"); yylval.string = "float"; return(FLOAT);}
boolean		{tokenKeyword("BOOLEAN"); yylval.string = "boolean"; return(BOOLEAN);}
string		{tokenKeyword("STRING"); yylval.string = "string"; return(STRING);}
char		{tokenKeyword("CHAR"); yylval.string = "char"; return(CHAR);}
break		{tokenKeyword("BREAK"); return(BREAK);}
class		{tokenKeyword("CLASS"); return(CLASS);}
continue	{tokenKeyword("CONTINUE"); return(CONTINUE);}
def		{tokenKeyword("DEF"); return(DEF);}
do		{tokenKeyword("DO"); return(DO);}
else		{tokenKeyword("ELSE"); return(ELSE);}
exit		{tokenKeyword("EXIT"); return(EXIT);}
for		{tokenKeyword("FOR"); return(FOR);}
if		{tokenKeyword("IF"); return(IF);}
null		{tokenKeyword("NULL"); return(TNULL);}
while		{tokenKeyword("WHILE"); return(WHILE);}
object		{tokenKeyword("OBJECT"); return(OBJECT);}
print		{tokenKeyword("PRINT"); return(PRINT);}
println		{tokenKeyword("PRINTLN"); return(PRINTLN);}
repeat		{tokenKeyword("REPEAT"); return(REPEAT);}
return		{tokenKeyword("RETURN"); return(RETURN);}
to		{tokenKeyword("TO"); return(TO);}
read		{tokenKeyword("READ"); return(READ);}
true		{tokenKeyword("TRUE"); return(TRUE);}
false		{tokenKeyword("FALSE"); return(FALSE);}
val		{tokenKeyword("VAL"); return(VAL);}
var		{tokenKeyword("VAR"); return(VAR);}
\,		{token(","); return(',');}
\:		{token(":"); return(':');}
\.		{token("."); return('.');}
\;		{token(";"); return(';');}
\(		{token("("); return('(');}
\)		{token(")"); return(')');}
\[		{token("["); return('[');}
\]		{token("]"); return(']');}
\{		{token("{"); return('{');}
\}		{token("}"); return('}');}
\+		{token("+"); return('+');}
\-		{token("-"); return('-');}
\*		{token("*"); return('*');}
\/		{token("/"); return('/');}
=		{token("=") ;return('=');}
\<		{token("<"); return('<');}
\<=		{token("<="); return(LESSEQUAL);}
>		{token(">"); return('>');}
>=		{token(">="); return(LARGEEQUAL);}
==		{token("=="); return(EQUAL);}
!=		{token("!="); return(NOTEQUAL);}
&&		{token("&&"); return(AND);}
\|\|	{token("||"); return(OR);}
!		{token("!"); return('!');}
%		{token("%"); return('%');}

{number}	{tokenInteger("INT", atoi(yytext)); yylval.ival = atoi(yytext); return(NUMBER);}

{real}		{tokenFloat("FLOAT", atof(yytext)); yylval.fval = atof(yytext); return(REAL);}

{identifier}	{
		tokenString("id",yytext);
		char *id = (char*)malloc(sizeof(char)*strlen(yytext));
		strcpy(id, yytext);
		yylval.string = id; return(IDENTIFIER);
		}

\n	{ 
	LIST;
	printf("%d: %s", linenum++, buf);
	buf[0] = '\0';
	}

[ \t]*	{LIST;}

^\/\*	{
	LIST;
	BEGIN COMMENT;
	}

<COMMENT>{
\n	{
	LIST;
	printf("%d: %s", linenum++, buf);
	buf[0] = '\0';
	}

\*\/\n$	{
	LIST;
	printf("%d: %s", linenum++, buf);
	buf[0] = '\0';
	BEGIN(INITIAL);
	}

.	{LIST;}
}

\/\/.*\n	{
		// ignore all of the content
		LIST;
		printf("%d: %s", linenum++, buf);
		buf[0] = '\0';
		}

\"[^\"\n\t]*\"	{
		char c = input();
		unput(c);	/* just peeking */
		if(c != '\"'){
			// normal string
			char *out = removeDoubleQuote(yytext,yyleng);
			out = removeQuote(out);
			buf[yyleng] = '\0';
			yylval.string = out;
			return(STRING_VAL);
		}else{
			yymore();
		}
		}
.	{
	LIST;
	printf("%d:%s\n", linenum+1, buf);
	printf("bad character:'%s'\n", yytext);
	exit(-1);
	}
%%
// convert letter to upper case
char* strupr(char *str){
    // we dynamic allocate memory space for the output string
    int i=0;
    char *output=(char*)malloc(sizeof(char)*strlen(str));
    while(i < strlen(str)){
	if(str[i] >= 97){
	    output[i] = str[i]-32;
	}else{
	    output[i]=str[i];
	}
	i++;
    }
    return output;
}

// delete the i th letter from input string
char* strdel(int i, char *str){
	for(int j=i; j < strlen(str)-1; j++){
		str[j] = str[j+1];
	}
	return str;
}

// remove the second quote from the string
char* removeDoubleQuote(char *input, int len){
	// scan from right to left and mark the position of quote
	// use a linked list to store the position where quote need to be eliminated
	// here the yytext is all of the remaining string
	char index[10];
	// initailize index array to 0
	for(int i=0; i < 10; i++){
		index[i]=0;
	}
	// j to indicate whether the quote is first or second, only the first one should be store
	int j=1;
	// a is the index for index array
	int a=0;
	// detect the second quote, except first and second
	for(char i=1; i < (len-1); i++){
		if(input[i] == '\"'){
			j++;
			if(j%2){
			    index[a]=i;
			    a++;
			}
		}
	}
	int i=0;
	char *current = (char*)malloc(sizeof(char)*len);
	memcpy(current,input,len);
	while(index[i] != 0){
		// delete the letter from string
		current = strdel(index[i]-i,current);
		i++;
	}
	// delete the redundant characters
	current[len-i]='\0';
	return current;
}

char* removeQuote(char *str){
	char *out = (char*)malloc(sizeof(char)*(strlen(str)-2));
	for(int i=0; i<strlen(str)-2; i++){
		out[i] = str[i+1];
	}
	return out;
}
