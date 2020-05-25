%{
#define Trace(t)        printf(t)
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct symtab{
	char *name;
	// changeable: 0 to be const, 1 to be variable
	int changeable;
	char *type;
	void *value;
	struct symtab *next;
}symtab;

symtab* create();
void insert(symtab*, int, char*, char*, void*, size_t);
// (head, name, type, value, size of data)
void dump(symtab*);
void yyerror(char*);
extern int yylex(void);
// parameter used for error handling
extern int linenum;

symtab *head;
%}

/* data type definition */
%union {
	float fval;
	int ival;
	char *string;
	void *notype;
}

/* tokens */
%token  BREAK CLASS CONTINUE DEF DO ELSE EXIT FOR IF TNULL WHILE OBJECT PRINT PRINTLN REPEAT RETURN TO READ
%token  VAL VAR 
%token	LESSEQUAL LARGEEQUAL EQUAL NOTEQUAL AND OR

/* typed token */
%token <fval> REAL
%token <ival> NUMBER
%token <string> TRUE FALSE
%token <string> STRING_VAL 
%token <string> IDENTIFIER
%token <string> INT STRING BOOLEAN FLOAT BOOL
%token <notype> VALUE

%type <string> type

%left OR
%left AND
%left NOT
%left '<' '>' LESSEQUAL EQUAL LARGEEQUAL NOTEQUAL
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%left INT
%left FLOAT
%left STRING
%left BOOLEAN

%start program
%%
program : 		OBJECT IDENTIFIER'{' 
			declaration
			'}'
			;

declaration : 		constant_declaration
		|	variable_declaration
		|	array_declaration
		|	method_declaration	
		|	declaration constant_declaration	{Trace("reduce to constant declaration");}
		|	declaration variable_declaration	{Trace("reduce to variable declaration");}
		|	declaration array_declaration		{Trace("reduce to array declaration");}
		|	declaration method_declaration		{Trace("reduce to method declaration");}
		|
		;

constant_declaration :	VAL IDENTIFIER ':' FLOAT '=' REAL	{ float input = $6; 
								insert(head, 0, $2, $4, &input, sizeof(float)); }
		|	VAL IDENTIFIER ':' INT '=' NUMBER	{ int input = $6; 
								insert(head, 0, $2, $4, &input, sizeof(int)); }
		|	VAL IDENTIFIER ':' BOOLEAN '=' BOOL	{ char *input = $6; 
								insert(head, 0, $2, $4, &input, sizeof(char*)); }
		|	VAL IDENTIFIER ':' STRING '=' STRING_VAL	{ char *input = $6; 
								insert(head, 0, $2, $4, &input, sizeof(char*)); }
		|	VAL IDENTIFIER VALUE			{ void *input = $3; insert(head, 0, $2, "undefined", input, sizeof(void*)); }
		;

variable_declaration :	VAL IDENTIFIER ':' FLOAT '=' REAL	{ float input = $6; 
								insert(head, 1, $2, $4, &input, sizeof(float)); }
		|	VAL IDENTIFIER ':' INT '=' NUMBER	{ int input = $6; 
								insert(head, 1, $2, $4, &input, sizeof(int)); }
		|	VAL IDENTIFIER ':' BOOLEAN '=' BOOL	{ char *input = $6; 
								insert(head, 1, $2, $4, &input, sizeof(char*)); }
		|	VAL IDENTIFIER ':' STRING '=' STRING_VAL	{ char *input = $6; 
								insert(head, 0, $2, $4, &input, sizeof(char*)); }
		;

array_declaration :	VAR IDENTIFIER ':' FLOAT '[' NUMBER ']'		{}
		|	VAR IDENTIFIER ':' INT	 '[' NUMBER ']'		{}
		|	VAR IDENTIFIER ':' STRING '[' NUMBER ']'	{}
		; 

