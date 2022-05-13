#include "symbols.h"
symbol *create_sym(char *_n, int _type, value _v)
{
    symbol *temp = malloc(sizeof(symbol));
    temp->name = strdup(_n);
    temp->nptr = NULL;
    temp->pptr = NULL;
    switch (_type)
    {
    case UI_VAL:
        temp->type = UI_VAL;
        temp->v.sizet = _v.sizet;
        break;
    case INT_VAL:
        temp->type = INT_VAL;
        temp->v.int4 = _v.int4;
        break;
    case FP_VAL:
        temp->type = FP_VAL;
        temp->v.fp = _v.fp;
        break;
    case STR_VAL:
        temp->type = STR_VAL;
        temp->v.str = strdup(_v.str);
        break;
    case CLASS_DEC:
        temp->type = CLASS_DEC;
        temp->v.int4 = _v.int4;
        break;
    case FUNC_DEC:
        temp->type = FUNC_DEC;
        temp->v.int4 = _v.int4;
        break;
    case ARR_UI:
        temp->type = ARR_UI;
        temp->v.arr_ptr = _v.arr_ptr;
        break;
    case ARR_INT:
        temp->type = ARR_INT;
        temp->v.arr_ptr = _v.arr_ptr;
        break;
    case ARR_FP:
        temp->type = ARR_FP;
        temp->v.arr_ptr = _v.arr_ptr;
        break;
    case ARR_STR:
        temp->type = ARR_STR;
        temp->v.arr_ptr = _v.arr_ptr;
        break;
    default:
        break;
    }
    return temp;
}
symbol_table *create_tb()
{
    symbol_table *temp = malloc(sizeof(symbol_table));
    temp->begin = NULL;
    temp->nptr = NULL;
    temp->pptr = NULL;
    temp->size = 0;
    return temp;
}
/*Symbol Table*/
symbol *lookup(char *sym, symbol_table tb)
{
    symbol *temp_ptr = tb.begin;
    while (temp_ptr != NULL)
    {
        if (strcmp(sym, temp_ptr->name) == 0)
            return temp_ptr;
        temp_ptr = temp_ptr->nptr;
    }
    return NULL;
}

void insert(symbol *const sym, symbol_table *tb)
{
    symbol *temp_ptr = tb->begin;
    if (temp_ptr == NULL)
    {
        tb->begin = sym;
        tb->size += 1;
    }
    else
    {
        if (lookup(sym->name, *tb) != NULL)
        {
            return;
        }
        while (temp_ptr->nptr != NULL)
        {
            temp_ptr = temp_ptr->nptr;
        }
        sym->pptr = temp_ptr;
        sym->nptr = NULL;
        temp_ptr->nptr = sym;
        tb->size += 1;
    }
    return;
}

void dump(symbol_table *tb)
{
    symbol *temp_ptr = tb->begin;
    tb->begin = NULL;
    tb->size = 0;
    symbol *cur_ptr;
    while (temp_ptr != NULL)
    {
        cur_ptr = temp_ptr;
        temp_ptr = temp_ptr->nptr;
        free(cur_ptr);
    }
}
char *get_type_str(size_t _type)
{
    /*For print_tb*/
    switch (_type)
    {
    case 0:
        return "SIZE_T";
    case 1:
        return "INT";
    case 2:
        return "FLOAT";
    case 3:
        return "STRING";
    case 4:
        return "CLASS";
    case 5:
        return "FUNC";
    case 6:
        return "VOID";
    case 7:
        return "VOID";
    }
    return "";
}
void print_tb(symbol_table tb)
{
    printf("\nSymbol Table:\n");
    symbol *temp_ptr = tb.begin;
    printf("%-12s|%-10s|%-10s\n", "Name:", "Type:", "Value:");
    while (temp_ptr != NULL)
    {
        switch (temp_ptr->type)
        {
        case UI_VAL:
            printf("%-12s|%-10s|%-16zu\n", temp_ptr->name, "SIZE_T", temp_ptr->v.sizet);
            temp_ptr = temp_ptr->nptr;
            break;
        case INT_VAL:
            printf("%-12s|%-10s|%-16ld\n", temp_ptr->name, "INT", temp_ptr->v.int4);
            temp_ptr = temp_ptr->nptr;
            break;
        case FP_VAL:
            printf("%-12s|%-10s|%-16lf\n", temp_ptr->name, "FLOAT", temp_ptr->v.fp);
            temp_ptr = temp_ptr->nptr;
            break;
        case STR_VAL:
            printf("%-12s|%-10s|%-16s\n", temp_ptr->name, "STRING", temp_ptr->v.str);
            temp_ptr = temp_ptr->nptr;
            break;
        case CLASS_DEC:
            printf("%-12s|%-10s|%-16s\n", temp_ptr->name, "CLASS", get_type_str(temp_ptr->v.sizet));
            temp_ptr = temp_ptr->nptr;
            break;
        case FUNC_DEC:
            printf("%-12s|%-10s|%-16s|%-8lu\n", temp_ptr->name, "FUNC", get_type_str(temp_ptr->v.sizet), temp_ptr->argn);
            if (temp_ptr->argn > 0)
            {
                int i = 0;
                for (; i < temp_ptr->argn; i++)
                {
                    printf("%s:%s\t", temp_ptr->arg_name[i], get_type_str(temp_ptr->arg_type[i]));
                }
                printf("\n\n");
            }
            temp_ptr = temp_ptr->nptr;
            break;
        case ARR_UI:
            printf("%-12s|%-10s|%-16p\n", temp_ptr->name, "ARRAY_UI", temp_ptr->v.arr_ptr);
            temp_ptr = temp_ptr->nptr;
            break;
        case ARR_INT:
            printf("%-12s|%-10s|%-16p\n", temp_ptr->name, "ARRAY_INT", temp_ptr->v.arr_ptr);
            temp_ptr = temp_ptr->nptr;
            break;
        case ARR_FP:
            printf("%-12s|%-10s|%-16p\n", temp_ptr->name, "ARRAY_FP", temp_ptr->v.arr_ptr);
            temp_ptr = temp_ptr->nptr;
            break;
        case ARR_STR:
            printf("%-12s|%-10s|%-16p\n", temp_ptr->name, "ARRAY_STR", temp_ptr->v.arr_ptr);
            temp_ptr = temp_ptr->nptr;
            break;
        default:
            break;
        }
    }
}

