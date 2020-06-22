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
	bool changeable;
	int value;
	struct listnode *parameterList;
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
void symtabInsert(symtab*, char*, char*, bool, int, listnode*);
symtab* symtabLookup(symtab*, char*);
void symtabDump(symtab*);

// function for linked list
listnode* listnodeCreate();
void listnodeInsert(listnode*, char*);
listnode* listnodeLookup(listnode*, char*);
void listnodeDump(listnode*);
char* getParamList(listnode*);

// scope rule
symtab* scopeLookup(symtab*, symtab*, char*);
int listcmp(listnode*, listnode*);

// other function
void yyerror(char*);
extern int yylex(void);
extern int linenum;

// bytecode generation
char* loadSymbol(symtab*, symtab*, char*);
char* storeSymbol(symtab*, symtab*, char*, int);

// head is point to the symbol table of current scope
symtabIndex *symtabIndexHead;

// for global symtab
symtab *globalSymtab;

// for local symtab
symtab *localSymtab;
listnode *listnodeHead;

// string used to remember the last scope
char *lastScope;
FILE *outputFile;
int localRef;
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

%type <string> type type_exp procedure_invocation boolorval value num_expression
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
program: 	OBJECT IDENTIFIER 
			{
				globalSymtab = symtabCreate($2, symtabIndexHead);
				localSymtab=globalSymtab;
			} 
			'{'
			{
				fprintf(outputFile, "%s %s %s", "class", $2, "{\n");
			}
			declaration 
			'}'	
			{
				fprintf(outputFile, "}\n");
				Trace("reduce to program\n");
			};

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
			VAL IDENTIFIER ':' INT '=' NUMBER			{symtabInsert(localSymtab, $2, $4, false, $6, NULL);}
		|	VAL IDENTIFIER ':' FLOAT '=' REAL			{symtabInsert(localSymtab, $2, $4, false, 0, NULL);}
		|	VAL IDENTIFIER ':' BOOLEAN '=' BOOL			{symtabInsert(localSymtab, $2, $4, false, 0, NULL);}
		|	VAL IDENTIFIER ':' STRING '=' STRING_VAL	{symtabInsert(localSymtab, $2, $4, false, 0, NULL);}
		|	VAL IDENTIFIER ':' CHAR '=' STRING_VAL		{symtabInsert(localSymtab, $2, $4, false, 0, NULL);}
		|	no_type_constant_declaration
		;

no_type_constant_declaration:
			VAL IDENTIFIER '=' NUMBER		{symtabInsert(localSymtab, $2, "int", false, $4, NULL);}
		|	VAL IDENTIFIER '=' REAL			{symtabInsert(localSymtab, $2, "float", false, 0, NULL);}
		|	VAL IDENTIFIER '=' BOOL			{symtabInsert(localSymtab, $2, "bool", false, 0, NULL);}
		|	VAL IDENTIFIER '=' STRING		{symtabInsert(localSymtab, $2, "string", false, 0, NULL);}
		;

