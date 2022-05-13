%{
#include <stdio.h>
#include "symbols.h"
extern int yylex(void);
void yyerror(char *s)
{
    printf("%s\n", s);
    fprintf(stderr, "%s\n", s);
}
stack *s;
value val;
symbol_table *arg_tb;
%}

%union
{
    size_t sizet;
    long int4;
    double fp;
    char *str;
    symbol *sym;
    symbol_table *sym_tb;
}
%token <sizet> SIZE_T_CONS
%token <int4> NEG_INT_CONS BOOL_CONS
%token <fp> REAL_CONS
%token <str> STR_CONS
%token BREAK CHAR CASE CLASS CONTINUE DECLARE DO ELSE EXIT FALSE FOR FUN IF LOOP PRINT PRINTLN RETURN TRUE VAL VAR WHILE
%token <int4> INT FLOAT STRING BOOL 
%token ARROW
%token LE GE EQ NEQ EQ_ADD EQ_MIN EQ_MUL EQ_DIV
%token MAIN READ
%token <str> ID
%token IN BETWEEN

%left '|'
%left '&'
%left '!'
%left LE GE EQ NEQ '>' '<'
%left '+' '-'
%left '*' '/'

%type<int4> TYPE FUN_RE_TYPE
%type<sym> TYPE_CONS
%type<sym_tb> FUNC_ARG FUNC_ARGS
%type<int4> INT_CONS
%%
PROGRAM: 
    |PROGRAM { 
        symbol_table *class = create_tb(); 
        push(class, s);
    } CLASS_UNIT {
        print_stack(*s);
        pop(s);
    }
;

/*2.2*/
CLASS_UNIT: CLASS ID 
    {
        val.sizet= VOID_TYPE;
        insert(create_sym($2, CLASS_DEC, val), top(*s));
    } 
    '{' 
    { 
        push(create_tb(), s);
    } 
    CLASS_BODY '}' 
    {
        print_stack(*s);
        pop(s);
    };

CLASS_BODY:
    |CLASS_BODY CONS_DECLARATION 
    |CLASS_BODY VAR_DECLARATION 
    |CLASS_BODY ARR_DECLARATION 
    |CLASS_BODY FUN_UNIT 
;

FUN_UNIT: FUN ID '(' 
    {
        arg_tb = create_tb();
    }
    FUNC_ARG ')' FUN_RE_TYPE '{' 
    { 
        val.sizet = $7;
        symbol *temp = create_sym($2, FUNC_DEC, val);

        temp->arg_type = malloc(sizeof(int) * arg_tb->size);
        temp->arg_name = malloc(sizeof(char *) * arg_tb->size);
        symbol *temp_ptr = arg_tb->begin;
        int i = 0;
        for (i = arg_tb->size - 1; i >= 0; i--)
        {
            temp->arg_type[i] = temp_ptr->type;
            temp->arg_name[i] = strdup(temp_ptr->name);
            temp_ptr = temp_ptr->nptr;
        }
        temp->argn = arg_tb->size;
        insert(temp, top(*s));
        push(arg_tb, s);
        arg_tb = NULL;
    }
    FUNC_BODY '}'
    {
        print_stack(*s);
        pop(s);
    }
    |FUN MAIN '(' 
    {
        arg_tb = create_tb();
    }
    FUNC_ARG ')' '{' 
    { 
        val.sizet = VOID_TYPE;
        symbol *temp = create_sym("main", FUNC_DEC, val);
        temp->argn = arg_tb->size;
        insert(temp, top(*s));
        push(arg_tb, s);
        arg_tb = NULL;
    }
    FUNC_BODY '}' 
    {
        print_stack(*s);
        pop(s);
    }
;

FUNC_ARG: 
    {
        $$ = arg_tb;
    }
    | ID ':' TYPE FUNC_ARGS
    {
        switch ($3)
        {
        case UI_VAL:
            val.sizet = 0;
            insert(create_sym($1, UI_VAL, val), arg_tb);
            break;
        case INT_VAL:
            val.int4 = 0;
            insert(create_sym($1, INT_VAL, val), arg_tb);
            break;
        case FP_VAL:
            val.fp = 0.0;
            insert(create_sym($1, FP_VAL, val), arg_tb);
            break;
        case STR_VAL:
            val.str = strdup("");
            insert(create_sym($1, STR_VAL, val), arg_tb);
            break;
        default:
            break;
        }
    }
;
FUNC_ARGS:
    {
        $$ = arg_tb;
    }
    | ',' ID ':' TYPE FUNC_ARGS
    {
        switch ($4)
        {
        case UI_VAL:
            val.sizet = 0;
            insert(create_sym($2, UI_VAL, val), arg_tb);
            break;
        case INT_VAL:
            val.int4 = 0;
            insert(create_sym($2, INT_VAL, val), arg_tb);
            break;
        case FP_VAL:
            val.fp = 0.0;
            insert(create_sym($2, FP_VAL, val), arg_tb);
            break;
        case STR_VAL:
            val.str = strdup("");
            insert(create_sym($2, STR_VAL, val), arg_tb);
            break;
        default:
            break;
        }
    }
;
FUN_RE_TYPE:  
    {
        $$ = VOID_TYPE;
    }
    |':' TYPE
    {
        $$ = $2;
    }
;

FUNC_BODY: 
    |FUNC_BODY CONS_DECLARATION 
    |FUNC_BODY VAR_DECLARATION 
    |FUNC_BODY ARR_DECLARATION 
    |FUNC_BODY STATEMENT 
