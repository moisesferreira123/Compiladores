#include "Parser.hpp"
#include <FlexLexer.h>

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

void Program() {
   if (lookahead == TOKEN_PROGRAM) {
      match(TOKEN_PROGRAM);
      match(NAME);
      match(TOKEN_BEGIN);
      ProgramDecl();
      match(TOKEN_END);
   } else {
      std::cerr << "Erro sintático na linha " << numLines << ", coluna "
                << numCols << ". Esperado token " << TOKEN_PROGRAM
                << " mas encontrado " << scanner.YYText() << "\n";
      exit(1);
   }
}

void ProgramDecl() {
   if (lookahead == TOKEN_VAR || lookahead == TOKEN_PROCEDURE
     || lookahead == TOKEN_STRUCT || lookahead == TOKEN_ENUM) {
      Decl();
      ProgramDecl_();
   }
}

void ProgramDecl_() {
   if (lookahead == TOKEN_SEMICOLON) {
      match(TOKEN_SEMICOLON);
      Decl();
      ProgramDecl_();
   }
}

void Decl() {
   if (lookahead == TOKEN_VAR) {
      VarDecl();
   } else if (lookahead == TOKEN_PROCEDURE) {
      ProcDecl();
   } else if (lookahead == TOKEN_STRUCT) {
      RecDecl();
   } else if (lookahead == TOKEN_ENUM) {
      EnumDecl();
   } else {
      std::cerr << "Erro sintático na linha " << numLines << ", coluna "
                << numCols << ". Esperado token " << TOKEN_VAR << " ou "
                << TOKEN_PROCEDURE << " ou " << TOKEN_STRUCT << " ou "
                << TOKEN_ENUM << " mas encontrado " << scanner.YYText() << "\n";
      exit(1);
   }
}

void VarDecl() {
   if (lookahead == TOKEN_VAR) {
      match(TOKEN_VAR);
      match(NAME);
      VarDecl_();
   } else {
      std::cerr << "Erro sintático na linha " << numLines << ", coluna "
                << numCols << ". Esperado token " << TOKEN_VAR
                << " mas encontrado " << scanner.YYText() << "\n";
      exit(1);
   }
}

void VarDecl_() {
   if (lookahead == TOKEN_ATTRIBUTION) {
      match(TOKEN_ATTRIBUTION);
      Exp();
   } else if (lookahead == TOKEN_COLON) {
      match(TOKEN_COLON);
      Type();

      if (lookahead == TOKEN_ATTRIBUTION) {
         match(TOKEN_ATTRIBUTION);
         Exp();
      }
   } else {
      std::cerr << "Erro sintático na linha " << numLines << ", coluna "
                << numCols << ". Esperado token " << TOKEN_ATTRIBUTION << " ou "
                << TOKEN_COLON << " mas encontrado " << scanner.YYText()
                << "\n";
      exit(1);
   }
}

void ProcDecl() { }
void RecDecl() { }
void EnumDecl() { }
void Exp() { }
void Type() { }