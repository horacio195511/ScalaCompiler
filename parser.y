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
	// constant: value
	// variable: reference
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
listnode* listnodePop(listnode*);
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
int conRef;
int loopRef;
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

%type <string> type type_exp procedure_invocation value num_expression
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
			{
				fprintf(outputFile, "%s %s %s", "class", $2, "{\n");
			}
			'{'
			declaration
			{
				fprintf(outputFile, "}\n");
				Trace("reduce to program\n");
			}
			'}'
			;

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
			VAR IDENTIFIER ':' INT '=' NUMBER		{
															// the genereated program differed from what scope it's in
															if(localSymtab == globalSymtab){
																// global scope
																symtabInsert(localSymtab, $2, $4, true, 0, NULL);
																// fprintf(outputFile, "sipush %d\n", $6);
																fprintf(outputFile, "field static int %s\n", $2);
																// fprintf(outputFile, "pustatic int %s.%s", globalSymtab->name, $2);
															}else{
																// local scope
																symtabInsert(localSymtab, $2, $4, true, localRef, NULL);
																localRef++;
																symtab *symbol = symtabLookup(localSymtab, $2);
																fprintf(outputFile, "sipush %d\n", $6);
																fprintf(outputFile, "istore %d\n", symbol->value);
															}
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
												symtabInsert(localSymtab, $2, $4, true, 0, NULL);
												fprintf(outputFile, "field static int %s\n", $2);
											}else{
												// local scope
												symtabInsert(localSymtab, $2, $4, true, localRef, NULL);
												localRef++;
												symtab *symbol = symtabLookup(localSymtab, $2);
												fprintf(outputFile, "sipush %d\nistore %d\n", 0, symbol->value);
											}
										}
		|	VAR IDENTIFIER ':' FLOAT	{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		|	VAR IDENTIFIER ':' BOOLEAN	{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		|	VAR IDENTIFIER ':' STRING	{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		|	VAR IDENTIFIER ':' CHAR		{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		|	no_type_variable_declaration
		;

no_type_variable_declaration:
			VAR IDENTIFIER '=' NUMBER		{
												if(localSymtab == globalSymtab){
													// global scope
													symtabInsert(localSymtab, $2, "int", true, 0, NULL);
													fprintf(outputFile, "field static int %s\n", $2);
													// fprintf(outputFile, "sipush %d\n", $4);
													// fprintf(outputFile, "putstatic int %s.%s\n", globalSymtab->name, $2);
												}else{
													// local scope
													symtabInsert(localSymtab, $2, "int", true, localRef, NULL);
													localRef++;
													symtab *symbol = symtabLookup(localSymtab, $2);
													fprintf(outputFile, "sipush %d\n", $4);
													fprintf(outputFile, "istore %d\n", symbol->value);
												}
											}
		|	no_type_value_variable_declaration
		;

no_type_value_variable_declaration:
			VAR IDENTIFIER		{symtabInsert(localSymtab, $2, "void", true, 0, NULL);}
		;

array_declaration:	
			VAR IDENTIFIER ':' type '[' NUMBER ']'		{symtabInsert(localSymtab, $2, $4, true, 0, NULL);}
		; 

method_declaration:
			DEF IDENTIFIER 
			{
				// create local symtab and enter it
				localSymtab = symtabCreate($2, symtabIndexHead);
				listnodeHead = listnodeCreate();
				// set the reference number to the number of parameter
				localRef = 0;
			}
	 		'(' formal_argument ')' type_exp 
			{
				// enter global, and insert to global
				localSymtab = globalSymtab;
				symtabInsert(localSymtab, $2, $7, false, 0, $5);
				//code generation
				fprintf(outputFile, "method public static %s %s (", $7, $2);
				if(strcmp($2, "main") == 0){
					// main method use String as input type
					fprintf(outputFile, "java.lang.String[]");
				}else{
					// other function print out the type list
					symtab *symbol;
					symbol = scopeLookup(globalSymtab, localSymtab, $2);
					listnode *typelist = symbol->parameterList;
					while(typelist->next != NULL){
						typelist = typelist->next;
						fprintf(outputFile, "%s", typelist->val);
						if(typelist->next != NULL)fprintf(outputFile, ",");
					}
				}
				// set to local symtab
				symtabIndex *index = symtabIndexLookup(symtabIndexHead, $2);
				localSymtab = index->table;
				fprintf(outputFile, ")\nmax_stack 15\nmax_locals 15\n{\n");
			}
			'{' method_block 
			{
				symtab *symbol = symtabLookup(globalSymtab, $2);
				if(strcmp(symbol->type, "void") == 0){
					fprintf(outputFile, "return\n");
					fprintf(outputFile, "}\n");
				}else{
					fprintf(outputFile, "}\n");
				}
			}
			'}'
		;

formal_argument:
			formal_argument ',' IDENTIFIER ':' type		{
															symtabInsert(localSymtab, $3, $5, true, localRef, NULL);
															listnodeInsert(listnodeHead, $5);
															localRef++;
														}
		|	IDENTIFIER ':' type							{
															symtabInsert(localSymtab, $1, $3, true, localRef, NULL);
															listnodeInsert(listnodeHead, $3);
															localRef++;
															$$=listnodeHead;
														}
		|	{
				printf("type NUll\n");
				$$=NULL;
			}
		;

type_exp:
			{$$="void";}
		|	':' type {$$=$2;}
		;

method_block:	zmvcd zms;

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
												char *out = storeSymbol(globalSymtab, localSymtab, symbol->name, symbol->value);
												fprintf(outputFile, "%s", out);
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
		|	PRINTLN 
			{
				fprintf(outputFile, "getstatic java.io.PrintStream java.lang.System.out\n");
			}
			'(' num_expression ')'
			{
				if(strcmp($4, "int") == 0){
					// type = string
					fprintf(outputFile, "invokevirtual void java.io.PrintStream.println(int)\n");
				}else{
					// type = int
					fprintf(outputFile, "invokevirtual void java.io.PrintStream.println(java.lang.String)\n");
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
			IF '(' boolean_expression ')' ACT sab_statment 
			{
				fprintf(outputFile, "goto Lexit\n");
			}
			ELSE
			{
				fprintf(outputFile, "Lfalse:\n");
			}
			sab_statment
			{
				fprintf(outputFile, "Lexit:\n");
				Trace("Reduce to conditional statement\n");
			}
		|
			IF '(' boolean_expression ')' ACT sab_statment
			{
				fprintf(outputFile, "Lfalse:\n");
				Trace("Reduce to conditional statement\n");
			}
		;

ACT:
	{
		fprintf(outputFile, "Lfalse\n");
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
				fprintf(outputFile, "goto Lbegin\n");
				fprintf(outputFile, "Lexit:\n");
			}
		|	FOR '(' IDENTIFIER '<''-' NUMBER TO NUMBER ')'
			{
				char name[10];
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
								yyerror("!!!Couldn't resolve the symbol!!!\n");
							}
							listnode *idParam = symbol->parameterList;
							listnode *inputParam = $4;
							if(listcmp(idParam, inputParam) != 0){
								yyerror("!!!Type mismatch!!!");
							}
							// code generation
							fprintf(outputFile, "invokestatic int %s.%s(", globalSymtab->name, $1);
							while(inputParam->next != NULL){
								inputParam = inputParam->next;
								fprintf(outputFile, "%s ", inputParam->val);
								if(inputParam->next != NULL)fprintf(outputFile, ",");
							}
							fprintf(outputFile, ")\n");
							$$ = symbol->type;
						}
						;

parameter_expression:
						parameter_expression ',' value 		{
																// type checking
																listnodeInsert(listnodeHead, $3);
															}
					|	value 								{
																// type checking
																listnodeInsert(listnodeHead, $1);
																$$ = listnodeHead;
															}
					| 	{$$=NULL;}
					;

value: 
		NUMBER 					{
									fprintf(outputFile, "sipush %d\n", $1);
									$$ = "int";
								}
	| 	REAL					{$$ = "float";}
	|	STRING_VAL				{
									fprintf(outputFile, "ldc \"%s\"\n", $1);
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

num_expression:
			num_expression '+' num_expression	{
													fprintf(outputFile, "iadd\n");
													// type checking
													if(strcmp($1, $3) != 0)yyerror("!!!expression type mismatch!!!");
													else $$=$1;
												}
		|	num_expression '-' num_expression	{
													fprintf(outputFile, "isub\n");
													// type checking
													if(strcmp($1, $3) != 0)yyerror("!!!expression type mismatch!!!");
													else $$=$1;
												}
		|	num_expression '*' num_expression	{
													fprintf(outputFile, "imul\n");
													// type checking
													if(strcmp($1, $3) != 0)yyerror("!!!expression type mismatch!!!");
													else $$=$1;
												}
		|	num_expression '/' num_expression	{
													fprintf(outputFile, "idiv\n");
													// type checking
													if(strcmp($1, $3) != 0)yyerror("!!!expression type mismatch!!!");
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
															fprintf(outputFile, "ifge ");
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
		|	'!' boolean_expression %prec '!'
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
	char *inputFileName;
	char *outputFileName;
    /* open the source program file */
    if (argc != 2) {
		printf ("Usage: scala filename\n");
		exit(1);
    }else{
		// store arg2
		inputFileName = (char*)malloc(sizeof(char)*strlen(argv[1]));
		strcpy(inputFileName, argv[1]);
	}
	// symtab index initialized here
    if((yyin = fopen(inputFileName, "r")) == NULL){
		printf("Error: File Not Found\n");
		exit(1);
	}else{
		// replace the *.scala to *.javac
		char *newSub = ".jasm";
		char *mid = strchr(inputFileName, '.');
		strcpy(mid, newSub);
		outputFileName = (char*)malloc(sizeof(char)*strlen(inputFileName));
		strcpy(outputFileName, inputFileName);
		// open file for ouptut
		outputFile = fopen(outputFileName, "w");
    	symtabIndexHead = symtabIndexCreate();
		// parameter initialization
		conRef = 0;
	}
    
    /* perform parsing */
    if (yyparse() == 1){
		yyerror("Parsing error !");     /* syntax error */
	}
	else{
		// check if there is any main method
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
		yyerror("!!!This symbol table name is redifined!!!");
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
	printf("\nSymbol Table List\n");
	while(current->next !=  NULL){
		current = current->next;
		printf("%s\n", current->name);
		symtabDump(current->table);
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
		yyerror("!!!This symbol name is redifined!!!");
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
	while(current->next !=  NULL){
		printf("<%s : %s = %d>\n", current->name, current->type, current->value);
		current = current->next;
	}
	printf("<%s : %s = %d>\n", current->name, current->type, current->value);
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
// get the last listnode and delete it from list
listnode* listnodePop(listnode* head){
	listnode* current = head;
	listnode* last;
	while(current->next != NULL){
		// last to last two, current to last one
		last = current;
		current = current->next;
	}
	last->next = NULL;
	return current;
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
		current = current->next;
		printf("%s\n", current->val);
	}
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
		char err[500];
		sprintf(err, "!!!Input id \"%s\" doesn't exist in local or global scope!!!", name);
		yyerror(err);
		return NULL;
	}
}

// list cmp, return 0 if all elements are the same, other means not the same
// length are not the same: l1=null, l2!=null or vice versa
int listcmp(listnode *l1, listnode *l2){
	int result = 0;
	listnode *current1 = l1;
	listnode *current2 = l2;
	while(current1->next != NULL){
		// of the same length
		current1 = current1->next;
		current2 = current2->next;
		if(current1->next != NULL && current2->next != NULL){
			if(strcmp(current1->val, current2->val) != 0)result++;
		}else if(current1->next != NULL && current2->next == NULL){
			yyerror("!!!Length of Parameter aren't the same!!!");
			return ++result;
		}else if(current1->next == NULL && current2->next != NULL){
			yyerror("!!!Length of Parameter aren't the same!!!");
			return ++result;
		}else{
			if(strcmp(current1->val, current2->val) != 0)result++;
		}
	}
	return result;
}

char* storeSymbol(symtab *global, symtab *local, char *name, int ref){
	char result[100];
	char *str = &result[0];
	symtab *symbol;
	if((symbol = symtabLookup(local, name)) != NULL){
		// local
		if(symbol->changeable == true){
			// variable
			sprintf(result, "istore %d\n", ref);
		}else if(symbol->changeable == false){
			// constant
			yyerror("!!!Trying to modify constant!!!");
		}
	}else if((symbol = symtabLookup(global, name)) != NULL){
		// global
		if(symbol->changeable == true){
			// variable
			sprintf(result, "putstatic int %s.%s \n", global->name, symbol->name);
		}else if(symbol->changeable == false){
			// constant
			yyerror("!!!Trying to modify constant!!!");
		}
	}else{
		char err[500];
		sprintf(err, "!!!Symbol \"%s\" Not Found!!!", name);
		yyerror(err);
		str = NULL;
	}
	return str;
}

char* loadSymbol(symtab *global, symtab *local, char *name){
	// a symbol could be local or global, and variable or constant
	char result[500];
	char *str = &result[0];
	symtab *symbol;
	if((symbol = symtabLookup(local, name)) != NULL){
		// local
		if(symbol->changeable == 1){
			// variable
			sprintf(result, "iload %d\n", symbol->value);
		}else{
			// constant: looking in symtab
			sprintf(result, "sipush %d\n", symbol->value);
		}
	}else if((symbol = symtabLookup(global, name)) != NULL){
		// global
		if(symbol->changeable == 1){
			// variable
			sprintf(result, "getstatic %s %s.%s\n", symbol->type, global->name, symbol->name);
		}else{
			// constant: looking in symtab, directly return the value
			sprintf(result, "sipush %d\n", symbol->value);
		}
	}else{
		yyerror("!!!Symbol Not Found!!!");
		str = NULL;
	}
	return str;
}