;
/*2.3*/
STATEMENT: ID '=' EXP 
    { 
        // printf("ASSIGN\n"); 
    }
    |ID '[' EXP ']' '=' EXP
    |PRINT '(' EXP ')'
    |PRINT EXP
    |PRINTLN '(' EXP ')'
    |PRINTLN EXP
    |READ ID
    |RETURN
    |RETURN EXP
    |COND_STATEMENT
    |LOOP_STATEMENT
;

/*2.1*/
/*
DEC EXP => float
*/
CONS_DECLARATION: VAL ID '=' EXP 
    {
        // XXXXXXX
        val.fp = 0.7777;
        insert(create_sym($2, FP_VAL, val), top(*s));
    }
    |VAL ID ':' TYPE_CONS
    {
        $4->name = strdup($2);
        insert($4, top(*s));
    }
;

/*Without type the assign value only accept float expression*/
VAR_DECLARATION: VAR ID
    {
        val.int4 = 0;
        insert(create_sym($2, INT_VAL, val), top(*s));
    }
    |VAR ID ':' TYPE
    {
        switch ($4)
        {
        case UI_VAL:   
            val.sizet = 0;
            insert(create_sym($2, UI_VAL, val), top(*s));
            break;
        case INT_VAL:
            val.int4 = 0;
            insert(create_sym($2, INT_VAL, val), top(*s));
            break;
        case FP_VAL:
            val.fp = 0.0;
            insert(create_sym($2, FP_VAL, val), top(*s));
            break;
        case STR_VAL:
            val.str = strdup("");
            insert(create_sym($2, STR_VAL, val), top(*s));
            break;
        default:
            break;
        }
    }
    |VAR ID '=' EXP
    {
        // XXXXXXX
        val.fp = 0.8888;
        insert(create_sym($2, FP_VAL, val), top(*s));
    }
    |VAR ID ':' TYPE_CONS
    {
        $4->name = strdup($2);
        insert($4, top(*s));
    }
;
/* Warrning: Warning: Array declaration have no range protection. */
/* Only allocate memory space for array */
ARR_DECLARATION: VAR ID ':' TYPE '[' SIZE_T_CONS ']'
    {
        switch ($4)
        { 
        case UI_VAL:
            val.arr_ptr = malloc(sizeof(size_t) * $6);
            insert(create_sym($2, ARR_UI, val), top(*s));
            break;
        case INT_VAL:
            val.arr_ptr = malloc(sizeof(long) * $6);
            insert(create_sym($2, ARR_INT, val), top(*s));
            break;
        case FP_VAL:
            val.arr_ptr = malloc(sizeof(double) * $6);
            insert(create_sym($2, ARR_FP, val), top(*s));
            break;
        case STR_VAL:
            val.arr_ptr = malloc(sizeof(char *) * $6);
            insert(create_sym($2, ARR_STR, val), top(*s));
            break;
        default:
            break;
        }
    }
;

EXP: EXP OP TERM
    |UNARY_OP TERM {printf("xx\n");}
    |TERM
    |ID '(' FUNC_INV_ARG ')'
;

FUNC_INV_ARG: 
    |EXP FUNC_INV_ARGS
;

FUNC_INV_ARGS: 
    |',' EXP FUNC_INV_ARGS
;

TERM: ID
    |CONS
    |ID '[' SIZE_T_CONS ']'
;

UNARY_OP: '-';

OP: '*'
    |'/'
    |'+'
    |'-'
    |'<'
    |'>'
    |LE
    |EQ
    |GE
    |NEQ
    |'!'
    |'&'
    |'|'
;

CONS: INT_CONS
    |BOOL_CONS 
    |REAL_CONS
    |STR_CONS
;

TYPE: INT
    {
        $$ = $1;
    }
    |STRING
    {
        $$ = $1;
    }
    |FLOAT
    {
        $$ = $1;
    }
    |BOOL
    {
        $$ = $1;
    }
;

TYPE_CONS: INT '=' INT_CONS
    {
        val.int4 = $3;
        $$ = create_sym("temp", INT_VAL, val);
    }
    |STRING '=' STR_CONS
    {
        val.str = strdup($3);
        $$ = create_sym("temp", STR_VAL, val);
    }
    |FLOAT '=' REAL_CONS
    {
        val.fp = $3;
        $$ = create_sym("temp", FP_VAL, val);
    }
    |BOOL '=' BOOL_CONS
    {
        val.sizet = $3;
        $$ = create_sym("temp", UI_VAL, val);
    }
;

INT_CONS: SIZE_T_CONS 
    {
        $$ = $1;
    }
    | NEG_INT_CONS
    {
        $$ = $1;
    }
;

COND_STATEMENT: IF '(' EXP ')' STATEMENT_BODY ELSE STATEMENT_BODY
    |IF '(' EXP ')' STATEMENT_BODY
;

LOOP_STATEMENT: WHILE '(' EXP ')' STATEMENT_BODY
    |FOR '(' ID IN INT_CONS BETWEEN INT_CONS ')' STATEMENT_BODY
;

STATEMENT_BODY: '{' 
    { 
        push(create_tb(), s);
    } 
    FUNC_BODY '}'
    {
        print_stack(*s);
        pop(s);
    }
|   STATEMENT   
;


%%
int main(void)
{
    s = create_stack();
    printf("Value represent return type, array size or real value!\n");
    while (yyparse())
    {
    }
    return 0;
}