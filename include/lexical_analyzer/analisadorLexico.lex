%{
#include <iostream>
#include "../symbol_table/SymbolTableTemporary.hpp"

int numLines = 1; 
int numCols = 0;
SymbolTableTemporary table;

enum Tokens {
  TOKEN_INT=360,
  TOKEN_FLOAT,
  TOKEN_STRING,
  TOKEN_BOOL,
  TOKEN_PROGRAM,
  TOKEN_PROCEDURE,
  TOKEN_BEGIN,
  TOKEN_END,
  TOKEN_VAR,
  TOKEN_IN,
  TOKEN_STRUCT,
  TOKEN_NOT,
  TOKEN_NULL,
  TOKEN_NEW,
  TOKEN_REF, 
  TOKEN_DEREF,
  TOKEN_TRUE, 
  TOKEN_FALSE,
  TOKEN_IF,
  TOKEN_THEN,
  TOKEN_ELSE,
  TOKEN_FI,
  TOKEN_WHILE,
  TOKEN_DO,
  TOKEN_OD,
  TOKEN_RETURN,
  TOKEN_ENUM,
  TOKEN_OF,
  TOKEN_AND,
  TOKEN_OR,
  TOKEN_COMP,
  TOKEN_ADD,
  TOKEN_SUB,
  TOKEN_MULT,
  TOKEN_DIV,
  TOKEN_POT,
  TOKEN_ATTRIBUTION,
  TOKEN_COLON,
  TOKEN_OPEN_PARENTHESIS,
  TOKEN_CLOSE_PARENTHESIS,
  TOKEN_SEMICOLON,
  TOKEN_COMMA,
  TOKEN_DOT,
  TOKEN_OPEN_BRACES,
  TOKEN_CLOSE_BRACES,
  TOKEN_SINGLE_LINE_COMMENT,
  TOKEN_MULTIPLE_LINE_COMMENT,
  NAME,
  INT_LITERAL,
  FLOAT_LITERAL,
  STRING_LITERAL,
  TOKEN_ERRO
};

%}

