compiler: lex.yy.o y.tab.o symbols.o
	gcc -o compiler lex.yy.o y.tab.o symbols.o -ll

lex.yy.o: lex.yy.c y.tab.h
	gcc -c -g lex.yy.c

y.tab.o: y.tab.c lex.yy.c
	gcc -c -g y.tab.c

y.tab.c y.tab.h: compiler.y 
	yacc -d compiler.y 

lex.yy.c: scanner.l
	lex scanner.l

symbols.o: symbols.c
	gcc -c -g symbols.c

clean:
	rm -f *.o lex.yy.c y.tab.* compiler *.txt *.jasm *.class