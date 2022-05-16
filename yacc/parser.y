%{
#include <stdio.h>
#include "symbols.h"
#define show_stack 0
#define show_top 1
extern int yylex(void);
void init_arr(void *arr_ptr, int type, size_t len)
{
    int i = 0;
    switch (type)
    {
    case UI_VAL:
        for (; i < len; i++)
        {
            ((size_t *)arr_ptr)[i] = 0;
        }
        break;
    case INT_VAL:
        for (; i < len; i++)
        {
            ((long *)arr_ptr)[i] = 0;
        }
        break;
    case FP_VAL:
        for (; i < len; i++)
        {
            ((double *)arr_ptr)[i] = 0;
        }
        break;
    case STR_VAL:
        for (; i < len; i++)
        {
            ((char **)arr_ptr)[i] = strdup("init");
        }
        break;
    default:
        break;
    }
}

stack *s;
value val;

/* Temp symbol is not free. */
/*Arg_tb is used for FUNC_ARG FUNC_ARGS FUNC_INV_ARG FUNC_INV_ARGS */
symbol_table *arg_tb;

void yyerror(char *_s)
{
    // dump stack to check error
    print_stack(*s);
    printf("%s\n", _s);
    fprintf(stderr, "%s\n", _s);
    exit(0);
}

void show_tb(char *msg)
{
    if (show_stack == 1)
    {
        print_stack(*s);
    }
    else if (show_top == 1)
    {
        print_tb(*top(*s), msg);
    }
}
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
%token <sizet> BOOL_CONS
%token <int4> INT_CONS 
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
%nonassoc UNARY_OP
%type<int4> TYPE FUN_RE_TYPE OP
%type<sym> EXP CONS TERM

%%
PROGRAM: 
    |PROGRAM 
    { 
        symbol_table *class = create_tb();
        push(class, s);
    } CLASS_UNIT 
    {
        show_tb("End");
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
        symbol *id_val = search_id("main", *s);
        if (id_val == NULL || id_val->type != FUNC_DEC)
        {
            yyerror("No main function in the class!");
        }
        show_tb("End of Class");
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
        if (lookup($2, *top(*s)) == NULL)
        {
            val.sizet = $7;
            symbol *temp = create_sym($2, FUNC_DEC, val);
            temp->arg_type = malloc(sizeof(int) * arg_tb->size);
            temp->arg_name = malloc(sizeof(char *) * arg_tb->size);
            symbol *temp_ptr = arg_tb->begin;
            int i = 0;
            for (; i < arg_tb->size; i++)
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
        else
        {
            yyerror("Duplicate declaration!");
        }
    }
    FUNC_BODY '}'
    {
        show_tb($2);
        pop(s);
    }
    |FUN MAIN '(' 
    {
        arg_tb = create_tb();
    }
    FUNC_ARG ')' '{' 
    { 
        if (lookup("main", *top(*s)) == NULL)
        {
            val.sizet = VOID_TYPE;
            symbol *temp = create_sym("main", FUNC_DEC, val);
            temp->argn = arg_tb->size;
            insert(temp, top(*s));
            push(arg_tb, s);
            arg_tb = NULL;
        }
        else
        {
            yyerror("Duplicate declaration!");
        }
    }
    FUNC_BODY '}' 
    {
        show_tb("End of main");
        pop(s);
    }
;

FUNC_ARG: 
    | ID ':' TYPE FUNC_ARGS
    {
        /*Insert protection*/
        if (lookup($1, *arg_tb) == NULL)
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
                yyerror("Argument type error!");
                break;
            }
        }
        else
        {
            yyerror("Argument duplicate declaration!");
        }
        
    }
