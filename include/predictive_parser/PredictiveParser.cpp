#include "../Tokens.hpp"
#include "module/PredictiveParser.hpp"
#include <FlexLexer.h>
#include <stack>

int lookahead;

yyFlexLexer scanner;
int yylex() { return scanner.yylex(); }
extern int numLines, numCols;

void advance() { lookahead = yylex(); }

void match(int expected) {
   if (lookahead == expected) {
      advance();
   } else {
      std::cerr << "Erro sintático na linha " << numLines << ", coluna "
                << numCols << ". Esperado token " << expected
                << " mas encontrado " << scanner.YYText() << "\n";
      exit(1);
   }
}

bool isTerminal(int token) {
   return token > Tokens::FIRST_TOKEN && token < Tokens::LAST_TOKEN;
}
bool isNonTerminal(int token) {
   return token > NonTerminalTokens::FIRST_TOKEN_NT
     && token < NonTerminalTokens::LAST_TOKEN_NT;
}

PredictiveParser::PredictiveParser() : table() { }

bool PredictiveParser::isValid() {
   std::stack<int> tokens;
   auto productions = table.getTable();

   tokens.push(Tokens::TOKEN_CIPHER);
   tokens.push(NonTerminalTokens::PROGRAM);
   advance();

   while (!tokens.empty()) {
      int top = tokens.top();

      if (isTerminal(top)) {
         match(top);
         tokens.pop();
      } else if (isNonTerminal(top)) {
         auto production = productions.at({ top, lookahead });

         if (production.empty()) {
            std::cerr << "ERROR: Não existe a produção esperada.\n";
            return false;
         } else if (production.front() != TOKEN_EPSILON) {
            tokens.pop();
            for (auto token : production) {
               tokens.push(token);
            }
         } else {
            tokens.pop();
         }
      } else {
         std::cerr << "ERROR: Token inválido.\n";
         return false;
      }
   }

   return true;
}
