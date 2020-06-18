# B10504028 Compiler Design Project 2
## Change to scanner.l
scanner remain unchange, and still capable of recognize all of the token unused for debug.
## Change to parser.y
Add parameter type checking
Add expression type checking
Create a seperate symbol table for each scope: function, loop, if statement or any block statement. The head parameter would point to the current symbol table for each scope.