variable_declaration:	
			VAR IDENTIFIER ':' INT '=' NUMBER			{
															// the genereated program differed from what scope it's in
															if(localSymtab == globalSymtab){
																// global scope
																fprintf(outputFile, "%s %s %s", "field static int", $2, "\n");
															}else{
																// local scope
																fprintf(outputFile, "sipush %d\nistore %d\n", $6, localRef++);
															}
															symtabInsert(localSymtab, $2, $4, true, 0, NULL);
														}
		|	VAR IDENTIFIER ':' FLOAT '=' REAL			{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		|	VAR IDENTIFIER ':' BOOLEAN '=' BOOL			{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		|	VAR IDENTIFIER ':' STRING '=' STRING_VAL	{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		|	VAR IDENTIFIER ':' CHAR '=' STRING_VAL		{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		|	no_value_variable_declaration
		;

no_value_variable_declaration:	
			VAR IDENTIFIER ':' INT		{
											// the genereated program differed from what scope it's in
											if(localSymtab == globalSymtab){
												// global scope
												fprintf(outputFile, "%s %s %s", "field static int", $2, "\n");
											}else{
												// local scope
												fprintf(outputFile, "sipush %d\nistore %d\n", 0, localRef++);
											}
											symtabInsert(localSymtab, $2, $4, true, 0, NULL);
										}
		|	VAR IDENTIFIER ':' FLOAT	{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		|	VAR IDENTIFIER ':' BOOLEAN	{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		|	VAR IDENTIFIER ':' STRING	{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		|	VAR IDENTIFIER ':' CHAR		{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		;

array_declaration:	
			VAR IDENTIFIER ':' type '[' NUMBER ']'		{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		; 

method_declaration:
			DEF IDENTIFIER 
			{
				fprintf(outputFile, "mehtod public static void %s ", $2);
				fprintf(outputFile, "(java.lang.String[])\nmax_stack 15\nmax_locals 15\n{\n");
				localSymtab = symtabCreate($2, symtabIndexHead);
				listnodeHead = listnodeCreate();
				// set the reference number to the number of parameter
				localRef = 0;
			}
	 		'(' formal_argument ')' type_exp method_block 
			{
				fprintf(outputFile, "}\n");
				localSymtab = globalSymtab;
				symtabInsert(localSymtab, $2, $7, false, 0, $5);
			}
		;

formal_argument:
			formal_argument ',' IDENTIFIER ':' type		{
															fprintf(outputFile, "%s, ",$5);
															symtabInsert(localSymtab, $3, $5, true, 0, NULL);
															// type checking
															listnodeInsert(listnodeHead, $5);
															localRef++;
														}
		|	IDENTIFIER ':' type							{
															fprintf(outputFile, "%s ", $3);
															symtabInsert(localSymtab, $1, $3, true, 0, NULL);
															// type checking
															listnodeInsert(listnodeHead, $3);
															localRef++;
															$$=listnodeHead;
														}
		|	{$$=NULL;}
		;

type_exp:
			{$$="NULL";}
		|	':' type {$$=$2;}
		;

method_block:	'{'zmvcd zms'}';

type:	
		FLOAT
	| 	INT
	|	STRING
	|	CHAR
	|	BOOLEAN 	{$$=$1;}
	;

statement:
			conditional_statement | loop_statement
		;
		
simple_statement:
			IDENTIFIER '=' num_expression	{
												symtab *symbol = scopeLookup(globalSymtab, localSymtab, $1);
												// value assignment
												storeSymbol(globalSymtab, localSymtab, symbol->name, localRef);
											}
		|	IDENTIFIER '[' NUMBER ']' '=' num_expression
		|	PRINT 
			{
				fprintf(outputFile, "getstatic java.io.PrintStream java.lang.System.out\n");
			}		
			'(' num_expression ')'	
			{
				if(strcmp($4, "int") == 0){
					// type = string
					fprintf(outputFile, "invokevirtual void java.io.PrintStream.print(int)\n");
				}else{
					// type = int
					fprintf(outputFile, "invokevirtual void java.io.PrintStream.print(java.lang.String)\n");
				}
				
			}
		|	PRINTLN '(' num_expression ')'
			{
				if(strcmp($3, "int") == 0){
					// type = string
					fprintf(outputFile, "invokevirtual void java.io.PrintStream.print(int)\n");
				}else{
					// type = int
					fprintf(outputFile, "invokevirtual void java.io.PrintStream.print(java.lang.String)\n");
				}
				
			}
		|	READ IDENTIFIER
		|	RETURN					{fprintf(outputFile, "return\n");}
		|	RETURN num_expression	{fprintf(outputFile, "ireturn\n");}
		;

zmvcd:	zmvcd variable_declaration | zmvcd constant_declaration | ;

zms:	zms statement | zms simple_statement | ;

oms:	oms statement | oms simple_statement | statement | simple_statement ;

conditional_statement:
			IF '(' boolean_expression ')'
			{fprintf(outputFile, "Lfalse\n");}
			sab_statment
			{fprintf(outputFile, "Lfalse:\n");}
		|	IF '(' boolean_expression ')'
			{fprintf(outputFile, "Lfalse\n");}
			sab_statment 
			{fprintf(outputFile, "goto Lexit\n");}
			ELSE
			{fprintf(outputFile, "Lfalse:\n");}
			sab_statment
			{
				fprintf(outputFile, "Lexit:");
				Trace("Reduce to conditional statement\n");
			}
		;

block_statement:	'{' zmvcd oms '}';

sab_statment:	simple_statement | block_statement;

loop_statement:	
			WHILE 
			{
				fprintf(outputFile, "Lbegin:\n");
			}
			'(' boolean_expression ')'
			{
				fprintf(outputFile, "Lexit\n");
			}
			sab_statment
			{
				fprintf(outputFile, "goto Lbegin:\n");
				fprintf(outputFile, "Lexit:\n");
			}
		|	FOR '(' IDENTIFIER '<''-' NUMBER TO NUMBER ')'
			{
				char *name;
				// naming the symtab with line number
				sprintf(name, "for-%d", linenum);
				localSymtab = symtabCreate(name, symtabIndexHead);
				localRef=0;
				symtabInsert(localSymtab, $3, "int", true, localRef, NULL);
				symtab *symbol = scopeLookup(globalSymtab, localSymtab, $3);
				fprintf(outputFile, "Fbegin:\n");
				// increment or decrement the input ID
				if($6 > $8){
					// increment
					fprintf(outputFile, "iinc %d\n", symbol->value);
				}else if($8 < $6){
					// decrement
					fprintf(outputFile, "idec %d\n", symbol->value);
				}else{
					// opearate only once
				}
				// conditional satement
				fprintf(outputFile, "iload %d\n", symbol->value);
				fprintf(outputFile, "sipush %d\n", $8);
				fprintf(outputFile, "isub\n");
				fprintf(outputFile, "ifeq Fquit\n");
			}
			sab_statment
			{
				fprintf(outputFile, "goto Fbegin\n");
				fprintf(outputFile, "hello");
				Trace("reduce to loop statement");
			}
		;

procedure_invocation:	IDENTIFIER 
						{
							listnodeHead = listnodeCreate();
						}
						'(' parameter_expression ')'	
						{
							// recognize if the identifier's type is of method
							// some of the function should lookup in the program scope
							symtab *symbol = scopeLookup(globalSymtab, localSymtab, $1);
							if(symbol == NULL){
								yyerror("!!!couldn't resolve the symbol!!!\n");
							}
							printf("symbol name: %s\n", symbol->name);
							listnode *idParam = symbol->parameterList;
							listnode *inputParam = $4;
							if(listcmp(idParam, inputParam) != 0){yyerror("!!!Type mismatch!!!\n");}
							// code generation
							fprintf(outputFile, "getstatic int %s.%s(", globalSymtab->name, $1);
							fprintf(outputFile, "%s", getParamList(symbol->parameterList));
							fprintf(outputFile, ")\n");
							$$ = symbol->type;
						};

parameter_expression:
						parameter_expression ',' boolorval 		{
																// type checking
																listnodeInsert(listnodeHead, $3);
															}
					|	boolorval 								{
																// type checking
																listnodeInsert(listnodeHead, $1);
																$$ = listnodeHead;
															}
					| 	{$$=NULL;}
					;

value: 
		NUMBER 					{
									fprintf(outputFile, "sipush %d", $1);
									$$ = "int";
								}
	| 	REAL					{$$ = "float";}
	|	STRING_VAL				{
									fprintf(outputFile, "ldc %s", $1);
									$$ = "string";
								}
	|	IDENTIFIER 				{
									char *result = loadSymbol(globalSymtab, localSymtab, $1);
									fprintf(outputFile, "%s", result);
									symtab *symbol = scopeLookup(globalSymtab, localSymtab, $1);
									$$ = symbol->type;
								}
	|	procedure_invocation	{$$=$1;}
	;

bool: 
		TRUE 
	|	FALSE 
	|	IDENTIFIER 
	;

boolorval: 
		NUMBER		{$$="int";}
	|	REAL		{$$="float";}
	|	STRING		{$$="string";}
	|	TRUE		{$$="bool";}
	|	FALSE		{$$="bool";}
	|	IDENTIFIER	{
						symtab *symbol = scopeLookup(globalSymtab, localSymtab, $1);
						$$=symbol->type;
					}
	;

num_expression:
			num_expression '+' num_expression	{
													fprintf(outputFile, "iadd\n");
													// type checking
													if(strcmp($1, $3) != 0)printf("!!!expression type mismatch!!!");
													else $$=$1;
												}
		|	num_expression '-' num_expression	{
													fprintf(outputFile, "isub\n");
													// type checking
													if(strcmp($1, $3) != 0)printf("!!!expression type mismatch!!!");
													else $$=$1;
												}
		|	num_expression '*' num_expression	{
													fprintf(outputFile, "imul\n");
													// type checking
													if(strcmp($1, $3) != 0)printf("!!!expression type mismatch!!!");
													else $$=$1;
												}
		|	num_expression '/' num_expression	{
													fprintf(outputFile, "idiv\n");
													// type checking
													if(strcmp($1, $3) != 0)printf("!!!expression type mismatch!!!");
													else $$=$1;
												}
		|	'-' num_expression %prec UMINUS		{
													fprintf(outputFile, "ineg\n");
													// type checking
													$$ = $2;
												}
		|	value	{$$ = $1;}
		;

boolean_expression:	
			num_expression '<' num_expression			{
															fprintf(outputFile, "isub\n");
															fprintf(outputFile, "ifge");
														}
		|	num_expression LESSEQUAL num_expression		{
															fprintf(outputFile, "isub\n");
															fprintf(outputFile, "ifgt ");
														}
		|	num_expression LARGEEQUAL num_expression	{
															fprintf(outputFile, "isub\n");
															fprintf(outputFile, "iflt ");
														}
		|	num_expression '>' num_expression			{
															fprintf(outputFile, "isub\n");
															fprintf(outputFile, "ifle ");
														}
		|	num_expression EQUAL num_expression			{
															fprintf(outputFile, "isub\n");
															fprintf(outputFile, "ifne ");
														}
		|	num_expression NOTEQUAL num_expression		{
															fprintf(outputFile, "isub\n");
															fprintf(outputFile, "ifeq ");
														}
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
    outputFile = fopen("target.javac", "w");
    /* perform parsing */
    if (yyparse() == 1){
		yyerror("Parsing error !");     /* syntax error */
	}
	else{
		// check if there is any main mehtod
		fclose(outputFile);
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
		symtabIndex *current = head;
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
		yyerror("!!!This symbol table name is redifined!!!\n");
	}
}

// return the address of searching id, or 0 if not found
symtabIndex* symtabIndexLookup(symtabIndex *head, char *name){
	symtabIndex *current = head;
	while(current->next != NULL){
		current = current->next;
		if(strcmp(current->name, name) == 0){
			return current;
		}
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
		current = current->next;
		printf("%s\n", current->name);
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

void symtabInsert(symtab *head, char *name, char *type, bool changeable, int value, listnode *parameterList){
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
		new->changeable = changeable;
		new->value = value;
		new->parameterList = parameterList;
		new->next = NULL;
		current->next = new;
	}else{
		yyerror("!!!This symbol name is redifined!!!\n");
	}
}

// return the address of searching id, or 0 if not found
symtab* symtabLookup(symtab *head, char *id){
	symtab *current = head;
	while(current->next != NULL){
		current = current->next;
		if(strcmp(current->name, id) == 0){
			return current;
		}
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
	new->val = nval;
	new->next = NULL;
	current->next = new;
}

listnode* listnodeLookup(listnode *head, char *val){
	listnode *current = head;
	while(current->next != NULL){
		current = current->next;
		if(strcmp(current->val, val) == 0){
			return current;
		}
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

char* getParamList(listnode *head){
	listnode *current = head;
	char *output = "";
	while(current->next != NULL){
		current = current->next;
		sprintf(output, "%s,", current->val);
	}
	return output;
}

//scope rule: global and local, return symbol pointer if the symbol is valid
// return NULL if the symbol is invalid, accompany with an error message
symtab* scopeLookup(symtab *global, symtab *local, char *name){
	// search 
	// local lookup
	symtab *symbol;
	if((symbol = symtabLookup(local, name)) != NULL){
		return symbol;
	}else if((symbol = symtabLookup(global, name)) != NULL){
		return symbol;
	}else{
		yyerror("!!!Input id doesn't exist in local or global scope!!!");
		return NULL;
	}
}

// list cmp, return 0 if all elements are the same, other means not the same
// length are not the same: l1=null, l2!=null or vice versa
int listcmp(listnode *l1, listnode *l2){
	int result = 0;
	listnode *current1 = l1;
	listnode *current2 = l2;
	while(l1->next != NULL){
		// of the same length
		current1 = current1->next;
		current2 = current2->next;
		if(l1->next != NULL && l2->next != NULL){
			if(strcmp(l1->val, l2->val) != 0)result++;
		}else if(l1->next != NULL && l2->next == NULL){
			yyerror("!!!Length of Parameter aren't the same!!!\n");
			return ++result;
		}else if(l1->next == NULL && l2->next != NULL){
			yyerror("!!!Length of Parameter aren't the same!!!\n");
			return ++result;
		}else{
			if(strcmp(l1->val, l2->val) != 0)result++;
		}
	}
	return result;
}

char* storeSymbol(symtab *global, symtab *local, char *name, int ref){
	char *result;
	symtab *symbol;
	if((symbol = symtabLookup(local, name)) != NULL){
		// local
		if(symbol->changeable == true){
			// variable
			sprintf(result, "store %d\n", ref);
		}else if(symbol->changeable == false){
			// constant
			yyerror("!!!Trying to modify constant!!!\n");
		}
	}else if((symbol = symtabLookup(global, name)) != NULL){
		// global
		if(symbol->changeable == true){
			// variable
			sprintf(result, "putstatic int %s.%s", global->name, symbol->name);
		}else if(symbol->changeable == false){
			// constant
			yyerror("!!!Trying to modify constant!!!\n");
		}
	}else{
		yyerror("!!!Symbol Not Found!!!\n");
		result = NULL;
	}
	return result;
}

char* loadSymbol(symtab *global, symtab *local, char *name){
	// a symbol could be local or global, and variable or constant
	char *result;
	symtab *symbol;
	if((symbol = symtabLookup(local, name)) != NULL){
		// local
		// variable
		sprintf(result, "getstatic %s.%s", global->name, symbol->name);
		// constant: looking in symtab
		int val = symbol->value;
		sprintf(result, "sipush %d\n", val);
	}else if((symbol = symtabLookup(global, name)) != NULL){
		// global
		// variable
		sprintf(result, "getstatic %s.%s", global->name, symbol->name);
		// constant: looking in symtab, directly return the value
		int val = symbol->value;
		sprintf(result, "sipush %d\n", val);
	}else{
		yyerror("!!!Symbol Not Found!!!\n");
		result = "";
	}
	return result;
}
