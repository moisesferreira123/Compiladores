%{
#include <stdio.h>


int numLines = 1; 
int numCols = 1; 
int tokenValue = 256; // Valor inicial para os tokens

int getNumLines() {
  return numLines;
}

int getNumCols() {
  return numCols;
}

int getTokenValue() {
  return tokenValue;
}
%}

DIGIT [0-9]
LETTER [a-zA-Z]
WHITESPACE [ \t]+
COMMENT_SL .*
COMMENT_ML [^("//")("(*")("*))]*

%%

{WHITESPACE}     { numCols += yyleng; }  

\r\n|\r|\n    { numLines++;  numCols = 1; } 


int                                                                          {printf("%s -> INT (%d)\n", yytext, tokenValue++); numCols += yyleng;}
float                                                                        {printf("%s -> FLOAT (%d)\n", yytext, tokenValue++); numCols += yyleng;}
string                                                                       {printf("%s -> STRING (%d)\n", yytext, tokenValue++); numCols += yyleng;}
bool                                                                         {printf("%s -> BOOL (%d)\n", yytext, tokenValue++); numCols += yyleng;}
program                                                                      {printf("%s -> PROGRAM (%d)\n", yytext, tokenValue++); numCols += yyleng;}
begin                                                                        {printf("%s -> BEGIN (%d)\n", yytext, tokenValue++); numCols += yyleng;}
end                                                                          {printf("%s -> END (%d)\n", yytext, tokenValue++); numCols += yyleng;}
var                                                                          {printf("%s -> VAR (%d)\n", yytext, tokenValue++); numCols += yyleng;}
in                                                                           {printf("%s -> IN (%d)\n", yytext, tokenValue++); numCols += yyleng;}
struct                                                                       {printf("%s -> STRUCT (%d)\n", yytext, tokenValue++); numCols += yyleng;}
not                                                                          {printf("%s -> NOT (%d)\n", yytext, tokenValue++); numCols += yyleng;}
null                                                                         {printf("%s -> NULL (%d)\n", yytext, tokenValue++); numCols += yyleng;}
new                                                                          {printf("%s -> NEW (%d)\n", yytext, tokenValue++); numCols += yyleng;}

"&&"                                                                         {printf("%s -> AND (%d)\n", yytext, tokenValue++); numCols += yyleng;}
"||"                                                                         {printf("%s -> OR (%d)\n", yytext, tokenValue++); numCols += yyleng;}
"<"|"<="|">"|">="|"="|"<>"                                                   {printf("%s -> COMP (%d)\n", yytext, tokenValue++); numCols += yyleng;} 
"+"                                                                          {printf("%s -> ADD (%d)\n", yytext, tokenValue++); numCols += yyleng;}                                                                      
"-"                                                                          {printf("%s -> SUB (%d)\n", yytext, tokenValue++); numCols += yyleng;}
"*"                                                                          {printf("%s -> MULT (%d)\n", yytext, tokenValue++); numCols += yyleng;}
"/"                                                                          {printf("%s -> DIV (%d)\n", yytext, tokenValue++); numCols += yyleng;}

"//"{COMMENT_SL}                                                             {printf("%s -> SINGLE_LINE_COMMENT (%d)\n", yytext, tokenValue++); numCols += yyleng;}
"(*"{COMMENT_ML}"*)"                                                         {printf("%s -> MULTIPLE_LINE_COMMENT (%d)\n", yytext, tokenValue++); numCols += yyleng;}
{LETTER}((({LETTER}|{DIGIT}|_)*_({LETTER}|{DIGIT})+)|({LETTER}|{DIGIT})*)    {printf("%s -> NAME (%d)\n", yytext, tokenValue++); numCols += yyleng;}
{DIGIT}+                                                                     {printf("%s -> INT_LITERAL (%d)\n", yytext, tokenValue++); numCols += yyleng;}
{DIGIT}+("."{DIGIT}+)?(e(-|"+")?{DIGIT}+)?                                   {printf("%s -> FLOAT_LITERAL (%d)\n", yytext, tokenValue++); numCols += yyleng;}
\"[^\n\r\t"]*\"                                                              {printf("%s -> STRING_LITERAL (%d)\n", yytext, tokenValue++); numCols += yyleng;}

.                                                                            {printf("%s -> ERRO (%d)\n", yytext, tokenValue++); numCols += yyleng;}

%%


int main(){
  yylex();
  printf("N\u00FAmero total de linhas: %d\n", getNumLines());
  printf("N\u00FAmero de colunas: %d\n", getNumCols());
  printf("Valor atual do token: %d\n", getTokenValue());
  return 0;
}
