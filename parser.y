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

// symbol table structure to store symbol in each scope
typedef struct symtab{
	char *name;
	char *type;
	struct symtab *parameterList;
	struct symtab *next;
}symtab;

// really basic linken list sturcture, mostly for type checking
typedef struct listnode{
	char *val;
	struct listnode *next;
}listnode;

// function for symtabIndex
symtabIndex* symtabIndexCreate();
void symtabIndexInsert(symtabIndex*, symtab*, char*);
symtabIndex* symtabIndexLookup(symtabIndex*, char*);
void symtabIndexDump(symtabIndex*);

// function for symtab
symtab* symtabCreate(char*, symtabIndex*);
void symtabInsert(symtab*, char*, char*, listnode*);
symtab* symtabLookup(symtab*, char*);
void symtabDump(symtab*);

// function for linked list
listnode* listnodeCreate();
void listnodeInsert(listnode*, char*);
listnode* listnodeLookup(listnode*, char*);
void listnodeDump(listnode*);

// other function
void yyerror(char*);
extern int yylex(void);
extern int linenum;
// head is point to the symbol table of current scope
symtabIndex *symtabIndexHead;
symtab *symtabHead;
listnode *listnodeHead;
%}

/* data type definition */
%union {
	float fval;
	int ival;
	bool bval;
	char *string;
	struct listnode *listnode;
}

/* tokens */
%token  BREAK CLASS CONTINUE DEF DO ELSE EXIT FOR IF TNULL WHILE OBJECT PRINT PRINTLN REPEAT RETURN TO READ
%token  VAL VAR
%token	LESSEQUAL LARGEEQUAL EQUAL NOTEQUAL AND OR

/* typed token */
%token <fval> REAL
%token <ival> NUMBER
%token <string> INT STRING BOOLEAN FLOAT BOOL CHAR IDENTIFIER STRING_VAL TRUE FALSE

%type <string> type value num_expression procedure_invocation
%type <listnode> parameter_expression formal_argument

%left OR
%left AND
%left '!'
%left '<' '>' LESSEQUAL EQUAL LARGEEQUAL NOTEQUAL
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%start program

%%
program: 	OBJECT IDENTIFIER'{' declaration '}'	{symtabHead = symtabCreate(symtabHead, $2); Trace("reduce to program\n");};

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
			VAL IDENTIFIER ':' FLOAT '=' REAL			{symtabInsert(symtabHead, $2, $4, NULL);}
		|	VAL IDENTIFIER ':' INT '=' NUMBER			{symtabInsert(symtabHead, $2, $4, NULL);}
		|	VAL IDENTIFIER ':' BOOLEAN '=' BOOL			{symtabInsert(symtabHead, $2, $4, NULL);}
		|	VAL IDENTIFIER ':' STRING '=' STRING_VAL	{symtabInsert(symtabHead, $2, $4, NULL);}
		|	VAL IDENTIFIER ':' CHAR '=' STRING_VAL		{symtabInsert(symtabHead, $2, $4, NULL);}
		|	no_type_constant_declaration
		;

no_type_constant_declaration:
			VAL IDENTIFIER '=' REAL			{symtabInsert(symtabHead, $2, "float", NULL);}
		|	VAL IDENTIFIER '=' NUMBER		{symtabInsert(symtabHead, $2, "int", NULL);}
		|	VAL IDENTIFIER '=' BOOL			{symtabInsert(symtabHead, $2, "bool", NULL);}
		|	VAL IDENTIFIER '=' STRING		{symtabInsert(symtabHead, $2, "string", NULL);}
		;

variable_declaration:	
			VAR IDENTIFIER ':' FLOAT '=' REAL			{symtabInsert(symtabHead, $2, $4, NULL);}
		|	VAR IDENTIFIER ':' INT '=' NUMBER			{symtabInsert(symtabHead, $2, $4, NULL);}
		|	VAR IDENTIFIER ':' BOOLEAN '=' BOOL			{symtabInsert(symtabHead, $2, $4, NULL);}
		|	VAR IDENTIFIER ':' STRING '=' STRING_VAL	{symtabInsert(symtabHead, $2, $4, NULL);}
		|	VAR IDENTIFIER ':' CHAR '=' STRING_VAL		{symtabInsert(symtabHead, $2, $4, NULL);}
		|	no_value_variable_declaration
		;

no_value_variable_declaration:	
			VAR IDENTIFIER ':' type		{symtabInsert(symtabHead, $2, $4, NULL);}
		;

array_declaration:	
			VAR IDENTIFIER ':' type '[' NUMBER ']'		{symtabInsert(symtabHead, $2, $4, NULL);}
		; 

method_declaration:
			DEF IDENTIFIER '(' formal_argument ')' method_block				{symtabInsert(symtabHead, $2, "NULL", $4); listnodeHead = listnodeCreate();}
		|	DEF IDENTIFIER '(' formal_argument ')' ':' type method_block	{symtabInsert(symtabHead, $2, $7, $4); listnodeHead = listnodeCreate();}
		;

method_block:	'{'zmvcd zms'}';

type:	FLOAT
	| 	INT
	|	STRING
	|	CHAR
	|	BOOLEAN 	{$$=$1;}
	;

