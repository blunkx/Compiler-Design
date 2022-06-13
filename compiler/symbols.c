#include "symbols.h"
symbol *create_sym(char *_n, int _type, value _v)
{
    symbol *temp = malloc(sizeof(symbol));
    temp->name = strdup(_n);
    temp->nptr = NULL;
    temp->pptr = NULL;
    temp->symbol_type = -1;
    temp->scope = -1;
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

symbol *add_sym_type_scope(symbol *temp, int _sym_type, int _scope)
{
    temp->symbol_type = _sym_type;
    temp->scope = _scope;
    return temp;
}

symbol_table *create_tb()
{
    symbol_table *temp = malloc(sizeof(symbol_table));
    temp->begin = NULL;
    temp->nptr = NULL;
    temp->pptr = NULL;
    temp->size = 0;
    temp->index = 0;
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

void insert_dup(symbol *const sym, symbol_table *tb)
{
    symbol *temp_ptr = tb->begin;
    if (temp_ptr == NULL)
    {
        tb->begin = sym;
        tb->size += 1;
    }
    else
    {
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

char *get_scope(int _scope)
{
    switch (_scope)
    {
    case LOCAL:
        return "LOCAL";
        break;
    case GLOBAL:
        return "GLOBAL";
        break;
    default:
        return "Pending";
        break;
    }
}

char *get_sym_type(int _type)
{
    switch (_type)
    {
    case VARIABLE:
        return "VAR";
        break;
    case CONST:
        return "CONST";
        break;
    default:
        return "Pending";
        break;
    }
}

void print_tb(symbol_table tb, char *msg)
{
    printf("\nSymbol Table: %s\n", msg);
    symbol *temp_ptr = tb.begin;
    printf("%-12s|%-10s|%-10s\n", "Name:", "Type:", "Value:");
    while (temp_ptr != NULL)
    {
        switch (temp_ptr->type)
        {
        case UI_VAL:
            printf("%-12s|%-10s|%-16zu", temp_ptr->name, "SIZE_T", temp_ptr->v.sizet);
            printf("|%-8s|%-8s\n", get_sym_type(temp_ptr->symbol_type), get_scope(temp_ptr->scope));
            temp_ptr = temp_ptr->nptr;
            break;
        case INT_VAL:
            printf("%-12s|%-10s|%-16ld", temp_ptr->name, "INT", temp_ptr->v.sizet);
            printf("|%-8s|%-8s\n", get_sym_type(temp_ptr->symbol_type), get_scope(temp_ptr->scope));
            temp_ptr = temp_ptr->nptr;
            break;
        case FP_VAL:
            printf("%-12s|%-10s|%-16lf", temp_ptr->name, "FLOAT", temp_ptr->v.fp);
            printf("|%-8s|%-8s\n", get_sym_type(temp_ptr->symbol_type), get_scope(temp_ptr->scope));
            temp_ptr = temp_ptr->nptr;
            break;
        case STR_VAL:
            printf("%-12s|%-10s|%-16s", temp_ptr->name, "STRING", temp_ptr->v.str);
            printf("|%-8s|%-8s\n", get_sym_type(temp_ptr->symbol_type), get_scope(temp_ptr->scope));
            temp_ptr = temp_ptr->nptr;
            break;
        case CLASS_DEC:
            printf("%-12s|%-10s|%-16s\n", temp_ptr->name, "CLASS", get_type_str(temp_ptr->v.sizet));
            temp_ptr = temp_ptr->nptr;
            break;
        case FUNC_DEC:
            printf("%-12s|%-10s|%-16s|%-8lu", temp_ptr->name, "FUNC", get_type_str(temp_ptr->v.sizet), temp_ptr->argn);
            if (temp_ptr->argn > 0)
            {
                printf("|");
                int i = 0;
                for (i = temp_ptr->argn - 1; i >= 0; i--)
                {
                    printf("%s:%s  ", temp_ptr->arg_name[i], get_type_str(temp_ptr->arg_type[i]));
                }
            }
            printf("\n");
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
        print_tb(*temp_ptr, "");
        temp_ptr = temp_ptr->pptr;
    }
    printf("=====END======\n\n\n");
}
symbol *search_id(char *_n, stack st)
{
    symbol_table *temp_ptr = st.top_ptr;
    while (temp_ptr != NULL)
    {
        symbol *result = lookup(_n, *temp_ptr);
        if (result != NULL)
        {
            return result;
        }
        temp_ptr = temp_ptr->pptr;
    }
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
}

void recover_table(symbol_table *tb, int len)
{
    if (len == 0)
    {
        tb->begin = NULL;
        return;
    }
    int i = 0;
    symbol *temp_ptr = tb->begin;
    for (; i < len; i++)
    {
        if (i == len - 1)
            temp_ptr->nptr = NULL;
        else
            temp_ptr = temp_ptr->nptr;
    }
    tb->size = len;
}

void branch_restore()
{
    FILE *old_file;
    FILE *output;
    char mystring[1024];
    int arr[1024];
    int len = 0;
    for (; len < 1024; len++)
    {
        arr[len] = -1;
    }
    int loop_index = 0;
    old_file = fopen("output.jasm", "r");
    if (old_file == NULL)
        perror("Error opening file");
    else
    {
        while (fgets(mystring, 1024, old_file) != NULL)
        {
            if (strstr(mystring, "end_point") != NULL)
            {
                int i;
                int j;
                sscanf(mystring, "%*s%d%*s%d", &i, &j);
                printf("%d %d\n", i, j);
                arr[i] = j;
            }
        }
        fclose(old_file);
    }
    old_file = fopen("output.jasm", "r");
    output = fopen("copy.txt", "w");
    if (old_file == NULL || output == NULL)
        perror("Error opening file");
    else
    {
        while (fgets(mystring, 1024, old_file) != NULL)
        {
            fprintf(output, "%s", mystring);
        }
        fclose(output);
        fclose(old_file);
    }

    old_file = fopen("copy.txt", "r");
    output = fopen("output.jasm", "w");
    if (old_file == NULL || output == NULL)
        perror("Error opening file");
    else
    {
        while (fgets(mystring, 1024, old_file) != NULL)
        {
            if (strstr(mystring, "loop_end_br") != NULL)
            {
                int i;
                sscanf(mystring, "%*s%d", &i);
                printf("%d\n", i);
                if (arr[i] != -1)
                {
                    fprintf(output, "ifle L%d\n", arr[i]);
                }
                else
                {
                    fprintf(output, "%s", mystring);
                }
            }
            else if (strstr(mystring, "end_point") != NULL)
            {
                int i;
                int j;
                sscanf(mystring, "%*s%d%*s%d", &i, &j);
                fprintf(output, "L%d:\n", j);
            }
            else
            {
                fprintf(output, "%s", mystring);
            }
        }
        fclose(old_file);
        fclose(output);
    }
}