DIGIT [0-9]
LETTER [a-zA-Z]
WHITESPACE [ \t]
COMMENT_SL .*
COMMENT_ML [^("//")("(*")("*))]*

%option noyywrap

%%

\r\n|\r|\n                                                                   { numLines++;  numCols = 0; } 
int                                                                          {numCols += YYLeng();std::cout << YYText() << " -> INT\n";}
float                                                                        {numCols += YYLeng(); printf("%s -> FLOAT\n", YYText());}
string                                                                       {numCols += YYLeng(); printf("%s -> STRING\n", YYText());}
bool                                                                         {numCols += YYLeng(); printf("%s -> BOOL\n", YYText());}
program                                                                      {numCols += YYLeng(); printf("%s -> PROGRAM\n", YYText());}
procedure                                                                    {numCols += YYLeng(); printf("%s -> PROCEDURE\n", YYText());}
begin                                                                        {numCols += YYLeng(); printf("%s -> BEGIN\n", YYText());}
end                                                                          {numCols += YYLeng(); printf("%s -> END\n", YYText());}
var                                                                          {numCols += YYLeng(); printf("%s -> VAR\n", YYText());}
in                                                                           {numCols += YYLeng(); printf("%s -> IN\n", YYText());}
struct                                                                       {numCols += YYLeng(); printf("%s -> STRUCT\n", YYText());}
not                                                                          {numCols += YYLeng(); printf("%s -> NOT\n", YYText());}
null                                                                         {numCols += YYLeng(); printf("%s -> NULL\n", YYText());}
new                                                                          {numCols += YYLeng(); printf("%s -> NEW\n", YYText());}
ref                                                                          {numCols += YYLeng(); printf("%s -> REF\n", YYText());}
deref                                                                        {numCols += YYLeng(); printf("%s -> DEREF\n", YYText());}
true                                                                         {numCols += YYLeng(); printf("%s -> TRUE\n", YYText());}
false                                                                        {numCols += YYLeng(); printf("%s -> FALSE\n", YYText());}
if                                                                           {numCols += YYLeng(); printf("%s -> IF\n", YYText());}
then                                                                         {numCols += YYLeng(); printf("%s -> THEN\n", YYText());}
else                                                                         {numCols += YYLeng(); printf("%s -> ELSE\n", YYText());}
fi                                                                           {numCols += YYLeng(); printf("%s -> FI\n", YYText());}
while                                                                        {numCols += YYLeng(); printf("%s -> WHILE\n", YYText());}
do                                                                           {numCols += YYLeng(); printf("%s -> DO\n", YYText());}
od                                                                           {numCols += YYLeng(); printf("%s -> OD\n", YYText());}
return                                                                       {numCols += YYLeng(); printf("%s -> RETURN\n", YYText());}
enum                                                                         {numCols += YYLeng(); printf("%s -> ENUM\n", YYText());}
of                                                                           {numCols += YYLeng(); printf("%s -> OF\n", YYText());}
"&&"                                                                         {numCols += YYLeng(); printf("%s -> AND\n", YYText());}
"||"                                                                         {numCols += YYLeng(); printf("%s -> OR\n", YYText());}
"<"|"<="|">"|">="|"="|"<>"                                                   {numCols += YYLeng(); printf("%s -> COMP\n", YYText());} 
"+"                                                                          {numCols += YYLeng(); printf("%s -> ADD\n", YYText());}                                                                      
"-"                                                                          {numCols += YYLeng(); printf("%s -> SUB\n", YYText());}
"*"                                                                          {numCols += YYLeng(); printf("%s -> MULT\n", YYText());}
"/"                                                                          {numCols += YYLeng(); printf("%s -> DIV\n", YYText());}
"^"                                                                          {numCols += YYLeng(); printf("%s -> POT\n", YYText());}
":="                                                                         {numCols += YYLeng(); printf("%s -> ATTRIBUTION\n", YYText());}
":"                                                                          {numCols += YYLeng(); printf("%s -> COLON\n", YYText());}
"("                                                                          {numCols += YYLeng(); printf("%s -> OPEN_PARENTHESIS\n", YYText());}
")"                                                                          {numCols += YYLeng(); printf("%s -> CLOSE_PARENTHESIS\n", YYText());}
";"                                                                          {numCols += YYLeng(); printf("%s -> SEMICOLON\n", YYText());}
","                                                                          {numCols += YYLeng(); printf("%s -> COMMA\n", YYText());}
"."                                                                          {numCols += YYLeng(); printf("%s -> DOT\n", YYText());}
"{"                                                                          {numCols += YYLeng(); printf("%s -> OPEN_BRACES\n", YYText());}
"}"                                                                          {numCols += YYLeng(); printf("%s -> CLOSE_BRACES\n", YYText());}
"//"{COMMENT_SL}                                                             {numCols += YYLeng(); printf("%s -> SINGLE_LINE_COMMENT \n", YYText());}
"(*"{COMMENT_ML}"*)"                                                         {numCols += YYLeng(); printf("%s -> MULTIPLE_LINE_COMMENT \n", YYText());}
{LETTER}((({LETTER}|{DIGIT}|_)*_({LETTER}|{DIGIT})+)|({LETTER}|{DIGIT})*)    {
  numCols += YYLeng(); 
  table.insert(YYText());
  printf("%s -> NAME\n", YYText());
}
{DIGIT}+                                                                     {numCols += YYLeng(); printf("%s -> INT_LITERAL\n", YYText());}
{DIGIT}+("."{DIGIT}+)?(e(-|"+")?{DIGIT}+)?                                   {numCols += YYLeng(); printf("%s -> FLOAT_LITERAL\n", YYText());}
\"[^\n\r\t"]*\"                                                              {numCols += YYLeng(); printf("%s -> STRING_LITERAL\n", YYText());}
{WHITESPACE}                                                                 {numCols += YYLeng();} 
.                                                                            {numCols += YYLeng(); return TOKEN_ERRO;}

%%


int main(){
  yyFlexLexer lexer;
  if(lexer.yylex() == TOKEN_ERRO){
    printf("Erro na linha %d e coluna %d\n", numLines, numCols);
  }
  table.printTable();
  return 0;
}
