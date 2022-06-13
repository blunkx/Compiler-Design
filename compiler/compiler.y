%{
#include <stdio.h>
#include "symbols.h"
#define show_stack 0
#define show_top 1
extern int yylex(void);
extern int get_line_num();
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

/*Global variables*/
stack *s;
value val;
int branch_num = 0;
int loop_begin[100];
int loop_stack_len = 0;

int tb_len;
int tb_index;
char *class_name;

/* Temp symbol is not free. */
/*Arg_tb is used for FUNC_ARG FUNC_ARGS FUNC_INV_ARG FUNC_INV_ARGS */
symbol_table *arg_tb;

FILE *java_byte_code;

void yyerror(char *_s)
{
    // dump stack to check error
    print_stack(*s);
    printf("Line %d | %s\n", get_line_num(), _s);
    fprintf(stderr, "Line %d | %s\n", get_line_num(), _s);
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

char *get_type(int _type)
{
    switch (_type)
    {
    case UI_VAL:
        //bool -> int
        return "int";
        break;
    case INT_VAL:
        return "int";
        break;
    case FP_VAL:
        return "float";
        break;
    case STR_VAL:
        return "string";
        break;
    case VOID_TYPE:
        return "void";
        break;
    default:
        return NULL;
    }
}

void var_dec(char *id_name, int _type, int _scope, int _init)
{
    switch (_type)
    {
    case UI_VAL:
        if (_scope == GLOBAL)
        {
            if (_init)
                val.sizet = 0;
            insert(add_sym_type_scope(create_sym(id_name, UI_VAL, val), VARIABLE, _scope), top(*s));
            fprintf(java_byte_code, "field static %s %s = %lu\n", get_type(_type), id_name, lookup(id_name, *top(*s))->v.sizet);
        }
        else if (_scope == LOCAL)
        {
            val.sizet = (top(*s)->index)++;
            insert(add_sym_type_scope(create_sym(id_name, UI_VAL, val), VARIABLE, _scope), top(*s));
            if (_init)
                fprintf(java_byte_code, "sipush %d\n", 0);
            fprintf(java_byte_code, "istore %ld\n", lookup(id_name, *top(*s))->v.sizet);
        }
        break;
    case INT_VAL:
        if (_scope == GLOBAL)
        {
            if (_init)
                val.int4 = 0;
            insert(add_sym_type_scope(create_sym(id_name, INT_VAL, val), VARIABLE, _scope), top(*s));
            fprintf(java_byte_code, "field static %s %s = %ld\n", get_type(_type), id_name, lookup(id_name, *top(*s))->v.int4);
        }
        else if (_scope == LOCAL)
        {
            val.int4 = (top(*s)->index)++;
            insert(add_sym_type_scope(create_sym(id_name, INT_VAL, val), VARIABLE, _scope), top(*s));
            if (_init)
                fprintf(java_byte_code, "sipush %d\n", 0);
            fprintf(java_byte_code, "istore %ld\n", lookup(id_name, *top(*s))->v.int4);
        }
        break;
    case FP_VAL:
        if (_scope == GLOBAL)
        {
            if (_init)
            {
                val.fp = 0.0;
                fprintf(java_byte_code, "field static %s %s\n", get_type(_type), id_name);
                insert(add_sym_type_scope(create_sym(id_name, FP_VAL, val), VARIABLE, _scope), top(*s));
            }
            else
            {
                yyerror("Not allow initial value for global float variable!");
                insert(add_sym_type_scope(create_sym(id_name, FP_VAL, val), VARIABLE, _scope), top(*s));
                fprintf(java_byte_code, "field static %s %s = %.1lf\n", get_type(_type), id_name, lookup(id_name, *top(*s))->v.fp);
            }
        }
        else if (_scope == LOCAL)
        {
            val.fp = (top(*s)->index)++;
            insert(add_sym_type_scope(create_sym(id_name, FP_VAL, val), VARIABLE, _scope), top(*s));
            if (_init)
                fprintf(java_byte_code, "fconst_0\n");
            else
                yyerror("Not allow initial value for local float variable!");
            fprintf(java_byte_code, "fstore %.0lf\n", lookup(id_name, *top(*s))->v.fp);
        }
        break;
    case STR_VAL:
        if (_scope == GLOBAL)
        {
            if (_init)
                val.str = strdup("");
            insert(add_sym_type_scope(create_sym(id_name, STR_VAL, val), VARIABLE, _scope), top(*s));
            fprintf(java_byte_code, "field static %s %s = %s string is unsupported!\n", get_type(_type), id_name, lookup(id_name, *top(*s))->v.str);
        }
        else if (_scope == LOCAL)
        {
            val.str = (char *)malloc(1024 * sizeof(char));
            sprintf(val.str, "%d", (top(*s)->index)++);
            insert(add_sym_type_scope(create_sym(id_name, STR_VAL, val), VARIABLE, _scope), top(*s));
            if (_init)
                fprintf(java_byte_code, "xx st sipush %s\n", "");
            fprintf(java_byte_code, "st var dec bc %s\n", lookup(id_name, *top(*s))->v.str);
        }
        break;
    default:
        yyerror("Invaild declaration");
        break;
    }
}

void exp_id(symbol *id_val)
{
    switch (id_val->symbol_type)
    {
    case VARIABLE:
        switch (id_val->scope)
        {
        case LOCAL:
            switch (id_val->type)
            {
            case UI_VAL:
                fprintf(java_byte_code, "iload %lu\n", id_val->v.sizet);
                break;
            case INT_VAL:
                fprintf(java_byte_code, "iload %ld\n", id_val->v.int4);
                break;
            case FP_VAL:
                fprintf(java_byte_code, "fload %.0lf\n", id_val->v.fp);
                break;
            case STR_VAL:
                fprintf(java_byte_code, "str var unsupported %s\n", id_val->v.str);
                break;
            default:
                yyerror("ID Type error!");
                break;
            }
            break;
        case GLOBAL:
            fprintf(java_byte_code, "getstatic %s %s.%s\n", get_type(id_val->type), class_name, id_val->name);
            break;
        default:
            yyerror("ID scope error!");
            break;
        }
        break;
    case CONST:
        switch (id_val->type)
        {
        case UI_VAL:
            fprintf(java_byte_code, "sipsuh %lu\n", id_val->v.sizet);
            break;
        case INT_VAL:
            fprintf(java_byte_code, "sipush %ld\n", id_val->v.int4);
            break;
        case FP_VAL:
            fprintf(java_byte_code, "fconst_1\n");
            // fprintf(java_byte_code, "fconst_1\n %lf fp is unsupported\n", id_val->v.fp);
            break;
        case STR_VAL:
            fprintf(java_byte_code, "ldc %s\n", id_val->v.str);
            break;
        default:
            yyerror("ID Type error!");
            break;
        }
        break;
    default:
        yyerror("ID Type error!");
        break;
    }
}

void print_cmp_op(int op)
{
    fprintf(java_byte_code, "isub\n");
    switch (op)
    {
    case L_E:
        fprintf(java_byte_code, "ifle L%d\n", branch_num);
        break;
    case G_E:
        fprintf(java_byte_code, "ifge L%d\n", branch_num);
        break;
    case E_Q:
        fprintf(java_byte_code, "ifeq L%d\n", branch_num);
        break;
    case N_E:
        fprintf(java_byte_code, "ifne L%d\n", branch_num);
        break;
    case G:
        fprintf(java_byte_code, "ifgt L%d\n", branch_num);
        break;
    case L:
        fprintf(java_byte_code, "iflt L%d\n", branch_num);
        break;
    default:
        yyerror("Boolean operator error!");
    }
    fprintf(java_byte_code, "iconst_0\n");
    fprintf(java_byte_code, "goto L%d\n", branch_num + 1);
    fprintf(java_byte_code, "L%d: iconst_1\n", branch_num++);
    fprintf(java_byte_code, "L%d:\n", branch_num++);
}

void id_assign(symbol *id_val)
{
    if (id_val->symbol_type == CONST)
    {
        yyerror("Constant assin not alllowed!");
    }
    else if (id_val->symbol_type == VARIABLE)
    {
        if (id_val->scope == GLOBAL)
        {
            fprintf(java_byte_code, "putstatic %s %s.%s\n", get_type(id_val->type), class_name, id_val->name);
        }
        else if (id_val->scope == LOCAL)
        {
            switch (id_val->type)
            {
            case UI_VAL:
                fprintf(java_byte_code, "istore %lu\n", id_val->v.sizet);
                break;
            case INT_VAL:
                fprintf(java_byte_code, "istore %ld\n", id_val->v.int4);
                break;
            case FP_VAL:
                fprintf(java_byte_code, "istore %lf\n fp is not supported", id_val->v.fp);
                break;
            case STR_VAL:
                fprintf(java_byte_code, "istore %s\n str is not supported", id_val->v.str);
                break;
            default:
                yyerror("Invaild assign!");
                break;
            }
        }
    }
}

void jbc_print(int _type, int _new_line)
{
    char *nl;
    nl = _new_line ? strdup("ln") : strdup("");
    switch (_type)
    {
    case UI_VAL:
        fprintf(java_byte_code, "invokevirtual void java.io.PrintStream.print%s(%s)\n", nl, get_type(_type));
        break;
    case INT_VAL:
        fprintf(java_byte_code, "invokevirtual void java.io.PrintStream.print%s(%s)\n", nl, get_type(_type));
        break;
    case FP_VAL:
        fprintf(java_byte_code, "invokevirtual void java.io.PrintStream.print%s(%s)\n", nl, get_type(_type));
        break;
    case STR_VAL:
        fprintf(java_byte_code, "invokevirtual void java.io.PrintStream.print%s(java.lang.String)\n", nl);
        break;
    default:
        yyerror("Print type error!");
        break;
    }
}

void func_inv(symbol *id_val)
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
            temp_ptr->name = strdup((id_val->arg_name)[i]);
            temp_ptr = temp_ptr->nptr;
        }
    }
    else
    {
        yyerror("Argument number not match!");
    }
    fprintf(java_byte_code, "invokestatic %s %s.%s(", get_type(id_val->v.sizet), class_name, id_val->name);
    int i = 0;
    for (; i < id_val->argn; i++)
    {
        if (i == arg_tb->size - 1)
        {
            fprintf(java_byte_code, "%s", get_type(id_val->arg_type[i]));
        }
        else
        {
            fprintf(java_byte_code, "%s, ", get_type(id_val->arg_type[i]));
        }
    }
    fprintf(java_byte_code, ")\n");
}
%}
%locations

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
%type<int4> TYPE FUN_RE_TYPE
%type<sym> EXP GLOBAL_CONS CONS TERM 

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
        class_name = strdup($2);
    } 
    '{' 
    { 
        fprintf(java_byte_code, "class %s\n{\n", $2);
        push(create_tb(), s);
    } 
    CLASS_BODY '}' 
    {
        fprintf(java_byte_code, "}");
        
        symbol *id_val = search_id("main", *s);
        if (id_val == NULL || id_val->type != FUNC_DEC)
        {
            yyerror("No main function in the class!");
        }
        show_tb("End of Class");
        pop(s);
    };

