%{

%}
bin_digit [01]
any .
%%
[01]* {
printf("BINARY: %s\n", yytext);
}

{any}*\n {
printf("any words with new line: %s\n", yytext);
}

{any}* {
printf("any words without new line: %s\n", yytext);
}



%%