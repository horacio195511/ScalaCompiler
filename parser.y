%{
#define Trace(t)        printf(t)
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

// user defined structure usesd to store the index for each symbol table
typedef struct symtabIndex{
	char *name;
	struct symtab *table;
	struct symtabIndex *next;
}symtabIndex;

typedef struct symtab{
	// the name of head is the name of symbol table
	char *name;
	// changeable: 0 to be const, 1 to be variable
	char *type;
	// for parameter type checking in method, null if the variable is not a method or a method
	// with parameter
	struct symtab *parameterList;
	struct symtab *next;
}symtab;

// function for symtabIndes
symtabIndex* symtabIndexCreate();
void symtabIndexInsert(symtabIndex*, symtab*, char*);
symtabIndex* symtabIndexLookup(symtabIndex*, char*);
void symtabIndexDump(symtabIndex*);

// function for symtab
symtab* symtabCreate();
void symtabInsert(symtab*, char*, char*);
symtab* symtabLookup(symtab*, char*);
void symtabDump(symtab*);

// other function
void yyerror(char*);
extern int yylex(void);
extern int linenum;
// head is point to the symbol table of current scope
symtab *head;
%}

/* data type definition */
%union {
	float fval;
	int ival;
	bool bval;
	char *string;
}

/* tokens */
%token  BREAK CLASS CONTINUE DEF DO ELSE EXIT FOR IF TNULL WHILE OBJECT PRINT PRINTLN REPEAT RETURN TO READ
%token  VAL VAR
%token	LESSEQUAL LARGEEQUAL EQUAL NOTEQUAL AND OR

/* typed token */
%token <fval> REAL
%token <ival> NUMBER
%token <string> INT STRING BOOLEAN FLOAT BOOL CHAR IDENTIFIER STRING_VAL TRUE FALSE

%type <string> type

%left OR
%left AND
%left '!'
%left '<' '>' LESSEQUAL EQUAL LARGEEQUAL NOTEQUAL
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%start program

%%
program: 	OBJECT IDENTIFIER'{' declaration '}'	{Trace("reduce to program\n");};

declaration:
			constant_declaration				{Trace("reduce to constant declaration\n");}
		|	variable_declaration				{Trace("reduce to variable declaration\n");}
		|	array_declaration					{Trace("reduce to array declaration\n");}
		|	method_declaration					{Trace("reduce to method declaration\n");}
		|	declaration constant_declaration	{Trace("reduce to constant declaration\n");}
		|	declaration variable_declaration	{Trace("reduce to variable declaration\n");}
		|	declaration array_declaration		{Trace("reduce to array declaration\n");}
		|	declaration method_declaration		{Trace("reduce to method declaration\n");}
		;

constant_declaration:
			VAL IDENTIFIER ':' FLOAT '=' REAL			{insert(head, $2, $4);}
		|	VAL IDENTIFIER ':' INT '=' NUMBER			{insert(head, $2, $4);}
		|	VAL IDENTIFIER ':' BOOLEAN '=' BOOL			{insert(head, $2, $4);}
		|	VAL IDENTIFIER ':' STRING '=' STRING_VAL	{insert(head, $2, $4);}
		|	VAL IDENTIFIER ':' CHAR '=' STRING_VAL		{insert(head, $2, $4);}
		|	no_type_constant_declaration
		;

no_type_constant_declaration:
			VAL IDENTIFIER '=' REAL			{insert(head, $2, "float");}
		|	VAL IDENTIFIER '=' NUMBER		{insert(head, $2, "int");}
		|	VAL IDENTIFIER '=' BOOL			{insert(head, $2, "bool");}
		|	VAL IDENTIFIER '=' STRING		{insert(head, $2, "string");}
		;

variable_declaration:	
			VAR IDENTIFIER ':' FLOAT '=' REAL			{insert(head, $2, $4);}
		|	VAR IDENTIFIER ':' INT '=' NUMBER			{insert(head, $2, $4);}
		|	VAR IDENTIFIER ':' BOOLEAN '=' BOOL			{insert(head, $2, $4);}
		|	VAR IDENTIFIER ':' STRING '=' STRING_VAL	{insert(head, $2, $4);}
		|	VAR IDENTIFIER ':' CHAR '=' STRING_VAL		{insert(head, $2, $4);}
		|	no_value_variable_declaration
		;

no_value_variable_declaration:	
			VAR IDENTIFIER ':' type		{insert(head, $2, $4);}
		;

array_declaration:	
			VAR IDENTIFIER ':' type '[' NUMBER ']'		{insert(head, $2, $4);}
		; 

method_declaration:
			DEF IDENTIFIER '(' formal_argument ')' method_block				{insert(head, $2, "method");}
		|	DEF IDENTIFIER '(' formal_argument ')' ':' type method_block	{insert(head, $2, "method");}
		;

method_block:	'{'zmvcd zms'}';

type:	FLOAT
	| 	INT
	|	STRING
	|	CHAR
	|	BOOLEAN 	{$$=$1;}
	;

formal_argument:
		|	IDENTIFIER ':' type
		|	formal_argument ',' IDENTIFIER ':' type
		;

statement:
			conditional_statement | loop_statement
		;
		
