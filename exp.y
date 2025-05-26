%{
#include <stdio.h>

int yylex();
void yyerror(const char *s);
%}

%token NAME
%left PLUS

%%

input:
    /* aceita várias expressões, até EOF */
    | input exp '\n' { printf("Parsing completed.\n"); }
    ;


exp:
    exp PLUS exp { printf("Matched: Exp + Exp\n"); }
    | NAME       { printf("Matched: NAME\n"); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
