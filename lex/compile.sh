#!/bin/sh
prog_name=scanner

lex test.l
gcc lex.yy.c -ll -o $prog_name
cat input.txt| ./$prog_name >out.txt
#rm *.c $prog_name