;
FUNC_ARGS:
    | ',' ID ':' TYPE FUNC_ARGS
    {
        if (lookup($2, *arg_tb) == NULL)
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
                yyerror("Argument type error!");
                break;
            }
        }
        else
        {
            yyerror("Argument duplicate declaration!");
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
        symbol *id_val = search_id($1, *s);
        if (id_val == NULL)
        {
            yyerror("Use undefined ID!");
        }
        else
        {
            if (id_val->type == $3->type)
            {
                switch (id_val->type)
                {
                case UI_VAL:   
                case INT_VAL:
                case FP_VAL:
                case STR_VAL:
                    id_val->v = $3->v;
                    break;
                default:
                    yyerror("Invaild assign!");
                    break;
                }
            }
            else
            {
                yyerror("Assign type error!");
            }
        }
    }
    |ID '[' EXP ']' '=' EXP
    {
        symbol *id_val = search_id($1, *s);
        if (id_val == NULL)
        {
            yyerror("Use undefined ID!");
        }
        else
        {
            if (id_val->type == $6->type+7 && $3->type == INT_VAL)
            {
                switch (id_val->type)
                {
                case ARR_UI:
                    ((size_t *)(id_val->v.arr_ptr))[$3->v.int4]  = $6->v.sizet;
                    break;
                case ARR_INT:
                    ((long *)(id_val->v.arr_ptr))[$3->v.int4] = $6->v.int4;
                    break;
                case ARR_FP:
                    ((double *)(id_val->v.arr_ptr))[$3->v.int4] = $6->v.fp;
                    break;
                case ARR_STR:
                    ((char **)(id_val->v.arr_ptr))[$3->v.int4] = strdup($6->v.str);
                    break;
                default:
                    yyerror("Access ID not array!");
                    break;
                }
            }
            else
            {
                yyerror("Array assign type error or index error!");
            }
        }
    }
    |PRINT '(' EXP ')'
    {
        switch ($3->type)
        {
        case UI_VAL:   
        case INT_VAL:
        case FP_VAL:
        case STR_VAL:
            break;
        default:
            yyerror("Print type error!");
            break;
        }
    }
    |PRINT EXP
    {
        switch ($2->type)
        {
        case UI_VAL:   
        case INT_VAL:
        case FP_VAL:
        case STR_VAL:
            break;
        default:
            yyerror("Print type error!");
            break;
        }
    }
    |PRINTLN '(' EXP ')'
    {
        switch ($3->type)
        {
        case UI_VAL:   
        case INT_VAL:
        case FP_VAL:
        case STR_VAL:
            break;
        default:
            yyerror("Println type error!");
            break;
        }
    }
    |PRINTLN EXP
    {
        switch ($2->type)
        {
        case UI_VAL:   
        case INT_VAL:
        case FP_VAL:
        case STR_VAL:
            break;
        default:
            yyerror("Return type error!");
            break;
        }
    }
    |READ ID
    {
        symbol *id_val = search_id($2, *s);
        if (id_val == NULL)
        {
            yyerror("Use undefined ID!");
        }
        else
        {
            switch (id_val->type)
            {
            case UI_VAL:   
            case INT_VAL:
            case FP_VAL:
            case STR_VAL:
                break;
            default:
                yyerror("Read type error!");
                break;
            }
        }
    }
    |RETURN
    {
        // Javabyte
    }
    |RETURN EXP
    {
        switch ($2->type)
        {
        case UI_VAL:   
        case INT_VAL:
        case FP_VAL:
        case STR_VAL:
            break;
        default:
            yyerror("Print type error!");
            break;
        }
    }
    |COND_STATEMENT
    |LOOP_STATEMENT
;

/*2.1*/
/* 
not handle if id name is equal to fun or class name!!! 
only check duplicate declaration in same scope
*/

CONS_DECLARATION: VAL ID '=' EXP 
    {
        if (lookup($2, *top(*s)) == NULL)
        {
            switch ($4->type)
            {
            case UI_VAL:   
            case INT_VAL:
            case FP_VAL:
            case STR_VAL:
                $4->name = strdup($2);
                insert($4, top(*s));
                break;
            default:
                yyerror("Invaild declaration");
                break;
            }
        }
        else
        {
            yyerror("Duplicate declaration!");
        }  
    }
    |VAL ID ':' TYPE '=' EXP
    {
        if (lookup($2, *top(*s)) == NULL)
        {
            if ($4 != $6->type)
            {
                yyerror("Declaration type error!");
            }
            $6->name = strdup($2);
            insert($6, top(*s)); 
        }
        else
        {
            yyerror("Duplicate declaration!");
        }
    }
;

/*Without type the assign value only accept float expression*/
VAR_DECLARATION: VAR ID
    {
        if (lookup($2, *top(*s)) == NULL)
        {
            val.int4 = 0;
            insert(create_sym($2, INT_VAL, val), top(*s));
        }
        else
        {
            yyerror("Duplicate declaration!");
        }
    }
    |VAR ID ':' TYPE
    {
        if (lookup($2, *top(*s)) == NULL)
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
        else
        {
            yyerror("Duplicate declaration!");
        }
    }
    |VAR ID '=' EXP
    {
        if (lookup($2, *top(*s)) == NULL)
        {
            switch ($4->type)
            {
            case UI_VAL:   
            case INT_VAL:
            case FP_VAL:
            case STR_VAL:
                $4->name = strdup($2);
                insert($4, top(*s));
                break;
            default:
                yyerror("Invaild declaration");
                break;
            }
        }
        else
        {
            yyerror("Duplicate declaration!");
        }
    }
    |VAR ID ':' TYPE '=' EXP
    {
        if (lookup($2, *top(*s)) == NULL)
        {
            if ($4 != $6->type)
            {
                yyerror("Declaration type error!");
            }
            $6->name = strdup($2);
            insert($6, top(*s)); 
        }
        else
        {
            yyerror("Duplicate declaration!");
        }
        
    }
