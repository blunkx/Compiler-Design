%{
#include <stdio.h>
extern int yylex(void);
void yyerror(char *s)
{
    printf("%s\n", s);
    fprintf(stderr, "%s\n", s);
}

%}

%union
{
    size_t sizet;
    long int4;
    double fp;
    char *str;
}
%token <sizet> SIZE_T_CONS
%token <int4> NEG_INT_CONS BOOL_CONS
%token <fp> REAL_CONS
%token <str> STR_CONS
%token BOOL BREAK CHAR CASE CLASS CONTINUE DECLARE DO ELSE EXIT FALSE FLOAT FOR FUN IF INT LOOP PRINT PRINTLN RETURN STRING TRUE VAL VAR WHILE
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

%%
PROGRAM: 
    |PROGRAM CLASS_UNIT {printf("CLASS\n");}
;

/*2.2*/
CLASS_UNIT: CLASS ID '{' CLASS_BODY '}';

CLASS_BODY:
    |CLASS_BODY CONS_DECLARATION 
    |CLASS_BODY VAR_DECLARATION 
    |CLASS_BODY ARR_DECLARATION 
    |CLASS_BODY FUN_UNIT 
;

FUN_UNIT: FUN ID '(' FUNC_ARG ')' FUN_RE_TYPE '{' FUNC_BODY '}'{printf("FUN\n");}
    |FUN MAIN '(' FUNC_ARG ')' '{' FUNC_BODY '}' {printf("MAIN\n");}
;

FUNC_ARG: 
    | ID ':' TYPE FUNC_ARGS
;
FUNC_ARGS:
    | ',' ID ':' TYPE FUNC_ARGS
;
FUN_RE_TYPE:  
    |':' TYPE
;

FUNC_BODY: 
    |FUNC_BODY CONS_DECLARATION 
    |FUNC_BODY VAR_DECLARATION 
    |FUNC_BODY ARR_DECLARATION 
    |FUNC_BODY STATEMENT 
;
/*2.3*/
STATEMENT: ID '=' EXP {printf("ASSIGN\n");}
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
CONS_DECLARATION: VAL ID '=' EXP 
    |VAL ID ':' TYPE_CONS
;

VAR_DECLARATION: VAR ID
    |VAR ID ':' TYPE
    |VAR ID '=' EXP
    |VAR ID ':' TYPE_CONS
;

ARR_DECLARATION: VAR ID ':' TYPE '[' SIZE_T_CONS ']'
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
    |STRING
    |FLOAT
    |BOOL
;

TYPE_CONS: INT '=' INT_CONS
    |STRING '=' STR_CONS
    |FLOAT '=' REAL_CONS
    |BOOL '=' BOOL_CONS
;

INT_CONS: SIZE_T_CONS
| NEG_INT_CONS
;

COND_STATEMENT: IF '(' EXP ')' STATEMENT_BODY ELSE STATEMENT_BODY
    |IF '(' EXP ')' STATEMENT_BODY
;

LOOP_STATEMENT: WHILE '(' EXP ')' STATEMENT_BODY
    |FOR '(' ID IN INT_CONS BETWEEN INT_CONS ')' STATEMENT_BODY
;

STATEMENT_BODY: '{' FUNC_BODY '}'
|   STATEMENT   
;


%%
int main(void)
{
    while (yyparse())
    {
    }
    return 0;
}