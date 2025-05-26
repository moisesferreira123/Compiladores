%{
#include "exp.tab.h"

#include <stdio.h>
#include <string.h>

// Prototipando yylval (sem extern "C")
extern YYSTYPE yylval;

// Inclui C++ após extern "C"
#include "symbol_table.hpp"

// Declara que existe uma instância global da tabela de símbolos
extern SymbolTable symbolTable;
%}

%%
[a-zA-Z_][a-zA-Z0-9_]*   {
    Symbol sym;
    sym.name = std::string(yytext);
    sym.type = SymbolType::VARIABLE;
    sym.dataType = "int";
    sym.scopeLevel = 0;
    sym.memoryAddress = 0;
    symbolTable.insert(sym);

    return NAME;
}

"+"                      { return PLUS; }
[ \t\n]                  ;  // Ignora espaços
.                        { return yytext[0]; }
%%
