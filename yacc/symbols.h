#ifndef SYMBOLS_H
#define SYMBOLS_H
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
enum Type
{
    UI_VAL,
    INT_VAL,
    FP_VAL,
    STR_VAL,
    CLASS_DEC,
    FUNC_DEC,
    VOID_TYPE,
    ARR_UI,
    ARR_INT,
    ARR_FP,
    ARR_STR,

};
typedef union v
{
    size_t sizet;
    long int4;
    double fp;
    char *str;
    void *arr_ptr;
} value;

typedef struct s
{
    char *name;
    int type;
    char *scope;
    value v;
    size_t argn;
    int *arg_type;
    char **arg_name;
    struct s *pptr;
    struct s *nptr;
} symbol;
symbol *create_sym(char *_n, int _type, value _v);

typedef struct t
{
    char *table_name;
    int size;
    symbol *begin;
    struct t *pptr;
    struct t *nptr;
} symbol_table;

symbol_table *create_tb();
symbol *lookup(char *sym, symbol_table tb);
void insert(symbol *const sym, symbol_table *tb);
void dump(symbol_table *tb);
void print_tb(symbol_table tb);

typedef struct st
{
    symbol_table *top_ptr;
} stack;
stack *create_stack();
void pop(stack *const st);
void push(symbol_table *const tb, stack *const st);
symbol_table *top();
void print_stack(stack st);

void create_fun_arg_info(symbol *temp, symbol_table *arg_tb);
#endif