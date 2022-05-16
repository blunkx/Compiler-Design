#ifndef SYMBOLS_H
#define SYMBOLS_H
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

enum OP_Type
{
    MUL_INT = 01,
    MUL_FP = 02,

    DIV_INT = 11,
    DIV_FP = 12,

    ADD_INT = 21,
    ADD_FP = 22,

    MIN_INT = 31,
    MIN_FP = 32,

    L_INT = 41,
    L_FP = 42,

    G_INT = 51,
    G_FP = 52,

    LE_INT = 61,
    LE_FP = 62,

    EQ_UI = 70,
    EQ_INT = 71,
    EQ_FP = 72,
    EQ_STR = 73,

    GE_INT = 81,
    GE_FP = 82,

    NEQ_UI = 90,
    NEQ_INT = 91,
    NEQ_FP = 92,
    NEQ_STR = 93,

    NOR_UI = 100,

    AND_UI = 110,

    OR_UI = 120,
};

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
void insert_dup(symbol *const sym, symbol_table *tb);
void dump(symbol_table *tb);
void print_tb(symbol_table tb, char *msg);

typedef struct st
{
    symbol_table *top_ptr;
} stack;
stack *create_stack();
void pop(stack *const st);
void push(symbol_table *const tb, stack *const st);
symbol_table *top();
symbol *search_id(char *_n, stack st);
void print_stack(stack st);

void create_fun_arg_info(symbol *temp, symbol_table *arg_tb);
#endif