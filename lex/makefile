# scanner: lex.yy.o symbols.o
# 	gcc -o p lex.yy.o symbols.o -ll
# 	cat input.txt| ./p >out.txt
scanner: lex.yy.o
	gcc -o scanner lex.yy.o -ll
	cat input.txt| ./scanner >out.txt
lex.yy.o: scanner.l
	lex scanner.l
	gcc -c -g lex.yy.c
# symbols.o: symbols.c symbols.h
# 	gcc -c -g symbols.c

clean:
	rm -f *.o lex.yy.c scanner