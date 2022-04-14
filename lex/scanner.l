%{
#include <stdio.h>
#include <stdlib.h>
int line_num = 1;
char temp_str[1024];
int temp_str_len = 0;
%}

space [ \t]
delimiters [,:;\(\)\[\]\{\}]|->
operators "+"|"-"|"*"|"/"|"%"|"<"|"<="|">="|">"|"!="|"&"|"|"|"!"|"="|"+="|"-="|"*="|"/="
keywords bool|break|char|case|class|continue|declare|do|else|exit|false|float|for|fun|if|int|loop|print|println|return|string|true|val|var|while
id  [a-zA-Z_][a-zA-Z0-9_]*
/* (\"\") => ""  */
constants [1-9][0-9]*
string_constants \"(\"\"|[^"])*\"
single_line_cmt "//".*
%x  comment

%%

"/*" {
    BEGIN(comment);
    strcat(temp_str,yytext);
}/*start cmt*/

<comment>\n  {
    printf("%d:c %s\n",line_num,temp_str);
    memset(temp_str, 0, sizeof(temp_str));
    ++line_num;
} 

<comment>[^*\n]* {
    strcat(temp_str,yytext);
} 

<comment>"*"+[^*/\n]*   {
    strcat(temp_str,yytext);
}   
 
<comment>"*"+"/" {
    strcat(temp_str,yytext);
    BEGIN(INITIAL);
}/*back to init*/


{delimiters} {
    strcat(temp_str,yytext);
    printf("<\'%s\'>\n",yytext);
}

{operators} {
    strcat(temp_str,yytext);
    printf("op<\'%s\'>\n",yytext);
}

{keywords} {
    strcat(temp_str,yytext);
    printf("<\'%s\'>\n",yytext);
}

{id} {
    printf("<id: %s>\n",yytext);
}/* */

{constants} {
    strcat(temp_str,yytext);
    printf("cons<%s>\n",yytext);
}

{string_constants} {
    strcat(temp_str,yytext);
    // yytext+=1;
    printf("str<%s>\n",yytext);
}

{space} {
    
}/*discard*/

{single_line_cmt} {

}

"\n" {
    printf("%d:b %s\n",line_num,temp_str);
    memset(temp_str, 0, sizeof(temp_str));
    ++line_num;
}

<<EOF>> {
    printf("%d:eof %s",line_num,temp_str);
    return 0;
}

%%
int main(int argc, char *argv[]) {
    while(yylex()){
        
    }
}