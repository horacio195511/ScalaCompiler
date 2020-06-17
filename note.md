# B10504028 Compiler Design Project 2
## Change to scanner.l
I reserve the original functionality that print one line after a token is recognize for simplicity of debugging.
Return the token defined in parser.y for each token
A new symbol table structure and insertion, lookup, create function is created.
Other program including comment recognition remain unchange. 
## Change to parser.y
Add parameter type checking
Add expression type checking
Create a seperate symbol table for each scope: function, loop, if statement or any block statement. The head parameter would point to the current symbol table for each scope.