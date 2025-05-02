%{
#include "../symbol_table/SymbolTable.hpp"
#include "../symbol_table/Symbol.hpp"
#include "../Tokens.hpp"
#include <string>

int numLines = 1; 
int numCols = 0;

SymbolTable table;

%}

DIGIT     [0-9]
LETTER    [a-zA-Z]
WHITESPACE [ \t]
COMMENT_SL .*
COMMENT_ML [^("//")("(*")("*))]*

%%

\r\n|\r|\n|\n\r                          { numLines++; numCols = 0; }

int                                     { numCols += yyleng; return TOKEN_INT; }
float                                   { numCols += yyleng; return TOKEN_FLOAT; }
string                                  { numCols += yyleng; return TOKEN_STRING; }
bool                                    { numCols += yyleng; return TOKEN_BOOL; }
program                                 { numCols += yyleng; return TOKEN_PROGRAM; }
procedure                               { numCols += yyleng; return TOKEN_PROCEDURE; }
begin                                   { numCols += yyleng; return TOKEN_BEGIN; }
end                                     { numCols += yyleng; return TOKEN_END; }
var                                     { numCols += yyleng; return TOKEN_VAR; }
in                                      { numCols += yyleng; return TOKEN_IN; }
struct                                  { numCols += yyleng; return TOKEN_STRUCT; }
not                                     { numCols += yyleng; return TOKEN_NOT; }
null                                    { numCols += yyleng; return TOKEN_NULL; }
new                                     { numCols += yyleng; return TOKEN_NEW; }
ref                                     { numCols += yyleng; return TOKEN_REF; }
deref                                   { numCols += yyleng; return TOKEN_DEREF; }
true                                    { numCols += yyleng; return TOKEN_TRUE; }
false                                   { numCols += yyleng; return TOKEN_FALSE; }
if                                      { numCols += yyleng; return TOKEN_IF; }
then                                    { numCols += yyleng; return TOKEN_THEN; }
else                                    { numCols += yyleng; return TOKEN_ELSE; }
fi                                      { numCols += yyleng; return TOKEN_FI; }
while                                   { numCols += yyleng; return TOKEN_WHILE; }
do                                      { numCols += yyleng; return TOKEN_DO; }
od                                      { numCols += yyleng; return TOKEN_OD; }
return                                  { numCols += yyleng; return TOKEN_RETURN; }
enum                                    { numCols += yyleng; return TOKEN_ENUM; }
of                                      { numCols += yyleng; return TOKEN_OF; }

"&&"                                    { numCols += yyleng; return TOKEN_AND; }
"||"                                    { numCols += yyleng; return TOKEN_OR; }
"<"|"<="|">"|">="|"<>"                  { numCols += yyleng; return TOKEN_COMP; }
"="                                     { numCols += yyleng; return TOKEN_EQUAL; }
"+"                                     { numCols += yyleng; return TOKEN_ADD; }
"-"                                     { numCols += yyleng; return TOKEN_SUB; }
"*"                                     { numCols += yyleng; return TOKEN_MULT; }
"/"                                     { numCols += yyleng; return TOKEN_DIV; }
"^"                                     { numCols += yyleng; return TOKEN_POT; }
":="                                    { numCols += yyleng; return TOKEN_ATTRIBUTION; }
":"                                     { numCols += yyleng; return TOKEN_COLON; }
"("                                     { numCols += yyleng; return TOKEN_OPEN_PARENTHESIS; }
")"                                     { numCols += yyleng; return TOKEN_CLOSE_PARENTHESIS; }
";"                                     { numCols += yyleng; return TOKEN_SEMICOLON; }
","                                     { numCols += yyleng; return TOKEN_COMMA; }
"."                                     { numCols += yyleng; return TOKEN_DOT; }
"{"                                     { numCols += yyleng; return TOKEN_OPEN_BRACES; }
"}"                                     { numCols += yyleng; return TOKEN_CLOSE_BRACES; }

"//"{COMMENT_SL}                        { numCols += yyleng;  }
"(*"{COMMENT_ML}"*)"                   { 
    std::string comment(yytext, yyleng);
    for (char c : comment) {
        if (c == '\n') {
            ++numLines;
            numCols = 1;  // coluna reinicia após uma nova linha
        } else {
            ++numCols;
        }
    }
}

{LETTER}((({LETTER}|{DIGIT}|_)*_({LETTER}|{DIGIT})+)|({LETTER}|{DIGIT})*) {
                                        numCols += yyleng;
                                        table.insert(YYText(), Symbol());
                                        return NAME;
}

{DIGIT}+                                { numCols += yyleng; return INT_LITERAL; }
{DIGIT}+("."{DIGIT}+)?(e(-|"+")?{DIGIT}+)? {
                                        numCols += yyleng; return FLOAT_LITERAL; }
\"[^\n\t\r]*\"                          { numCols += yyleng; return STRING_LITERAL; }
{WHITESPACE}                            { numCols += yyleng; /* ignora espaços */ }
.                                       { 
                                        numCols += yyleng;
                                        std::cerr << "Erro léxico na linha " << numLines << ", coluna " << numCols << ": '" << YYText() << "'\n";
                                        return TOKEN_ERRO;
}
<<EOF>> {
    return TOKEN_CIPHER;
}

%%

int yyFlexLexer::yywrap() {
    return 1;
}