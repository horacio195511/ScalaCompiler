# B10504028 Compiler Design Project 2
## Change to scanner.l
scanner remain unchange, and still capable of recognize all of the token unused for debug.
the scanner are able to recognize keyword regardless of upper or lower case.
## Change to parser.y
Add parameter type checking
Add expression type checking
Create a seperate symbol table for each scope: function, loop, if statement or any block statement. The head parameter would point to the current symbol table for each scope. Scope list would be store in symtabIndex.
Add symbol table index for faster symbol table search.
A symbol table index is a scope. scope include method(local) and object(global).
Add one more value property in the symtab structure for handling constant variable. For local variable, the reference number would be store here.
if...else..., while, for could be used in nested style, because Scala- doesn't support elseif statment, so nested if...else... is neccesary.

## Bonus
### READ
READ statement is working for reading integer from console. read id, to read a integer from console and store into variable id.
### Array
Array could be defined with var IDENTIFIER:int [ number ], spaces before and after the number is necessary or the token won't be recognize.
And the value of array could be declared with
IDENTIFIER[ number ] = number
note this statement must have some type checking mechanism to ensure that the IDENTIFER is declared as an array.
Array value could be access by invoke IDENTIFIER[ number ]
only one dimension array is available, the size of array have to be constant