/*Stack of symbol table*/
stack *create_stack()
{
    stack *temp = malloc(sizeof(stack));
    temp->top_ptr = NULL;
    return temp;
}

void pop(stack *const st)
{
    if (st->top_ptr == NULL)
    {
        return;
    }
    else
    {
        symbol_table *temp = st->top_ptr;
        st->top_ptr = temp->pptr;
        if (st->top_ptr != NULL)
            st->top_ptr->nptr = NULL;
        free(temp);
    }
}
void push(symbol_table *const tb, stack *const st)
{
    symbol_table *temp_ptr = st->top_ptr;
    if (temp_ptr == NULL)
    {
        st->top_ptr = tb;
    }
    else
    {
        while (temp_ptr->nptr != NULL)
        {
            temp_ptr = temp_ptr->nptr;
        }
        tb->pptr = temp_ptr;
        temp_ptr->nptr = tb;
        st->top_ptr = tb;
    }
}
symbol_table *top(const stack st)
{
    return st.top_ptr;
}
void print_stack(stack st)
{
    printf("\n=====Stack======");
    symbol_table *temp_ptr = st.top_ptr;
    while (temp_ptr != NULL)
    {
        print_tb(*temp_ptr);
        temp_ptr = temp_ptr->pptr;
    }
    printf("=====END======\n");
}
symbol *search_id(char *_n, stack st)
{
    symbol_table *temp_ptr = st.top_ptr;
    while (temp_ptr != NULL)
    {
        symbol *result = lookup(_n, *temp_ptr);
        if (result != NULL)
        {
            printf("Find %s\n", _n);
            return result;
        }
        temp_ptr = temp_ptr->pptr;
    }
    printf("%s not found\n", _n);
    return NULL;
}

void create_fun_arg_info(symbol *temp, symbol_table *arg_tb)
{
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
    // while (temp_ptr != NULL)
    // {
    // }
}
// int main()
// {
//     stack *s = create_stack();
//     value val;
//     // symbol_table *global = create_tb();
//     push(create_tb(), s);
//     val.int4 = -100;
//     insert(create_sym("id1", INT_VAL, val), top(*s));

//     val.sizet = 65000;
//     insert(create_sym("g_id2", UI_VAL, val), top(*s));

//     val.fp = 0.123;
//     insert(create_sym("g_id3", FP_VAL, val), top(*s));

//     val.str = strdup("global");
//     insert(create_sym("g_id4", STR_VAL, val), top(*s));

//     print_stack(*s);

//     symbol_table *sigma = create_tb();
//     push(sigma, s);
//     val.int4 = -2;
//     insert(create_sym("id1", INT_VAL, val), top(*s));

//     val.sizet = 87;
//     insert(create_sym("s_id2", UI_VAL, val), top(*s));

//     val.fp = 1.256;
//     insert(create_sym("s_id3", FP_VAL, val), top(*s));

//     val.str = strdup("sigma");
//     insert(create_sym("s_id4", STR_VAL, val), top(*s));

//     print_stack(*s);
//     symbol *sym;
//     sym = search_id("id1", *s);
//     if (sym->type == INT_VAL)
//     {
//         printf("%ld\n", sym->v.int4);
//     }

//     sym = search_id("s_id2", *s);
//     sym = search_id("g_id5", *s);
//     symbol_table *test_for = create_tb();
//     push(test_for, s);
//     val.int4 = -2;
//     insert(create_sym("l_id1", INT_VAL, val), top(*s));

//     val.sizet = 87;
//     insert(create_sym("l_id2", UI_VAL, val), top(*s));

//     val.fp = 1.256;
//     insert(create_sym("l_id3", FP_VAL, val), top(*s));

//     val.str = strdup("for loop");
//     insert(create_sym("l_id4", STR_VAL, val), top(*s));
//     print_stack(*s);
//     pop(s);
//     print_stack(*s);

//     symbol_table *fun = create_tb();
//     push(fun, s);
//     val.int4 = -2;
//     insert(create_sym("f_id1", INT_VAL, val), top(*s));

//     val.sizet = 87;
//     insert(create_sym("f_id2", UI_VAL, val), top(*s));

//     val.fp = 1.256;
//     insert(create_sym("f_id3", FP_VAL, val), top(*s));

//     val.str = strdup("fun");
//     insert(create_sym("f_id4", STR_VAL, val), top(*s));
//     print_stack(*s);
// }