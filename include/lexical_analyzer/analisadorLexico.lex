%{
#include <stdio.h>
%}

DIGIT [0-9]
LETTER [a-zA-Z]
WHITESPACE [ \t\n]+
COMMENT_SL .*
COMMENT_ML [^("//")("(*")("*))]*

%%

int                                                                          {printf("%s -> INT\n", yytext);}
float                                                                        {printf("%s -> FLOAT\n", yytext);}
string                                                                       {printf("%s -> STRING\n", yytext);}
bool                                                                         {printf("%s -> BOOL\n", yytext);}
program                                                                      {printf("%s -> PROGRAM\n", yytext);}
begin                                                                        {printf("%s -> BEGIN\n", yytext);}
end                                                                          {printf("%s -> END\n", yytext);}
var                                                                          {printf("%s -> VAR\n", yytext);}
in                                                                           {printf("%s -> IN\n", yytext);}
struct                                                                       {printf("%s -> STRUCT\n", yytext);}
not                                                                          {printf("%s -> NOT\n", yytext);}
null                                                                         {printf("%s -> NULL\n", yytext);}
new                                                                          {printf("%s -> NEW\n", yytext);}
ref                                                                          {printf("%s -> REF\n", yytext);}
deref                                                                        {printf("%s -> DEREF\n", yytext);}
true                                                                         {printf("%s -> TRUE\n", yytext);}
false                                                                        {printf("%s -> FALSE\n", yytext);}
if                                                                           {printf("%s -> IF\n", yytext);}
then                                                                         {printf("%s -> THEN\n", yytext);}
else                                                                         {printf("%s -> ELSE\n", yytext);}
fi                                                                           {printf("%s -> FI\n", yytext);}
while                                                                        {printf("%s -> WHILE\n", yytext);}
do                                                                           {printf("%s -> DO\n", yytext);}
od                                                                           {printf("%s -> OD\n", yytext);}
return                                                                       {printf("%s -> RETURN\n", yytext);}
enum                                                                         {printf("%s -> ENUM\n", yytext);}
of                                                                           {printf("%s -> OF\n", yytext);}
"&&"                                                                         {printf("%s -> AND\n", yytext);}
"||"                                                                         {printf("%s -> OR\n", yytext);}
"<"|"<="|">"|">="|"="|"<>"                                                   {printf("%s -> COMP\n", yytext);} 
"+"                                                                          {printf("%s -> ADD\n", yytext);}                                                                      
"-"                                                                          {printf("%s -> SUB\n", yytext);}
"*"                                                                          {printf("%s -> MULT\n", yytext);}
"/"                                                                          {printf("%s -> DIV\n", yytext);}
"^"                                                                          {printf("%s -> POT\n", yytext);}
":="                                                                         {printf("%s -> ATTRIBUTION\n", yytext);}
":"                                                                          {printf("%s -> COLON\n", yytext);}
"("                                                                          {printf("%s -> OPEN_PARENTHESIS\n", yytext);}
")"                                                                          {printf("%s -> CLOSE_PARENTHESIS\n", yytext);}
";"                                                                          {printf("%s -> SEMICOLON\n", yytext);}
","                                                                          {printf("%s -> COMMA\n", yytext);}
"."                                                                          {printf("%s -> DOT\n", yytext);}
"{"                                                                          {printf("%s -> OPEN_BRACES\n", yytext);}
"}"                                                                          {printf("%s -> CLOSE_BRACES\n", yytext);}
"//"{COMMENT_SL}                                                             {printf("%s -> SINGLE_LINE_COMMENT \n", yytext);}
"(*"{COMMENT_ML}"*)"                                                         {printf("%s -> MULTIPLE_LINE_COMMENT \n", yytext);}
{LETTER}((({LETTER}|{DIGIT}|_)*_({LETTER}|{DIGIT})+)|({LETTER}|{DIGIT})*)    {printf("%s -> NAME\n", yytext);}
{DIGIT}+                                                                     {printf("%s -> INT_LITERAL\n", yytext);}
{DIGIT}+("."{DIGIT}+)?(e(-|"+")?{DIGIT}+)?                                   {printf("%s -> FLOAT_LITERAL\n", yytext);}
\"[^\n\r\t"]*\"                                                              {printf("%s -> STRING_LITERAL\n", yytext);}
{WHITESPACE}          
.                                                                            {printf("%s -> ERRO\n", yytext);}

%%


int main(){
  yylex();
  return 0;
}
