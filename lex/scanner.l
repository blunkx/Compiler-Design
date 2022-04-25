%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "symbols.h"

#define MAX_LINE_LENG 1024
#define ADD_BUF strcat(buf, yytext);
#define CLEAR_BUF memset(buf, 0, sizeof(buf));
#define PRINT_LINE printf("%d: %s\n", line_num, buf);
#define TO_UPPER(string, len)               \
    do                                      \
    {                                       \
        for (int i = 0; i < len; i++)       \
            string[i] = toupper(string[i]); \
    } while (0)
/*delimiters and operators*/
#define token(t)               \
    {                          \
        ADD_BUF;               \
        printf("<'%s'>\n", t); \
    }
/*all keywords*/
#define tokenKw(t)           \
    {                        \
        ADD_BUF;             \
        TO_UPPER(t, yyleng); \
        printf("<%s>\n", t); \
    }
/*all identiers*/
#define tokenId(t)               \
    {                            \
        ADD_BUF;                 \
        printf("<id: %s>\n", t); \
    }
/*all constants*/
#define tokenConstant(type, token)        \
    {                                     \
        ADD_BUF;                          \
        printf("<%s:%s>\n", type, token); \
    }

int line_num = 1;
char buf[MAX_LINE_LENG];
symbol_table sym_tb;
/*
Remove the first and last double quotes which wrap a string.
Then, replace all two consecutive double quotes in the string with one double quote.
*/
char *str_preprocess(char *inp_)
{
    char *inp = NULL;
    copy_str(inp, inp_);
    if (inp[0] == '\"' && inp[strlen(inp) - 1] == '\"')
    {
        inp[strlen(inp) - 1] = '\0';
        inp++;
    }
    char *result;
    char *ins = inp;
    char *temp;
    size_t len_rep = strlen("\"\"");
    size_t len_with = strlen("\"");
    size_t len_front;
    size_t count;
    if (!inp)
        return NULL;
    count = 0;
    while ((temp = strstr(ins, "\"\"")) != NULL)
    {
        ins = temp + len_rep;
        ++count;
    }
    temp = result = malloc(strlen(inp) + (len_with - len_rep) * count + 1);
    if (!result)
        return NULL;
    while (count--)
    {
        ins = strstr(inp, "\"\"");
        len_front = ins - inp;
        temp = strncpy(temp, inp, len_front) + len_front;
        temp = strcpy(temp, "\"") + len_with;
        inp += len_front + len_rep;
    }
    strcpy(temp, inp);
    return result;
}
%}

space [ \t]

delimiters [,:;\(\)\[\]\{\}]|->
operators "+"|"-"|"*"|"/"|"%"|"<"|"<="|">="|">"|"!="|"&"|"|"|"!"|"="|"+="|"-="|"*="|"/="
keywords bool|break|char|case|class|continue|declare|do|else|exit|float|for|fun|if|int|loop|print|println|return|string|val|var|while
id  [a-zA-Z_][a-zA-Z0-9_]*

int_constants 0|[1-9][0-9]*
boolean_constants true|false
real_constants [+-]?(0|[1-9][0-9]*)("."[0-9]+)?([E|e][-+]?[0-9]+)?
string_constants \"(\"\"|[^"])*\"



single_line_cmt "//".*
%x  comment

%%

"/*" {
    BEGIN(comment);
    ADD_BUF ;
}/*start cmt*/

<comment>\n  {
    PRINT_LINE;
    CLEAR_BUF;
    ++line_num;
} 

<comment>[^*\n]* {
    ADD_BUF;
} 

<comment>"*"+[^*/\n]*   {
    ADD_BUF;
}   
 
<comment>"*"+"/" {
    ADD_BUF;
    BEGIN(INITIAL);
}/*back to init*/


{delimiters} {
    token(yytext);
}

{operators} {
    token(yytext);
}

{keywords} {
    tokenKw(yytext);
}

{int_constants} {
    tokenConstant("integer",yytext);
}

{boolean_constants} {
    tokenConstant("boolean",yytext);
}

{real_constants} {
    tokenConstant("real",yytext);
}

{string_constants} {
    char *temp = str_preprocess(yytext);
    tokenConstant("string",temp);
}

{id} {
    tokenId(yytext);
    insert(yytext, "pending", "pending", &sym_tb);
}

{space} {
    ADD_BUF;
}/*discard*/

{single_line_cmt} {
    ADD_BUF;
}/*discard*/

"\n" {
    PRINT_LINE;
    CLEAR_BUF;
    ++line_num;
}

<<EOF>> {
    PRINT_LINE;
    CLEAR_BUF;
    return 0;
}

%%
int main(int argc, char *argv[])
{
    sym_tb = create();
    while (yylex())
        ;
    print_tb(sym_tb);
}