;
/* Warrning: Warning: Array declaration have no range protection. */
/* Only allocate memory space for array */
ARR_DECLARATION: VAR ID ':' TYPE '[' INT_CONS ']'
    {
        switch ($4)
        { 
        case UI_VAL:
            val.arr_ptr = malloc(sizeof(size_t) * $6);
            init_arr(val.arr_ptr, $4, $6);
            insert(create_sym($2, ARR_UI, val), top(*s));
            break;
        case INT_VAL:
            val.arr_ptr = malloc(sizeof(long) * $6);
            init_arr(val.arr_ptr, $4, $6);
            insert(create_sym($2, ARR_INT, val), top(*s));
            break;
        case FP_VAL:
            val.arr_ptr = malloc(sizeof(double) * $6);
            init_arr(val.arr_ptr, $4, $6);
            insert(create_sym($2, ARR_FP, val), top(*s));
            break;
        case STR_VAL:
            val.arr_ptr = malloc(sizeof(char *) * $6);
            init_arr(val.arr_ptr, $4, $6);
            insert(create_sym($2, ARR_STR, val), top(*s));
            break;
        default:
            break;
        }
    }
;

EXP: EXP OP TERM
    {
        // OP EXP return the left most ID
        if($1->type != $3->type)
        {
            yyerror("Operation between different types");
        }
        else
        {
            // Javabyte code for operation
            // (OP_NUM)*10 + (TYPE_NUM)
            switch ($2 * 10 + $1->type)
            {
            case MUL_INT:
            case MUL_FP:
                $$ = create_sym("temp", $1->type, $1->v);
                break;

            case DIV_INT:
                if ($3->v.int4 == 0)
                    yyerror("Error divide 0!");
                else
                    $$ = create_sym("temp", $1->type, $1->v);
                break;
            case DIV_FP:
                if ($3->v.fp == 0)
                    yyerror("Error divide 0!");
                else
                    $$ = create_sym("temp", $1->type, $1->v);
                break;

            case ADD_INT:
            case ADD_FP:
                $$ = create_sym("temp", $1->type, $1->v);
                break;

            case MIN_INT:
            case MIN_FP:
                $$ = create_sym("temp", $1->type, $1->v);
                break;

            case L_INT:
            case L_FP:
                // Boolean exp return ture
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;

            case G_INT:
            case G_FP:
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;

            case LE_INT:
            case LE_FP:
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;

            case EQ_UI:
            case EQ_INT:
            case EQ_FP:
            case EQ_STR:
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;

            case GE_INT:
            case GE_FP:
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;

            case NEQ_UI:
            case NEQ_INT:
            case NEQ_FP:
            case NEQ_STR:
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;

            case NOR_UI:
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;

            case AND_UI:
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            case OR_UI:
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |TERM
    {
        // pass value to exp
        $$ = $1;
    }
;

TERM: '-' TERM %prec UNARY_OP 
    {
        switch ($2->type)
        {
        case INT_VAL:
            val.int4 = -$2->v.int4;
            $$ = create_sym("temp", INT_VAL, val);
            break;
        case FP_VAL:
            val.fp = -$2->v.fp;
            $$ = create_sym("temp", FP_VAL, val);
            break;
        default:
            yyerror("Invalid type for unary minus!");
            break;
        }
    } 
    |ID
    {
        symbol *id_val = search_id($1, *s);
        if (id_val == NULL)
        {
            yyerror("Use undefined ID!");
        }
        else
        {
            $$ = create_sym(id_val->name, id_val->type, id_val->v);
        }
    }
    |CONS
    {
        // pass constant value to term
        $$ = $1;
    }
    |ID '[' EXP ']'
    {
        symbol *id_val = search_id($1, *s);
        if (id_val == NULL)
        {
            yyerror("Use undefined ID!");
        }
        else
        {
            if ($3->type != INT_VAL || $3->v.int4 < 0)
            {
                yyerror("Invaild index!");
            }
            switch (id_val->type)
            {
            case ARR_UI:
                val.sizet = ((size_t *)(id_val->v.arr_ptr))[$3->v.int4];
                $$ = create_sym("temp", UI_VAL, val);
                break;
            case ARR_INT:
                val.int4 = ((long *)(id_val->v.arr_ptr))[$3->v.int4];
                $$ = create_sym("temp", INT_VAL, val);
                break;
            case ARR_FP:
                val.fp = ((double *)(id_val->v.arr_ptr))[$3->v.int4];
                $$ = create_sym("temp", FP_VAL, val);
                break;
            case ARR_STR:
                val.str = ((char **)(id_val->v.arr_ptr))[$3->v.int4];
                $$ = create_sym("temp", STR_VAL, val);
                break;
            default:
                yyerror("Access ID not array!");
                break;
            }
        }
    }
    |ID '(' 
    {
        arg_tb = create_tb();
    }
    FUNC_INV_ARG ')'
    {
        symbol *id_val = search_id($1, *s);
        if (id_val == NULL)
        {
            yyerror("Use undefined ID!");
        }
        else
        {
            if (id_val->type == FUNC_DEC)
            {
                /* arg type check and build initial table*/
                if (id_val->argn == arg_tb->size)
                {
                    symbol *temp_ptr = arg_tb->begin;
                    int i = 0;
                    for (; i < id_val->argn; i++)
                    {
                        if ((id_val->arg_type)[i] != temp_ptr->type)
                        {
                            yyerror("Argument type error!");
                        }
                        free(temp_ptr->arg_name);
                        temp_ptr->name = strdup((id_val->arg_name)[i]);
                        temp_ptr = temp_ptr->nptr;
                    }    
                }
                else
                {
                    yyerror("Argument number not match!");
                }

                char *temp = malloc(sizeof(char) * (strlen($1) + 20));
                strcpy(temp, "Call function ");
                print_tb(*(arg_tb), strcat(temp, $1));
                free(temp);

                /*return type*/
                switch (id_val->v.sizet)
                {
                case UI_VAL:
                    val.sizet = 1;
                    $$ = create_sym("temp", UI_VAL, val);
                    break;
                case INT_VAL:
                    val.int4 = -1;
                    $$ = create_sym("temp", INT_VAL, val);
                    break;
                case FP_VAL:
                    val.fp = 0.1;
                    $$ = create_sym("temp", FP_VAL, val);
                    break;
                case STR_VAL:
                    val.str = strdup("Fun_return");
                    $$ = create_sym("temp", STR_VAL, val);
                    break;
                default:
                    yyerror("Function return type error!");
                    break;
                }
            }
            else
            {
                yyerror("Invalid function invocation!");
            }
        }
        arg_tb = NULL;
    }
;

FUNC_INV_ARG: 
    |EXP FUNC_INV_ARGS
    {
        insert_dup($1, arg_tb);
    }
;

FUNC_INV_ARGS: 
    |',' EXP FUNC_INV_ARGS
    {
        insert_dup($2, arg_tb);
    }
;

OP: '*' { $$ = 0; }
    |'/' { $$ = 1; }
    |'+' { $$ = 2; }
    |'-' { $$ = 3; }
    |'<' { $$ = 4; }
    |'>' { $$ = 5; }
    |LE { $$ = 6; }
    |EQ { $$ = 7; }
    |GE { $$ = 8; }
    |NEQ { $$ = 9; }
    |'!' { $$ = 10; }
    |'&' { $$ = 11; }
    |'|' { $$ = 12; }
;

CONS: INT_CONS
    {
        val.int4 = $1;
        $$ = create_sym("temp", INT_VAL, val);
    }
    |STR_CONS
    {
        val.str = strdup($1);
        $$ = create_sym("temp", STR_VAL, val);
    }
    |REAL_CONS
    {
        val.fp = $1;
        $$ = create_sym("temp", FP_VAL, val);
    }
    |BOOL_CONS 
    {
        val.sizet = $1;
        $$ = create_sym("temp", UI_VAL, val);
    }
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

COND_STATEMENT: IF '(' EXP ')' STATEMENT_BODY ELSE STATEMENT_BODY
    {
        if ($3->type != UI_VAL)
        {
            yyerror("Expression type in if statement must be bool");
        }
    }
    |IF '(' EXP ')' STATEMENT_BODY
    {
        if ($3->type != UI_VAL)
        {
            yyerror("Expression type in if statement must be bool");
        }
    }
;

LOOP_STATEMENT: WHILE '(' EXP ')' STATEMENT_BODY
    {
        if ($3->type != UI_VAL)
        {
            yyerror("Expression type in while statement must be bool");
        }
    }
    |FOR '(' ID IN INT_CONS BETWEEN INT_CONS ')' 
    {
        symbol *id_val = search_id($3, *s);
        if (id_val == NULL)
        {
            yyerror("Use undefined ID!");
        }
        else
        {
            if (id_val->type == INT_VAL)
            {
                id_val->v.int4 = $5;
            }
            else
            {
                yyerror("Id in for loop must be int!");
            }
        }
    }
    STATEMENT_BODY
;

/*Statement body => function body or single staement */
STATEMENT_BODY: '{' 
    { 
        push(create_tb(), s);
    } 
    FUNC_BODY '}'
    {
        show_tb("End of staement");
        pop(s);
    }
    |STATEMENT
;

%%
int main(void)
{
    s = create_stack();
    while (yyparse())
    {
    }
    free(s);
    return 0;
}