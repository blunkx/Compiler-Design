#ifndef SYMBOLS_H
#define SYMBOLS_H
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#define copy_str(des, src)                        \
    {                                             \
        des = malloc(sizeof(char) * strlen(src)); \
        des = strcpy(des, src);                   \
    }

typedef struct s
{
    char *name;
    char *type;
    char *scope;
    struct s *pptr;
    struct s *nptr;
} symbol;

typedef struct t
{
    char *table_name;
    int size;
    symbol *begin;
} symbol_table;

symbol_table create();
int lookup(char *sym, symbol_table tb);
int insert(char *_n, char *_type, char *_scope, symbol_table *tb);
void dump(symbol_table *tb);
void print_tb(symbol_table tb);
#endif