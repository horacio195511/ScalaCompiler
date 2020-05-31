%{
#define Trace(t)        printf(t)
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct symtab{
	char *name;
	// changeable: 0 to be const, 1 to be variable
	char *type;
	struct symtab *next;
}symtab;

symtab* create();
void insert(symtab*, char*, char*);
// (head, name, type)
void dump(symtab*);
symtab* lookup(symtab*, char*);
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

%type <string> type

%left OR
%left AND
%left NOT
%left '<' '>' LESSEQUAL EQUAL LARGEEQUAL NOTEQUAL
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%start program

%%
program: 	OBJECT IDENTIFIER'{' 
			declaration
			'}'
			;

declaration: 
			constant_declaration		{Trace("reduce to constant declaration\n");}
		|	variable_declaration		{Trace("reduce to variable declaration\n");}
		|	array_declaration			{Trace("reduce to array declaration\n");}
		|	method_declaration			{Trace("reduce to method declaration\n");}
		|	declaration constant_declaration	{Trace("reduce to constant declaration\n");}
		|	declaration variable_declaration	{Trace("reduce to variable declaration\n");}
		|	declaration array_declaration		{Trace("reduce to array declaration\n");}
		|	declaration method_declaration		{Trace("reduce to method declaration\n");}
		;

constant_declaration:	
			VAL IDENTIFIER ':' FLOAT '=' REAL	{
												insert(head, $2, $4);
												}
		|	VAL IDENTIFIER ':' INT '=' NUMBER	{
												insert(head, $2, $4);
												}
		|	VAL IDENTIFIER ':' BOOLEAN '=' BOOL	{
												insert(head, $2, $4);
												}
		|	VAL IDENTIFIER ':' STRING '=' STRING_VAL	{
														insert(head, $2, $4);
														}
		|	no_type_constant_declaration
		;

no_type_constant_declaration:
			VAL IDENTIFIER '=' REAL			{
											insert(head, $2, "float");
											}
		|	VAL IDENTIFIER '=' NUMBER		{
											insert(head, $2, "int");
											}
		|	VAL IDENTIFIER '=' BOOL			{
											insert(head, $2, "bool");
											}
		|	VAL IDENTIFIER '=' STRING		{
											insert(head, $2, "string");
											}
		;

variable_declaration:	
			VAR IDENTIFIER ':' FLOAT '=' REAL	{
												insert(head, $2, $4);
												}
		|	VAR IDENTIFIER ':' INT '=' NUMBER	{
												insert(head, $2, $4);
												}
		|	VAR IDENTIFIER ':' BOOLEAN '=' BOOL	{
												insert(head, $2, $4);
												}
		|	VAR IDENTIFIER ':' STRING '=' STRING_VAL	{
														insert(head, $2, $4);
														}
		|	no_value_variable_declaration
		;

no_value_variable_declaration: 
			VAR IDENTIFIER ':' type	{
									insert(head, $2, $4);
									}
		;

array_declaration:	
			VAR IDENTIFIER ':' type '[' NUMBER ']'		{
														insert(head, $2, $4);
														}
		; 

method_declaration:
				DEF IDENTIFIER '(' formal_argument ')' method_block
														{
														insert(head, $2, "method");
														}
		|
				DEF IDENTIFIER '(' formal_argument ')' ':' type method_block
														{
														insert(head, $2, "method");
														}
		;

method_block:
				'{'
				zmvcd
				zms
				'}'
				;

zms:	zms statement | ;

type:	FLOAT
	| 	INT
	|	STRING
	|	BOOLEAN 	{$$=$1;};

formal_argument:
			IDENTIFIER ':' type
		|	formal_argument ',' IDENTIFIER ':' type
		;

statement:
		|	conditional_statement
		|	loop_statement
		;
		
simple_statement:
			IDENTIFIER '=' expression
		|	IDENTIFIER '=' procedure_invocation
		|	IDENTIFIER'['NUMBER']' '=' expression
		|	PRINT '(' expression ')'
		|	PRINTLN '(' expression ')'
		|	READ IDENTIFIER
		|	RETURN expression
		|	RETURN
		;

complex_statement:
			complex_statement simple_statement
		|	simple_statement
		;

block_statement:
			'{' zmvcd oms '}'
			;

zmvcd:	zmvcd variable_declaration | zmvcd constant_declaration |;
oms:	oms statement | complex_statement ;

conditional_statement:	
			matched_stmt
		|	unmatched_stmt
		;

matched_stmt:
			IF '('boolean_expression ')'
			matched_stmt
			ELSE
			matched_stmt
		|	sab_statment
		;

unmatched_stmt:
			IF '('boolean_expression ')'
			conditional_statement
		|	IF '('boolean_expression ')'
			matched_stmt
			ELSE
			unmatched_stmt
		;

sab_statment:
			simple_statement
		|	block_statement
		;

loop_statement:	
			WHILE '(' boolean_expression ')'
			sab_statment
		|	FOR '(' IDENTIFIER '<''-' NUMBER TO NUMBER ')'
			sab_statment
		;

procedure_invocation:
			IDENTIFIER '(' parameter_expression ')'
		;

parameter_expression:
			parameter_expression ',' expression
		|	expression
		;

value: NUMBER | REAL | IDENTIFIER;

bool: TRUE | FALSE | IDENTIFIER;

expression:
		|	value '+' value
		|	value '-' value
		|	value '*' value
		|	value '/' value
		|	'-' value
		|	boolean_expression
		;

boolean_expression:	
			value '<' value
		|	value LESSEQUAL value
		|	value LARGEEQUAL value
		|	value '>' value
		|	value EQUAL value
		|	value NOTEQUAL value
		|	bool AND bool
		|	bool OR bool
		|	'!' bool
		;
%%

void yyerror(char *msg)
{
    fprintf(stderr, "%s @line: %d\n", msg, linenum);
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
	else dump(head);
}

symtab* create(){
	symtab *head = (symtab*)malloc(sizeof(symtab));
	head->next = NULL;
	return head;
}

// generic insert function based on void pointer
void insert(symtab *head, char *name, char *type){
	/* Insert in the end of linked list*/
	symtab *current = head;
	// go to the last element
	while(current->next != NULL){
		current = current->next;
	}
	// insert
	symtab *new = (symtab*)malloc(sizeof(symtab));
	char *nname = (char*)malloc(sizeof(char)*strlen(name));
	char *ntype = (char*)malloc(sizeof(char)*strlen(type));
	strcpy(nname, name);
	strcpy(ntype, type);
	current->name = nname;
	current->type = ntype;
	new->next = NULL;
	current->next = new;
}

// print the value of each node, with different type of value.
void dump(symtab *head){
	// using nested printf to solve the type recognision problem
	// currently only support int, float, char, string type
	symtab *current = head;
	while(current->next !=  NULL){
		printf("%s : %s\n", current->name, current->type);
		current = current->next;
	}
}

// return the address of searching id, or 0 if not found
symtab* lookup(symtab *head, char *id){
	symtab *current = head;
	while(current->next != NULL){
		current = current->next;
		if(strcmp(current->name, id) == 0){
			return current;
		}
	}
	return NULL;
}
