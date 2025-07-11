%{
#include "exp.tab.h"

#include <stdio.h>
#include <string.h>
#include <iostream>
#include "logger.hpp"

extern YYSTYPE yylval;

// Contadores
int numLines = 1; 
int numCols = 1;
%}

%option noyywrap

DIGIT [0-9]
ALPHA [a-zA-Z]
ALPHA_NUM {ALPHA}|{DIGIT}
MACRO_NAME {ALPHA}({ALPHA_NUM}*(_{ALPHA_NUM}+)?)*
INVALID_NAME  ([0-9_]+{MACRO_NAME}"_"*|{MACRO_NAME}"_"+)
NUM {DIGIT}+
WHITESPACE [ \t]
COMMENT_SL .*
COMMENT_ML [^("//")("(*")("*))]*

%%
\r\n|\r|\n|\n\r { 
   numLines++; 
   numCols = 1; 
}

int { 
   numCols += yyleng; 
   return TOKEN_INT; 
}

float { 
   numCols += yyleng; 
   return TOKEN_FLOAT; 
}

string { 
   numCols += yyleng; 
   return TOKEN_STRING; 
}

bool { 
   numCols += yyleng; 
   return TOKEN_BOOL; 
}

program { 
   numCols += yyleng; 
   return TOKEN_PROGRAM; 
}

procedure { 
   numCols += yyleng; 
   return TOKEN_PROCEDURE; 
}

begin { 
   numCols += yyleng; 
   return TOKEN_BEGIN; 
}

end { 
   numCols += yyleng; 
   return TOKEN_END; 
}

var { 
    numCols += yyleng; 
    return TOKEN_VAR; 
}

in { 
   numCols += yyleng; 
   return TOKEN_IN; 
}

struct { 
   numCols += yyleng; 
   return TOKEN_STRUCT; 
}

not { 
   numCols += yyleng; 
   return TOKEN_NOT; 
}

null { 
   numCols += yyleng; 
   return TOKEN_NULL; 
}

new { 
    numCols += yyleng; 
    return TOKEN_NEW; 
}

ref { 
   numCols += yyleng; 
   return TOKEN_REF; 
}

deref { 
   numCols += yyleng; 
   return TOKEN_DEREF; 
}

true { 
   numCols += yyleng; 
   return TOKEN_TRUE; 
}

false { 
   numCols += yyleng; 
   return TOKEN_FALSE; 
}

if { 
   numCols += yyleng; 
   return TOKEN_IF; 
}

then { 
   numCols += yyleng; 
   return TOKEN_THEN; 
}

else { 
   numCols += yyleng; 
   return TOKEN_ELSE; 
}

fi { 
   numCols += yyleng; 
   return TOKEN_FI; 
}

while { 
   numCols += yyleng; 
   return TOKEN_WHILE; 
}

do { 
   numCols += yyleng; 
   return TOKEN_DO; 
}

od { 
   numCols += yyleng; 
   return TOKEN_OD; 
}

return { 
   numCols += yyleng; 
   return TOKEN_RETURN; 
}

enum { 
   numCols += yyleng; 
   return TOKEN_ENUM; 
}

of { 
   numCols += yyleng; 
   return TOKEN_OF; 
}

"&&" { 
   numCols += yyleng; 
   return TOKEN_AND; 
}

"||" { 
   numCols += yyleng; 
   return TOKEN_OR; 
}

"=" { 
   numCols += yyleng; 
   return TOKEN_EQUAL; 
}

"<>" {
   numCols += yyleng;
   return TOKEN_DIFF;
}

"<" {
   numCols += yyleng;
   return TOKEN_LESS;
}

"<=" {
   numCols += yyleng;
   return TOKEN_LESS_EQUAL;
}

">" {
   numCols += yyleng;
   return TOKEN_GREATER;
}

">=" {
   numCols += yyleng;
   return TOKEN_GREATER_EQUAL;
}

"+" { 
   numCols += yyleng; 
   return TOKEN_ADD; 
}

"-" { 
   numCols += yyleng; 
   return TOKEN_SUB; 
}

"*" { 
   numCols += yyleng; 
   return TOKEN_MULT; 
}

"/" { 
   numCols += yyleng; 
   return TOKEN_DIV; 
}

"^" { 
   numCols += yyleng; 
   return TOKEN_POT; 
}

":=" { 
   numCols += yyleng; 
   return TOKEN_ATTRIBUTION; 
}

":" { 
   numCols += yyleng; 
   return TOKEN_COLON; 
}

"(" { 
   numCols += yyleng; 
   return TOKEN_OPEN_PARENTHESIS; 
}

")" { 
   numCols += yyleng; 
   return TOKEN_CLOSE_PARENTHESIS; 
}

";" { 
   numCols += yyleng; 
   return TOKEN_SEMICOLON; 
}

"," { 
   numCols += yyleng; 
   return TOKEN_COMMA; 
}

"." { 
   numCols += yyleng; 
   return TOKEN_DOT; 
}

"{" { 
   numCols += yyleng; 
   return TOKEN_OPEN_BRACES; 
}

"}" { 
   numCols += yyleng; 
   return TOKEN_CLOSE_BRACES; 
}

"//"{COMMENT_SL} { 
   numCols += yyleng; 
}

"(*"{COMMENT_ML}"*)" { 
   std::string comment(yytext, yyleng); 
   for (char c : comment) { 
      if (c == '\n') { 
         ++numLines; 
         numCols = 1; 
      } 
      else { 
         ++numCols; 
      } 
   } 
}

{MACRO_NAME} { 
   numCols += yyleng; 
   yylval.name_value = strdup(yytext); 
   return NAME; 
}

{NUM} { 
   numCols += yyleng; 
   yylval.int_value = atoi(yytext);
   return INT_LITERAL; 
}

{NUM}("."{NUM})?(e[-+]?{NUM})? {
   numCols += yyleng; 
   yylval.float_value = atof(yytext); 
   return FLOAT_LITERAL; 
}

\"[^\\"\n\r]*\" { 
   numCols += yyleng; 
   yylval.string_value = strdup(yytext); 
   return STRING_LITERAL; 
}

{WHITESPACE} { 
   numCols += yyleng; 
}

.|{INVALID_NAME} {
   std::string message = std::string("Token \"") + yytext + "\" não identificado";
   Logger::error(message, numLines, numCols, false);

   numCols += yyleng;

   return TOKEN_ERROR; 
}

%%
