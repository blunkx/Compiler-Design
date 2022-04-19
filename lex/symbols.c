#include "symbols.h"
#define copy_str(des, src)                        \
    {                                             \
        des = malloc(sizeof(char) * strlen(src)); \
        des = strcpy(des, src);                   \
    }
symbol_table create()
{
    symbol_table temp;
    temp.begin = NULL;
    temp.size = 0;
    return temp;
}
int lookup(char *sym, symbol_table tb)
{
    int index = 0;
    symbol *temp_ptr = tb.begin;
    while (temp_ptr != NULL)
    {
        if (strcmp(sym, temp_ptr->name) != 0)
        {
            index += 1;
        }
        else
            return index;
        temp_ptr = temp_ptr->nptr;
    }
    return -1;
}
int insert(char *_n, char *_type, char *_scope, symbol_table *tb)
{
    symbol *temp_ptr = tb->begin;
    if (temp_ptr == NULL)
    {
        symbol *temp = malloc(sizeof(symbol));
        copy_str(temp->name, _n);
        copy_str(temp->type, _type);
        copy_str(temp->scope, _scope);
        temp->pptr = NULL;
        temp->nptr = NULL;
        tb->begin = temp;
        tb->size += 1;
    }
    else
    {
        if (lookup(_n, *tb) != -1)
        {
            return 0;
        }
        while (temp_ptr->nptr != NULL)
        {
            temp_ptr = temp_ptr->nptr;
        }
        symbol *temp = malloc(sizeof(symbol));
        copy_str(temp->name, _n);
        copy_str(temp->type, _type);
        copy_str(temp->scope, _scope);
        temp->pptr = temp_ptr;
        temp->nptr = NULL;
        temp_ptr->nptr = temp;
        tb->size += 1;
    }
    return 0;
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
void print_tb(symbol_table tb)
{
    printf("\nSymbol Table:\n");
    symbol *temp_ptr = tb.begin;
    printf("%-12s|%-10s|%-10s\n", "Name:", "Type:", "Scope:");
    while (temp_ptr != NULL)
    {
        printf("%-12s|%-10s|%-10s\n", temp_ptr->name, temp_ptr->type, temp_ptr->scope);
        temp_ptr = temp_ptr->nptr;
    }
}