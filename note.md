# B10504028 Compiler Design Project 2
## Change to scanner.l
I reserve the original functionality that print one line after a token is recognize for simplicity of debugging.
Return the token defined in parser.y for each token
A new symbol table structure and insertion, lookup, create function is created.
Other program including comment recognition remain unchange. 
## Change to parser.y
A new symbol table structure insertion, lookup, create function are created.
I left the dangling else ambiguity unsolved, so there is one conflict.