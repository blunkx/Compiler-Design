%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "symbols.h"
#include "y.tab.h"

char *str_preprocess(char *inp_)
{
    /*
    Remove the first and last double quotes which wrap a string.
    Then, replace all two consecutive double quotes in the string with one double quote.
    */
    char *inp = NULL;
    inp = strdup(inp_);
    // if (inp[0] == '\"' && inp[strlen(inp) - 1] == '\"')
    // {
    //     inp[strlen(inp) - 1] = '\0';
    //     inp++;
    // }
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

int get_line_num()
{
    return yylineno;
}
%}

%option yylineno

space [ \t]
single_delimiters [,:;\(\)\[\]\{\}]
single_operators "+"|"-"|"*"|"/"|"%"|"<"|">"|"&"|"|"|"!"|"="
id [a-zA-Z_][a-zA-Z0-9_]*
int_constants 0|-?[1-9][0-9]*
boolean_constants true|false
real_constants (0|-?[1-9][0-9]*)("."[0-9]+)?([E|e][-+]?[0-9]+)?
string_constants \"(\"\"|[^"])*\"
single_line_cmt "//".*
%x comment

%%

"/*" { BEGIN(comment); }

<comment>\n  {} 

<comment>[^*\n]* {} 

<comment>"*"+[^*/\n]* {}   
 
<comment>"*"+"/" {
    BEGIN(INITIAL);
}

{single_delimiters} { return yytext[0]; }
"->" { return ARROW; }

{single_operators} { return yytext[0]; }
"<=" { return LE; }
">=" { return GE; }
"==" { return EQ; }
"!=" { return NEQ; }
"+=" { return EQ_ADD; }
"-=" { return EQ_MIN; }
"*=" { return EQ_MUL; }
"/=" { return EQ_DIV; }

"bool" {
    yylval.int4 = UI_VAL;
    return BOOL;
}
"break" { return BREAK; }
"char" { return CHAR; }
"case" { return CASE; }
"class" { return CLASS; }
"continue" { return CONTINUE; }
"declare" { return DECLARE; }
"do" { return DO; }
"else" { return ELSE; }
"exit" { return EXIT; }
"float" {
    yylval.int4 = FP_VAL;
    return FLOAT;
}
"for" { return FOR; }
"fun" { return FUN; }
"if" { return IF; }
"int" { 
    yylval.int4 = INT_VAL;
    return INT; 
}
"loop" { return LOOP; }
"print" { return PRINT; }
"println" { return PRINTLN; }
"return" { return RETURN; }
"string" {
    yylval.int4 = STR_VAL;
    return STRING;
}
"var" { return VAR; }
"val" { return VAL; }
"while" { return WHILE; }

"main" { return MAIN; }
"read" { return READ; }
"in" { return IN; }
"\.\." { return BETWEEN; }

{int_constants} {
    char *ptr_end;
    yylval.int4 = strtol(yytext, &ptr_end, 10);
    return yylval.sizet >= 0 ? INT_CONS : 0;
}

{boolean_constants} {
    yylval.sizet = strcmp(yytext, "true") == 0 ? 1 : 0;
    return BOOL_CONS;
}

{real_constants} {
    yylval.fp = atof(yytext);
    return REAL_CONS;
}

{string_constants} {
    char *temp = str_preprocess(yytext);
    yylval.str = temp;
    return STR_CONS;
}

{id} {
    yylval.str = strdup(yytext);
    return ID;
}

{space} {}

{single_line_cmt} {}

"\n" {}

<<EOF>> { return 0; }

%%
