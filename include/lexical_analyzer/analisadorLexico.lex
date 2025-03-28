%{
#include <stdio.h>

int numLines = 1; 
int numCols = 0;

enum Tokens {
  TOK_INT=360,
  TOK_FLOAT,
  TOK_STRING,
  TOK_BOOL,
  TOK_PROGRAM,
  TOK_BEGIN,
  TOK_END,
  TOK_VAR,
  TOK_IN,
  TOK_STRUCT,
  TOK_NOT,
  TOK_NULL,
  TOK_NEW,
  TOK_REF, 
  TOK_DEREF,
  TOK_TRUE, 
  TOK_FALSE,
  TOK_IF,
  TOK_THEN,
  TOK_ELSE,
  TOK_FI,
  TOK_WHILE,
  TOK_DO,
  TOK_OD,
  TOK_RETURN,
  TOK_ENUM,
  TOK_OF,
  TOK_AND,
  TOK_OR,
  TOK_COMP,
  TOK_ADD,
  TOK_SUB,
  TOK_MULT,
  TOK_DIV,
  TOK_POT,
  TOK_ATTRIBUTION,
  TOK_COLON,
  TOK_OPEN_PARENTHESIS,
  TOK_CLOSE_PARENTHESIS,
  TOK_SEMICOLON,
  TOK_COMMA,
  TOK_DOT,
  TOK_OPEN_BRACES,
  TOK_CLOSE_BRACES,
  TOK_SINGLE_LINE_COMMENT,
  TOK_MULTIPLE_LINE_COMMENT,
  NAME,
  INT_LITERAL,
  FLOAT_LITERAL,
  STRING_LITERAL,
  TOK_ERRO
};

%}

DIGIT [0-9]
LETTER [a-zA-Z]
WHITESPACE [ \t]
COMMENT_SL .*
COMMENT_ML [^("//")("(*")("*))]*

%%

\r\n|\r|\n                                                                   { numLines++;  numCols = 0; } 
int                                                                          {numCols += yyleng;printf("%s -> INT\n", yytext);}
float                                                                        {numCols += yyleng; printf("%s -> FLOAT\n", yytext);}
string                                                                       {numCols += yyleng; printf("%s -> STRING\n", yytext);}
bool                                                                         {numCols += yyleng; printf("%s -> BOOL\n", yytext);}
program                                                                      {numCols += yyleng; printf("%s -> PROGRAM\n", yytext);}
begin                                                                        {numCols += yyleng; printf("%s -> BEGIN\n", yytext);}
end                                                                          {numCols += yyleng; printf("%s -> END\n", yytext);}
var                                                                          {numCols += yyleng; printf("%s -> VAR\n", yytext);}
in                                                                           {numCols += yyleng; printf("%s -> IN\n", yytext);}
struct                                                                       {numCols += yyleng; printf("%s -> STRUCT\n", yytext);}
not                                                                          {numCols += yyleng; printf("%s -> NOT\n", yytext);}
null                                                                         {numCols += yyleng; printf("%s -> NULL\n", yytext);}
new                                                                          {numCols += yyleng; printf("%s -> NEW\n", yytext);}
ref                                                                          {numCols += yyleng; printf("%s -> REF\n", yytext);}
deref                                                                        {numCols += yyleng; printf("%s -> DEREF\n", yytext);}
true                                                                         {numCols += yyleng; printf("%s -> TRUE\n", yytext);}
false                                                                        {numCols += yyleng; printf("%s -> FALSE\n", yytext);}
if                                                                           {numCols += yyleng; printf("%s -> IF\n", yytext);}
then                                                                         {numCols += yyleng; printf("%s -> THEN\n", yytext);}
else                                                                         {numCols += yyleng; printf("%s -> ELSE\n", yytext);}
fi                                                                           {numCols += yyleng; printf("%s -> FI\n", yytext);}
while                                                                        {numCols += yyleng; printf("%s -> WHILE\n", yytext);}
do                                                                           {numCols += yyleng; printf("%s -> DO\n", yytext);}
od                                                                           {numCols += yyleng; printf("%s -> OD\n", yytext);}
return                                                                       {numCols += yyleng; printf("%s -> RETURN\n", yytext);}
enum                                                                         {numCols += yyleng; printf("%s -> ENUM\n", yytext);}
of                                                                           {numCols += yyleng; printf("%s -> OF\n", yytext);}
"&&"                                                                         {numCols += yyleng; printf("%s -> AND\n", yytext);}
"||"                                                                         {numCols += yyleng; printf("%s -> OR\n", yytext);}
"<"|"<="|">"|">="|"="|"<>"                                                   {numCols += yyleng; printf("%s -> COMP\n", yytext);} 
"+"                                                                          {numCols += yyleng; printf("%s -> ADD\n", yytext);}                                                                      
"-"                                                                          {numCols += yyleng; printf("%s -> SUB\n", yytext);}
"*"                                                                          {numCols += yyleng; printf("%s -> MULT\n", yytext);}
"/"                                                                          {numCols += yyleng; printf("%s -> DIV\n", yytext);}
"^"                                                                          {numCols += yyleng; printf("%s -> POT\n", yytext);}
":="                                                                         {numCols += yyleng; printf("%s -> ATTRIBUTION\n", yytext);}
":"                                                                          {numCols += yyleng; printf("%s -> COLON\n", yytext);}
"("                                                                          {numCols += yyleng; printf("%s -> OPEN_PARENTHESIS\n", yytext);}
")"                                                                          {numCols += yyleng; printf("%s -> CLOSE_PARENTHESIS\n", yytext);}
";"                                                                          {numCols += yyleng; printf("%s -> SEMICOLON\n", yytext);}
","                                                                          {numCols += yyleng; printf("%s -> COMMA\n", yytext);}
"."                                                                          {numCols += yyleng; printf("%s -> DOT\n", yytext);}
"{"                                                                          {numCols += yyleng; printf("%s -> OPEN_BRACES\n", yytext);}
"}"                                                                          {numCols += yyleng; printf("%s -> CLOSE_BRACES\n", yytext);}
"//"{COMMENT_SL}                                                             {numCols += yyleng; printf("%s -> SINGLE_LINE_COMMENT \n", yytext);}
"(*"{COMMENT_ML}"*)"                                                         {numCols += yyleng; printf("%s -> MULTIPLE_LINE_COMMENT \n", yytext);}
{LETTER}((({LETTER}|{DIGIT}|_)*_({LETTER}|{DIGIT})+)|({LETTER}|{DIGIT})*)    {numCols += yyleng; printf("%s -> NAME\n", yytext);}
{DIGIT}+                                                                     {numCols += yyleng; printf("%s -> INT_LITERAL\n", yytext);}
{DIGIT}+("."{DIGIT}+)?(e(-|"+")?{DIGIT}+)?                                   {numCols += yyleng; printf("%s -> FLOAT_LITERAL\n", yytext);}
\"[^\n\r\t"]*\"                                                              {numCols += yyleng; printf("%s -> STRING_LITERAL\n", yytext);}
{WHITESPACE}                                                                 {numCols += yyleng;} 
.                                                                            {numCols += yyleng; return TOK_ERRO;}

%%


int main(){
  if(yylex() == TOK_ERRO){
    printf("Erro na linha %d e coluna %d\n", numLines, numCols);
  }
  return 0;
}
