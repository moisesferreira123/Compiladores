%{
#include <iostream>
#include "../symbol_table/SymbolTableTemporary.hpp"
#include "../symbol_table/SymbolTable.hpp"
#include "../symbol_table/Symbol.hpp"

int numLines = 1; 
int numCols = 0;
SymbolTableTemporary table;

enum Tokens {
  TOKEN_INT = 360,
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

\r\n|\r|\n|\n\r                                                                   { numLines++; numCols = 0; } 
int                                                                          { numCols += yyleng; std::cout << YYText() << " -> INT\n"; }
float                                                                        { numCols += yyleng; std::cout << YYText() << " -> FLOAT\n"; }
string                                                                       { numCols += yyleng; std::cout << YYText() << " -> STRING\n"; }
bool                                                                         { numCols += yyleng; std::cout << YYText() << " -> BOOL\n"; }
program                                                                      { numCols += yyleng; std::cout << YYText() << " -> PROGRAM\n"; }
procedure                                                                    { numCols += yyleng; std::cout << YYText() << " -> PROCEDURE\n"; }
begin                                                                        { numCols += yyleng; std::cout << YYText() << " -> BEGIN\n"; }
end                                                                          { numCols += yyleng; std::cout << YYText() << " -> END\n"; }
var                                                                          { numCols += yyleng; std::cout << YYText() << " -> VAR\n"; }
in                                                                           { numCols += yyleng; std::cout << YYText() << " -> IN\n"; }
struct                                                                       { numCols += yyleng; std::cout << YYText() << " -> STRUCT\n"; }
not                                                                          { numCols += yyleng; std::cout << YYText() << " -> NOT\n"; }
null                                                                         { numCols += yyleng; std::cout << YYText() << " -> NULL\n"; }
new                                                                          { numCols += yyleng; std::cout << YYText() << " -> NEW\n"; }
ref                                                                          { numCols += yyleng; std::cout << YYText() << " -> REF\n"; }
deref                                                                        { numCols += yyleng; std::cout << YYText() << " -> DEREF\n"; }
true                                                                         { numCols += yyleng; std::cout << YYText() << " -> TRUE\n"; }
false                                                                        { numCols += yyleng; std::cout << YYText() << " -> FALSE\n"; }
if                                                                           { numCols += yyleng; std::cout << YYText() << " -> IF\n"; }
then                                                                         { numCols += yyleng; std::cout << YYText() << " -> THEN\n"; }
else                                                                         { numCols += yyleng; std::cout << YYText() << " -> ELSE\n"; }
fi                                                                           { numCols += yyleng; std::cout << YYText() << " -> FI\n"; }
while                                                                        { numCols += yyleng; std::cout << YYText() << " -> WHILE\n"; }
do                                                                           { numCols += yyleng; std::cout << YYText() << " -> DO\n"; }
od                                                                           { numCols += yyleng; std::cout << YYText() << " -> OD\n"; }
return                                                                       { numCols += yyleng; std::cout << YYText() << " -> RETURN\n"; }
enum                                                                         { numCols += yyleng; std::cout << YYText() << " -> ENUM\n"; }
of                                                                           { numCols += yyleng; std::cout << YYText() << " -> OF\n"; }
"&&"                                                                         { numCols += yyleng; std::cout << YYText() << " -> AND\n"; }
"||"                                                                         { numCols += yyleng; std::cout << YYText() << " -> OR\n"; }
"<"|"<="|">"|">="|"="|"<>"                                                   { numCols += yyleng; std::cout << YYText() << " -> COMP\n"; } 
"+"                                                                          { numCols += yyleng; std::cout << YYText() << " -> ADD\n"; }                                                                      
"-"                                                                          { numCols += yyleng; std::cout << YYText() << " -> SUB\n"; }
"*"                                                                          { numCols += yyleng; std::cout << YYText() << " -> MULT\n"; }
"/"                                                                          { numCols += yyleng; std::cout << YYText() << " -> DIV\n"; }
"^"                                                                          { numCols += yyleng; std::cout << YYText() << " -> POT\n"; }
":="                                                                         { numCols += yyleng; std::cout << YYText() << " -> ATTRIBUTION\n"; }
":"                                                                          { numCols += yyleng; std::cout << YYText() << " -> COLON\n"; }
"("                                                                          { numCols += yyleng; std::cout << YYText() << " -> OPEN_PARENTHESIS\n"; }
")"                                                                          { numCols += yyleng; std::cout << YYText() << " -> CLOSE_PARENTHESIS\n"; }
";"                                                                          { numCols += yyleng; std::cout << YYText() << " -> SEMICOLON\n"; }
","                                                                          { numCols += yyleng; std::cout << YYText() << " -> COMMA\n"; }
"."                                                                          { numCols += yyleng; std::cout << YYText() << " -> DOT\n"; }
"{"                                                                          { numCols += yyleng; std::cout << YYText() << " -> OPEN_BRACES\n"; }
"}"                                                                          { numCols += yyleng; std::cout << YYText() << " -> CLOSE_BRACES\n"; }
"//"{COMMENT_SL}                                                             { numCols += yyleng; std::cout << YYText() << " -> SINGLE_LINE_COMMENT \n"; }
"(*"{COMMENT_ML}"*)"                                                         { numCols += yyleng; std::cout << YYText() << " -> MULTIPLE_LINE_COMMENT \n"; }
{LETTER}((({LETTER}|{DIGIT}|_)*_({LETTER}|{DIGIT})+)|({LETTER}|{DIGIT})*)    {
  numCols += yyleng; 
  table.insert(YYText()());
  std::cout << YYText() << " -> NAME\n";
}
{DIGIT}+                                                                     { numCols += yyleng; std::cout << YYText() << " -> INT_LITERAL\n"; }
{DIGIT}+("."{DIGIT}+)?(e(-|"+")?{DIGIT}+)?                                   { numCols += yyleng; std::cout << YYText() << " -> FLOAT_LITERAL\n"; }
\"[^\n\t\r]*\"                                                              { numCols += yyleng; std::cout << YYText() << " -> STRING_LITERAL\n"; }
{WHITESPACE}                                                                 { numCols += yyleng; } 
.                                                                            { numCols += yyleng; std::cout << YYText() << " -> ERRO\n";     std::cout << "Erro na linha " << numLines << " e coluna " << numCols << std::endl; }

%%

int main() {
  yyFlexLexer lexer;
  lexer.yylex();
  table.printTable();
  return 0;
}