CLASS_BODY:
    |CLASS_BODY GLOBAL_CONS_DECLARATION 
    |CLASS_BODY GLOBAL_VAR_DECLARATION 
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

            fprintf(java_byte_code, "method public static %s %s(", get_type($7), $2);
            for (i = 0; i < arg_tb->size; i++)
            {
                if (i == arg_tb->size - 1)
                {
                    fprintf(java_byte_code, "%s", get_type(temp->arg_type[i]));
                }
                else
                {
                    fprintf(java_byte_code, "%s, ", get_type(temp->arg_type[i]));
                }
            }
            fprintf(java_byte_code, ")\nmax_stack 15\n");
            fprintf(java_byte_code, "max_locals 15\n{\n");

            arg_tb = NULL;
        }
        else
        {
            yyerror("Duplicate declaration!");
        }
    }
    FUNC_BODY '}'
    {
        if ($7 == VOID_TYPE)
            fprintf(java_byte_code, "return\n}\n");
        else
            fprintf(java_byte_code, "}\n");
        show_tb($2);
        pop(s);
    }
    |FUN MAIN '(' 
    {
        arg_tb = create_tb();
    }
    ')' FUN_RE_TYPE '{' 
    { 
        if (lookup("main", *top(*s)) == NULL)
        {
            val.sizet = $6;
            symbol *temp = create_sym("main", FUNC_DEC, val);
            temp->argn = arg_tb->size;
            insert(temp, top(*s));
            push(arg_tb, s);
            arg_tb = NULL;

            fprintf(java_byte_code, "method public static %s %s", get_type($6), "main");
            fprintf(java_byte_code, "(java.lang.String[])\n");
            fprintf(java_byte_code, "max_stack 15\n");
            fprintf(java_byte_code, "max_locals 15\n{\n");
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

        fprintf(java_byte_code, "return\n}\n");
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
                val.sizet = (arg_tb->index)++;
                insert(add_sym_type_scope(create_sym($1, UI_VAL, val), VARIABLE, LOCAL), arg_tb);
                break;
            case INT_VAL:
                val.int4 = (arg_tb->index)++;
                insert(add_sym_type_scope(create_sym($1, INT_VAL, val), VARIABLE, LOCAL), arg_tb);
                break;
            case FP_VAL:
                val.fp = (arg_tb->index)++;
                insert(add_sym_type_scope(create_sym($1, FP_VAL, val), VARIABLE, LOCAL), arg_tb);
                break;
            case STR_VAL:
                val.str = (char *)malloc(1024 * sizeof(char));
                sprintf(val.str, "%d", (arg_tb->index)++);
                insert(add_sym_type_scope(create_sym($1, STR_VAL, val), VARIABLE, LOCAL), arg_tb);
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
                val.sizet = (arg_tb->index)++;
                insert(add_sym_type_scope(create_sym($2, UI_VAL, val), VARIABLE, LOCAL), arg_tb);
                break;
            case INT_VAL:
                val.int4 = (arg_tb->index)++;
                insert(add_sym_type_scope(create_sym($2, INT_VAL, val), VARIABLE, LOCAL), arg_tb);
                break;
            case FP_VAL:
                val.fp = (arg_tb->index)++;
                insert(add_sym_type_scope(create_sym($2, FP_VAL, val), VARIABLE, LOCAL), arg_tb);
                break;
            case STR_VAL:
                val.str = (char *)malloc(1024 * sizeof(char));
                sprintf(val.str, "%d", (arg_tb->index)++);
                insert(add_sym_type_scope(create_sym($2, STR_VAL, val), VARIABLE, LOCAL), arg_tb);
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
        symbol *id_val = lookup($1, *top(*s));
        if (id_val == NULL)
        {
            id_val = search_id($1, *s);
            if (id_val == NULL || id_val->scope != GLOBAL)
                yyerror("Use undefined ID or Scope Error!");
            if (id_val->type == $3->type)
                id_assign(id_val);
            else
                yyerror("Assign type error!");
        }
        else
        {
            if (id_val->type == $3->type)
                id_assign(id_val);
            else
                yyerror("Assign type error!");  
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
    |PRINT
    {
        fprintf(java_byte_code, "getstatic java.io.PrintStream java.lang.System.out\n");
    }
    '(' EXP ')'
    {
        jbc_print($4->type, 0);
    }
    |PRINT 
    {
        fprintf(java_byte_code, "getstatic java.io.PrintStream java.lang.System.out\n");
    }
    EXP
    {
        jbc_print($3->type, 0);
    }
    |PRINTLN 
    {
        fprintf(java_byte_code, "getstatic java.io.PrintStream java.lang.System.out\n");
    }
    '(' EXP ')'
    {
        jbc_print($4->type, 1);
    }
    |PRINTLN
    {
        fprintf(java_byte_code, "getstatic java.io.PrintStream java.lang.System.out\n");
    }
    EXP
    {
        jbc_print($3->type, 1);
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
        fprintf(java_byte_code, "return\n");
    }
    |RETURN EXP
    {
        switch ($2->type)
        {
        case UI_VAL:
            fprintf(java_byte_code, "ireturn\n");
            break;
        case INT_VAL:
            fprintf(java_byte_code, "ireturn\n");
            break;
        case FP_VAL:
            fprintf(java_byte_code, "ireturn\n float is unsupported");
            break;
        case STR_VAL:
            fprintf(java_byte_code, "ireturn\n str is unsupported");
            break;
        default:
            yyerror("Print type error!");
            break;
        }
    }
    |COND_STATEMENT
    |LOOP_STATEMENT
    |ID '(' 
    {
        arg_tb = create_tb();
    }
    FUNC_INV_ARG ')'
    {
        symbol *id_val = search_id($1, *s);
        if (id_val == NULL)
        {
            yyerror("Use undefined FUNC ID!");
        }
        else if (id_val->type == FUNC_DEC)
        {
            if (id_val->v.sizet != VOID_TYPE)
            {
                yyerror("No catch for non void function!");
            }
            func_inv(id_val);
        }
        else
        {
            yyerror("Invalid function invocation!");
        }
        arg_tb = NULL;
    }
;

/*2.1*/
/* 
not handle if id name is equal to fun or class name!!! 
only check duplicate declaration in same scope
*/

/*==================GLOBAL==================*/
GLOBAL_CONS_DECLARATION: VAL ID '=' GLOBAL_CONS
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
                insert(add_sym_type_scope($4, CONST, GLOBAL), top(*s));
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
    |VAL ID ':' TYPE '=' GLOBAL_CONS
    {
        if (lookup($2, *top(*s)) == NULL)
        {
            if ($4 != $6->type)
            {
                yyerror("Declaration type error!");
            }
            $6->name = strdup($2);
            insert(add_sym_type_scope($6, CONST, GLOBAL), top(*s));
        }
        else
        {
            yyerror("Duplicate declaration!");
        }
    }
;

/*Without type the assigning value only accept float expression*/
GLOBAL_VAR_DECLARATION: VAR ID
    {
        if (lookup($2, *top(*s)) == NULL)
            var_dec($2, INT_VAL, GLOBAL, 1);
        else
            yyerror("Duplicate declaration!");
    }
    |VAR ID ':' TYPE
    {
        if (lookup($2, *top(*s)) == NULL)
            var_dec($2, $4, GLOBAL, 1);
        else
            yyerror("Duplicate declaration!");
    }
    |VAR ID '=' GLOBAL_CONS
    {
        if (lookup($2, *top(*s)) == NULL)
        {
            val = $4->v;
            var_dec($2, $4->type, GLOBAL, 0);
        }
        else
        {
            yyerror("Duplicate declaration!");
        }
    }
    |VAR ID ':' TYPE '=' GLOBAL_CONS
    {
        if (lookup($2, *top(*s)) == NULL)
        {
            if ($4 != $6->type)
                yyerror("Declaration type error!");
            val = $6->v;
            var_dec($2, $6->type, GLOBAL, 0);
        }
        else
        {
            yyerror("Duplicate declaration!");
        }   
    }
;

/*==================LOCAL==================*/
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
                insert(add_sym_type_scope($4, CONST, LOCAL), top(*s));
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
            insert(add_sym_type_scope($6, CONST, LOCAL), top(*s));
        }
        else
        {
            yyerror("Duplicate declaration!");
        }
    }
;

/*Without type the assigning value only accept float expression*/
VAR_DECLARATION: VAR ID
    {
        if (lookup($2, *top(*s)) == NULL)
            var_dec($2, INT_VAL, LOCAL, 1);
        else
            yyerror("Duplicate declaration!");
    }
    |VAR ID ':' TYPE
    {
        if (lookup($2, *top(*s)) == NULL)
            var_dec($2, $4, LOCAL, 1);
        else
            yyerror("Duplicate declaration!");
    }
    |VAR ID '=' EXP
    {
        if (lookup($2, *top(*s)) == NULL)
            var_dec($2, $4->type, LOCAL, 0);
        else
            yyerror("Duplicate declaration!");
    }
    |VAR ID ':' TYPE '=' EXP
    {
        if (lookup($2, *top(*s)) == NULL)
        {
            if ($4 != $6->type)
                yyerror("Declaration type not match!");
            var_dec($2, $6->type, LOCAL, 0);
        }
        else
            yyerror("Duplicate declaration!"); 
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

EXP: EXP '*' EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case INT_VAL:
                fprintf(java_byte_code, "imul\n");
                $$ = create_sym("temp", $1->type, $1->v);
                break;
            case FP_VAL:
                $$ = create_sym("temp", $1->type, $1->v);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |EXP '/' EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case INT_VAL:
                fprintf(java_byte_code, "idiv\n");
                $$ = create_sym("temp", $1->type, $1->v);
                break;
            case FP_VAL:
                $$ = create_sym("temp", $1->type, $1->v);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |EXP '+' EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case INT_VAL:
                fprintf(java_byte_code, "iadd\n");
                $$ = create_sym("temp", $1->type, $1->v);
                break;
            case FP_VAL:
                $$ = create_sym("temp", $1->type, $1->v);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |EXP '-' EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case INT_VAL:
                fprintf(java_byte_code, "isub\n");
                $$ = create_sym("temp", $1->type, $1->v);
                break;
            case FP_VAL:
                $$ = create_sym("temp", $1->type, $1->v);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |EXP LE EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case INT_VAL:
                print_cmp_op(L_E);
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            case FP_VAL:
                // Boolean exp return ture
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |EXP GE EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case INT_VAL:
                print_cmp_op(G_E);
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            case FP_VAL:
                // Boolean exp return ture
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |EXP EQ EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case INT_VAL:
                print_cmp_op(E_Q);
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            case FP_VAL:
                // Boolean exp return ture
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |EXP NEQ EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case INT_VAL:
                print_cmp_op(N_E);
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            case FP_VAL:
                // Boolean exp return ture
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |EXP '>' EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case INT_VAL:
                print_cmp_op(G);
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            case FP_VAL:
                // Boolean exp return ture
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |EXP '<' EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case INT_VAL:
                print_cmp_op(L);
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            case FP_VAL:
                // Boolean exp return ture
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |EXP '!' EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case UI_VAL:
                // Boolean exp return ture
                fprintf(java_byte_code, "ixor\n");
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |EXP '&' EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case UI_VAL:
                // Boolean exp return ture
                fprintf(java_byte_code, "iand\n");
                val.sizet = 1;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            default:
                yyerror("Invaild operation types");
                break;
            }
        }  
    }
    |EXP '|' EXP
    {
        if($1->type != $3->type)
            yyerror("Operation between different types");
        else
        {
            switch ($1->type)
            {
            case UI_VAL:
                fprintf(java_byte_code, "ior\n");
                // Boolean exp return ture
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
            fprintf(java_byte_code, "ineg\n");
            $$ = create_sym("temp", INT_VAL, $2->v);
            break;
        case FP_VAL:
            fprintf(java_byte_code, "fneg\n");
            $$ = create_sym("temp", FP_VAL, $2->v);
            break;
        default:
            yyerror("Invalid type for unary minus!");
            break;
        }
    } 
    |ID
    {
        symbol *id_val = lookup($1, *top(*s));
        if (id_val == NULL)
        {
            // Search global
            id_val = search_id($1, *s);
            if (id_val == NULL || id_val->scope != GLOBAL)
                yyerror("Use undefined ID or Scope Error!");
            $$ = create_sym(id_val->name, id_val->type, id_val->v);
            exp_id(id_val);
        }
        else
        {
            $$ = create_sym(id_val->name, id_val->type, id_val->v);
            exp_id(id_val);
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
            yyerror("Use undefined FUNC ID!");
        }
        else if (id_val->type == FUNC_DEC)
        {
            func_inv(id_val);
            /*return type*/
            switch (id_val->v.sizet)
            {
            case UI_VAL:
                val.sizet = 0;
                $$ = create_sym("temp", UI_VAL, val);
                break;
            case INT_VAL:
                val.int4 = 0;
                $$ = create_sym("temp", INT_VAL, val);
                break;
            case FP_VAL:
                val.fp = 0.0;
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

GLOBAL_CONS: INT_CONS
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

CONS: INT_CONS
    {
        fprintf(java_byte_code, "sipush %ld\n", $1);
        val.int4 = $1;
        $$ = create_sym("temp", INT_VAL, val);
    }
    |STR_CONS
    {
        fprintf(java_byte_code, "ldc %s\n", $1);
        val.str = strdup($1);
        $$ = create_sym("temp", STR_VAL, val);
    }
    |REAL_CONS
    {
        // fprintf(java_byte_code, "ldc %lf\n fp is unsupported!\n", $1);
        val.fp = $1;
        $$ = create_sym("temp", FP_VAL, val);
    }
    |BOOL_CONS 
    {
        fprintf(java_byte_code, "sipush %lu\n", $1);
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

COND_STATEMENT: IF '(' EXP ')'
    {
        if ($3->type != UI_VAL)
        {
            yyerror("Expression type in if statement must be bool");
        }
        fprintf(java_byte_code, "ifeq L%d\n", branch_num);
    }
    STATEMENT_BODY 
    {
        fprintf(java_byte_code, "goto L%d\n", branch_num + 1);
    }    
    ELSE
    {
        fprintf(java_byte_code, "L%d:\n", branch_num++);
    }
    STATEMENT_BODY
    {
        fprintf(java_byte_code, "L%d:\n", branch_num++);
    }
    /*
    |IF '(' EXP ')' STATEMENT_BODY
    {
        if ($3->type != UI_VAL)
        {
            yyerror("Expression type in if statement must be bool");
        }
    }
    */
;

LOOP_STATEMENT: WHILE 
    {
        loop_begin[loop_stack_len] = branch_num;
        loop_stack_len++;
        fprintf(java_byte_code, "\n\nL%d:\n", branch_num++);
    }
    '(' EXP ')' 
    {
        if ($4->type != UI_VAL)
        {
            yyerror("Expression type in while statement must be bool");
        }
        // fprintf(java_byte_code, "ifle L%d\n", branch_num);
        fprintf(java_byte_code, "loop_end_br %d\n", loop_stack_len);
    }
    STATEMENT_BODY
    {
        loop_stack_len--;
        fprintf(java_byte_code, "goto L%d\n", loop_begin[loop_stack_len]);
        fprintf(java_byte_code, "end_point %d L %d\n", loop_stack_len + 1, branch_num++);
        // fprintf(java_byte_code, "L%d:\n\n", branch_num++);

        fclose(java_byte_code);
        branch_restore();
        java_byte_code = fopen("output.jasm", "a+");
    }
    |FOR '(' ID IN INT_CONS BETWEEN INT_CONS ')'
    {
        fprintf(java_byte_code, "\nsipush %ld\n", $5);
        symbol *id_val = search_id($3, *s);
        if (id_val == NULL)
        {
            yyerror("Use undefined ID!");
        }
        else
        {
            if (id_val->type == INT_VAL)
            {
                if(id_val->scope == GLOBAL)
                {
                    fprintf(java_byte_code, "putstatic %s %s.%s\n", get_type(INT_VAL), class_name, $3);
                    loop_begin[loop_stack_len] = branch_num;
                    loop_stack_len++;
                    fprintf(java_byte_code, "L%d:\n", branch_num++);
                    fprintf(java_byte_code, "getstatic %s %s.%s\n", get_type(INT_VAL), class_name, $3);
                    fprintf(java_byte_code, "sipush %ld\n", $7);
                }
                else if(id_val->scope == LOCAL)
                {
                    fprintf(java_byte_code, "istore %ld\n", id_val->v.int4);
                    loop_begin[loop_stack_len] = branch_num;
                    loop_stack_len++;
                    fprintf(java_byte_code, "L%d:\n", branch_num++);
                    fprintf(java_byte_code, "iload %ld\n", id_val->v.int4);
                    fprintf(java_byte_code, "sipush %ld\n", $7);
                }
                fprintf(java_byte_code, "isub\n");
                fprintf(java_byte_code, "iflt L%d\n", branch_num);
                fprintf(java_byte_code, "iconst_0\n");
                fprintf(java_byte_code, "goto L%d\n", branch_num + 1);
                fprintf(java_byte_code, "L%d: iconst_1\n", branch_num++);
                fprintf(java_byte_code, "L%d:\n", branch_num++);
                // fprintf(java_byte_code, "ifle L%d\n", branch_num);
                fprintf(java_byte_code, "loop_end_br %d\n", loop_stack_len);
            }
            else
            {
                yyerror("Id in for loop must be int!");
            }
        }
    }
    STATEMENT_BODY
    {
        symbol *id_val = search_id($3, *s);
        if(id_val->scope == GLOBAL)
        {
            fprintf(java_byte_code, "getstatic %s %s.%s\n", get_type(INT_VAL), class_name, $3);
            fprintf(java_byte_code, "sipush 1\n");
            fprintf(java_byte_code, "iadd \n");
            fprintf(java_byte_code, "putstatic %s %s.%s\n", get_type(INT_VAL), class_name, $3);
        }
        else if(id_val->scope == LOCAL)
        {
            fprintf(java_byte_code, "iload %ld\n", id_val->v.int4);
            fprintf(java_byte_code, "sipush 1\n");
            fprintf(java_byte_code, "iadd \n");
            fprintf(java_byte_code, "istore %ld\n", id_val->v.int4);
        }
        loop_stack_len--;
        fprintf(java_byte_code, "goto L%d\n", loop_begin[loop_stack_len]);
        // fprintf(java_byte_code, "L%d:\n\n", branch_num++);
        fprintf(java_byte_code, "end_point %d L %d\n", loop_stack_len + 1, branch_num++);
        fclose(java_byte_code);
        branch_restore();
        java_byte_code = fopen("output.jasm", "a+");
    }
;

/*Statement body => function body or single staement */
STATEMENT_BODY: '{' 
    {
        tb_len = top(*s)->size;
        tb_index = top(*s)->index;
    }
    FUNC_BODY '}'
    {
        show_tb("End of staement");
        recover_table(top(*s), tb_len);
        top(*s)->index = tb_index;
    }
    |STATEMENT
;

%%
int main(void)
{
    s = create_stack();
    java_byte_code = fopen("output.jasm", "w");
    while (yyparse())
    {
    }
    free(s);
    fclose(java_byte_code);
    return 0;
}