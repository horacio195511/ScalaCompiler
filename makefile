scala: lex.yy.c y.tab.c
	gcc -g -o scala y.tab.c lex.yy.c -ll -ly

lex.yy.c: scanner.l
	lex -l scanner.l

y.tab.c: parser.y
	yacc -d --report-file=yaccReport parser.y 

clean:
	rm lex.yy.c y.tab.*