method_declaration :		DEF IDENTIFIER '(' formal_argument ')' ':' type
				'{'
				declaration
				statement
				'}'
		;

type :	INT | STRING | BOOLEAN ;

formal_argument :	IDENTIFIER ':' type	
		|	formal_argument IDENTIFIER ':' type 
		| 
		;

statement :		sab_statement 
		|	conditional_statement 
		|	loop_statement
		|	statement sab_statement 
		|	statement conditional_statement 
		|	statement loop_statement
		;

sab_statement:		simple_statement 
		|	block_statement 
		;
		
simple_statement :	IDENTIFIER '=' expression
		|	IDENTIFIER'['NUMBER']' '=' expression
		|	PRINT '(' expression ')'
		|	PRINTLN '(' expression ')'
		|	READ IDENTIFIER
		|	RETURN ra
		;

ra : 			expression 
		|
		;

block_statement :	'{'
			declaration
			statement
			'}'
			;

conditional_statement :	IF '(' boolean_expression ')'
			sab_statement
			ELSE
			sab_statement
		|	IF '(' boolean_expression ')'
			sab_statement
		;

loop_statement :	WHILE '(' boolean_expression ')'
			sab_statement
		|	FOR '(' IDENTIFIER '<''-' NUMBER TO NUMBER ')'
			sab_statement
		;

expression :		expression '+' expression
		|	expression '-' expression
		|	expression '*' expression
		|	expression '/' expression
		|	'-' expression
		|	boolean_expression
		|	VALUE
		|	IDENTIFIER
		;

boolean_expression :	expression '<' expression
		|	expression LESSEQUAL expression
		|	expression LARGEEQUAL expression
		|	expression '>' expression
		|	expression EQUAL expression
		|	expression NOTEQUAL expression
		|	expression AND expression
		|	expression OR expression
		|	'!' expression 
		|	TRUE | FALSE
		|	IDENTIFIER
		;

stat : 		error '\n'
		{
			yyerrork;
			printf("Reenter last line: %d ", linenum);
		}
		;
%%
void yyerror(char *msg)
{
    fprintf(stderr, "%s\n", msg);
}

void main(int argc, char *argv[])
{
    extern FILE *yyin;
    /* open the source program file */
    if (argc != 2) {
	printf ("Usage: sc filename\n");
	exit(1);
    }
    head = create();
    yyin = fopen(argv[1], "r");         /* open input file */

    /* perform parsing */
    if (yyparse() == 1)                 /* parsing */
	yyerror("Parsing error !");     /* syntax error */
}

symtab* create(){
	symtab *head = (symtab*)malloc(sizeof(symtab));
	head->next = NULL;
	return head;
}

// generic insert function based on void pointer
void insert(symtab *head, int changeable, char *name, char *type, void *item , size_t data_size){
	/* Insert in the end of linked list*/
	symtab *current = head;
	// go to the last element
	while(current->next != NULL){
		current = current->next;
	}
	// insert
	symtab *new = (symtab*)malloc(sizeof(symtab)); 
	new->name = name;
	new->changeable = changeable;
	new->type = type;
	new->value = malloc(data_size);
	new->next = NULL;
	// copy the item data into linked list
	int i=0;
	for(i=0; i<data_size; i++)
		*(char *)(new->value + i) = *(char *)(item+i);
	current->next = new;
}

// print the value of each node, with different type of value.
void dump(symtab *head){
	// using nested printf to solve the type recognision problem
	symtab *current = head;
	while(current->next !=  NULL){
		current = current->next;
		if(strcmp(current->type, "int") == 0) 
			printf("%s = %d\n", current->name, *(int*)current->value);
		else if(strcmp(current->type, "float") == 0) 
			printf("%s = %f\n", current->name, *(float*)current->value);
		else if(strcmp(current->type, "char") == 0) 
			printf("%s = %c\n", current->name, *(char*)current->value);
		else{ printf("error\n"); }
	}
}