formal_argument:
		{$$=NULL;}
		|	IDENTIFIER ':' type							{listnodeInsert(listnodeHead, $3); $$=listnodeHead;}
		|	formal_argument ',' IDENTIFIER ':' type		{listnodeInsert(listnodeHead, $5);}
		;

statement:
			conditional_statement | loop_statement
		;
		
simple_statement:
			IDENTIFIER '=' num_expression					{symtab *symbol = symtabLookup(symtabHead, $1); if(strcmp(symbol->type, $3) != 0) printf("!!!type mismatch!!!\n");}
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
							symtab *target = symtabLookup(symtabHead, $1);
							$$ = target->type;
						};

parameter_expression:
						parameter_expression ',' value 		{listnodeInsert(listnodeHead, $3);}
					|	value 								{listnodeInsert(listnodeHead, $1); $$ = listnodeHead;}
					| 	{$$=NULL;}
					;

value: 
		NUMBER 					{$$="int";}
	| 	REAL 					{$$="float";}
	|	STRING_VAL 				{$$="string";}
	|	IDENTIFIER 				{symtab *symbol=symtabLookup(symtabIndexHead, $1); $$=symbol->type;};
	|	procedure_invocation	{$$=$1;}
	;

bool: TRUE | FALSE | IDENTIFIER | procedure_invocation;

boolorval: NUMBER | REAL | STRING | TRUE | FALSE | IDENTIFIER;

num_expression:
			num_expression '+' num_expression	{if(strcmp($1, $3) != 0)printf("!!!expression type mismatch!!!"); else $$=$1;}
		|	num_expression '-' num_expression	{if(strcmp($1, $3) != 0)printf("!!!expression type mismatch!!!"); else $$=$1;}
		|	num_expression '*' num_expression	{if(strcmp($1, $3) != 0)printf("!!!expression type mismatch!!!"); else $$=$1;}
		|	num_expression '/' num_expression	{if(strcmp($1, $3) != 0)printf("!!!expression type mismatch!!!"); else $$=$1;}
		|	'-' num_expression %prec UMINUS		{$$ = $2;}
		|	value	{$$ = $1;}
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
	// symtab index initialized here
    yyin = fopen(argv[1], "r");         /* open input file */
	symtabIndexHead = symtabIndexCreate();
    /* perform parsing */
    if (yyparse() == 1){
		yyerror("Parsing error !");     /* syntax error */
	}
	else{
		// check if there is any main mehtod
		symtabIndexDump(symtabIndexHead);
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
	if(symtabIndexLookup(head, name) == NULL){
		symtab *current = head;
		while(current->next != NULL){
			current = current->next;
		}
		symtabIndex *new = (symtabIndex*)malloc(sizeof(symtabIndex));
		char *nname = (char*)malloc(sizeof(char)*strlen(name));
		strcpy(nname, name);
		new->name = nname;
		new->table = table;
		new->next = NULL;
		current->next = new;
	}else{
		printf("!!!This symbol table name is redifined!!!\n");
	}
}

// return the address of searching id, or 0 if not found
symtabIndex* symtabIndexLookup(symtabIndex *head, char *name){
	symtabIndex *current = head;
	while(current->next != NULL){
		if(strcmp(current->name, name) == 0){
			return current;
		}
		current = current->next;
	}
	return NULL;
}

// print the value of each node, with different type of value.
void symtabIndexDump(symtabIndex *head){
	// using nested printf to solve the type recognision problem
	// currently only support int, float, char, string type
	symtabIndex *current = head;
	printf("Symbol Table List\n");
	while(current->next !=  NULL){
		printf("%s\n", current->name);
		current = current->next;
	}
}

symtab* symtabCreate(char *name, symtabIndex *symtabIndexHead){
	// this function shoudld be called when a new method is created or a new block is created.
	// how should we name the if statement? According to is line number?
	symtab *head = (symtab*)malloc(sizeof(symtab));
	char *nname = (char*)malloc(sizeof(char)*strlen(name));
	strcpy(nname, name);
	head->name = nname;
	head->next = NULL;
	// insert the symtab in to symtabIndex
	symtabIndexInsert(symtabIndexHead, head, name);
	return head;
}

void symtabInsert(symtab *head, char *name, char *type, listnode *parameterList){
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

listnode* listnodeCreate(){
	// this function should be called in the main function
	listnode *head = (listnode*)malloc(sizeof(listnode));
	head->next = NULL;
	return head;
}

void listnodeInsert(listnode *head, char *val){
	/* check if the name is in the symbol table */
	/* Insert in the end of linked list*/
	listnode *current = head;
	// go to the last element
	while(current->next != NULL){
		current = current->next;
	}
	// insert
	listnode *new = (listnode*)malloc(sizeof(listnode));
	char *nval = (char*)malloc(sizeof(char)*strlen(val));
	strcpy(nval, val);
	new->val = val;
	new->next = NULL;
	current->next = new;
}
listnode* listnodeLookup(listnode *head, char *val){
	listnode *current = head;
	while(current->next != NULL){
		if(strcmp(current->val, val) == 0){
			return current;
		}
		current = current->next;
	}
	return NULL;
}
void listnodeDump(listnode *head){
	// using nested printf to solve the type recognision problem
	// currently only support int, float, char, string type
	listnode *current = head;
	printf("list node\n");
	while(current->next !=  NULL){
		printf("%s\n", current->val);
		current = current->next;
	}
}