simple_statement:
			IDENTIFIER '=' num_expression
		|	IDENTIFIER '[' NUMBER ']' '=' num_expression
		|	PRINT '(' num_expression ')'
		|	PRINTLN '(' num_expression ')'
		|	READ IDENTIFIER
		|	RETURN
		|	RETURN num_expression
		|	error '\n'	{yyerror("statement error");}
		;

zmvcd:	zmvcd variable_declaration | zmvcd constant_declaration | ;

zms:	zms statement | zms simple_statement | ;

oms:	oms statement | oms simple_statement | statement | simple_statement ;

conditional_statement:
			IF '(' boolean_expression ')' sab_statment
		|	IF '(' boolean_expression ')' sab_statment ELSE sab_statment	{Trace("Reduce to conditional statement\n");}
		;

block_statement:	'{' zmvcd oms '}';

sab_statment:	simple_statement | block_statement;

loop_statement:	
			WHILE '(' boolean_expression ')'sab_statment
		|	FOR '(' IDENTIFIER '<''-' NUMBER TO NUMBER ')'sab_statment	{Trace("reduce to loop statement");}
		;

procedure_invocation:	IDENTIFIER '(' parameter_expression ')'	
						{
							//recognize if the identifier's type is of method
							symtab *target = lookup(head, $1);
							if(strcmp(target->type, "method") != 0){
								yyerror("invocation of non mehtod identifier");
							}
						};

parameter_expression:	parameter_expression ',' value | value | ;

value: NUMBER | REAL | STRING_VAL | IDENTIFIER | procedure_invocation;

bool: TRUE | FALSE | IDENTIFIER | procedure_invocation;

boolorval: NUMBER | REAL | STRING | TRUE | FALSE | IDENTIFIER;

num_expression:
			num_expression '+' num_expression
		|	num_expression '-' num_expression
		|	num_expression '*' num_expression
		|	num_expression '/' num_expression
		|	'-' num_expression %prec UMINUS
		|	value
		;

boolean_expression:	
			num_expression '<' num_expression
		|	num_expression LESSEQUAL num_expression
		|	num_expression LARGEEQUAL num_expression
		|	num_expression '>' num_expression
		|	boolorval EQUAL boolorval
		|	boolorval NOTEQUAL boolorval
		|	boolean_expression AND boolean_expression
		|	boolean_expression OR boolean_expression
		|	'!' boolean_expression
		|	bool
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
    if (yyparse() == 1){
		yyerror("Parsing error !");     /* syntax error */
	}
	else{
		// check if there is any main mehtod
		if(lookup(head, "main") == NULL){ printf("There is no main function!!");}
		dump(head);
	}
}

symtabIndex* symtabIndexCreate(){
	// this function should be called in the main function
	symtabIndex *head = (symtabIndex*)malloc(sizeof(symtabIndex));
	head->next = NULL;
	return head;
}

void symtabIndexInsert(symtabIndex *head, symtab *table, char *name){
	/* check if the name is in the symbol table */
	if(symtabIndexlookup(head, name) == NULL){
	/* Insert in the end of linked list*/
		symtab *current = head;
		// go to the last element
		while(current->next != NULL){
			current = current->next;
		}
		// insert
		symtabIndex *new = (symtabIndex*)malloc(sizeof(symtabIndex));
		char *nname = (char*)malloc(sizeof(char)*strlen(name));
		strcpy(nname, name);
		new->name = nname;
		new->next = NULL;
		current->next = new;
	}else{
		printf("!!!This symbol table name is redifined!!!\n");
	}
}

// return the address of searching id, or 0 if not found
symtabIndex* symtabLookup(symtabIndex *head, char *name){
	symtabIndex *current = head;
	while(current->next != NULL){
		if(strcmp(current->name, name) == 0){
			return current;
		}
		current = current->next;
	}
	return NULL;
}

symtab* symtabCreate(char *name){
	// this function shoudld be called when a new method is created or a new block is created.
	// how should we name the if statement? According to is line number?
	symtab *head = (symtab*)malloc(sizeof(symtab));
	char *nname = (char*)malloc(sizeof(char)*strlen(name));
	strcpy(nname, name);
	head->name = nname;
	head->next = NULL;
	// insert the symtab in to symtabIndex

	return head;
}

void symtabInsert(symtab *head, char *name, char *type, symtabIndex *parameterList){
	/* check if the name is in the symbol table */
	if(symtabLookup(head, name) == NULL){
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
		new->name = nname;
		new->type = ntype;
		new->parameterList = parameterList;
		new->next = NULL;
		current->next = new;
	}else{
		printf("!!!This symbol name is redifined!!!\n");
	}
}

// return the address of searching id, or 0 if not found
symtab* symtabLookup(symtab *head, char *id){
	symtab *current = head;
	while(current->next != NULL){
		if(strcmp(current->name, id) == 0){
			return current;
		}
		current = current->next;
	}
	return NULL;
}

// print the value of each node, with different type of value.
void symtabDump(symtab *head){
	// using nested printf to solve the type recognision problem
	// currently only support int, float, char, string type
	symtab *current = head;
	printf("Symbol Table\n");
	while(current->next !=  NULL){
		printf("%s : %s\n", current->name, current->type);
		current = current->next;
	}
}
