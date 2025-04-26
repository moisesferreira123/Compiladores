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
  if (lookahead == TOKEN_VAR || lookahead == TOKEN_PROCEDURE ||
      lookahead == TOKEN_STRUCT || lookahead == TOKEN_ENUM) {
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
  /// Proc e Enum não estão prontos
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
  /// EXP não está pronto
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
              << TOKEN_COLON << " mas encontrado " << scanner.YYText() << "\n";
    exit(1);
  }
}

void ProcDecl() {
  if (lookahead == TOKEN_PROCEDURE) {
    match(TOKEN_PROCEDURE);
    match(NAME);
    match(TOKEN_OPEN_PARENTHESIS);
    ProcParamFieldDecl();
    match(TOKEN_CLOSE_PARENTHESIS);
    ProcTypeDecl();
    match(TOKEN_BEGIN);
    ProcDeclDecl();
    StmtList();
    match(TOKEN_END);
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_PROCEDURE
              << " mas encontrado " << scanner.YYText() << "\n";
    exit(1);
  }
}

void ProcParamFieldDecl() {
  if (lookahead == NAME) {
    ParamFieldDecl();
    ProcParamFieldDecl_();
  }
}

void ProcParamFieldDecl_() {
  if (lookahead == TOKEN_SEMICOLON) {
    match(TOKEN_SEMICOLON);
    ParamFieldDecl();
    ProcParamFieldDecl_();
  }
}

void ProcTypeDecl() {
  if (lookahead == TOKEN_COLON) {
    match(TOKEN_COLON);
    Type();
  }
}

void ProcDeclDecl() {
  if (lookahead == TOKEN_VAR || lookahead == TOKEN_PROCEDURE ||
      lookahead == TOKEN_STRUCT || lookahead == TOKEN_ENUM) {
    ProgramDecl();
    match(TOKEN_IN);
  }
}

void RecDecl() {
  if (lookahead == TOKEN_STRUCT) {
    match(TOKEN_STRUCT);
    match(NAME);
    match(TOKEN_OPEN_BRACES);
    RecParamFieldDecl();
    match(TOKEN_CLOSE_BRACES);
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_STRUCT
              << " mas encontrado " << scanner.YYText() << "\n";
    exit(1);
  }
}

void RecParamFieldDecl() {
  if (lookahead == NAME) {
    ParamFieldDecl();
    RecParamFieldDecl_();
  }
}

void RecParamFieldDecl_() {
  if (lookahead == TOKEN_SEMICOLON) {
    match(TOKEN_SEMICOLON);
    ParamFieldDecl();
    RecParamFieldDecl_();
  }
}

void EnumDecl() {
  if (lookahead == TOKEN_ENUM) {
    match(TOKEN_ENUM);
    match(NAME);
    /// match(TOKEN_EQUAL) é necessário separar os tokens de comparação.
    match(TOKEN_OPEN_BRACES);
    match(NAME);
    EnumFieldDecl();
    match(TOKEN_CLOSE_BRACES);
    match(TOKEN_OF);
    Type();
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_ENUM
              << " mas encontrado " << scanner.YYText() << "\n";
    exit(1);
  }
}

void EnumFieldDecl() {
  if (lookahead == TOKEN_COMMA) {
    match(TOKEN_COMMA);
    match(NAME);
    EnumFieldDecl();
  }
}

void ParamFieldDecl() {
  if (lookahead == NAME) {
    match(NAME);
    match(TOKEN_COLON);
    Type();
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << NAME << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void StmtList() {
  if (lookahead == NAME || lookahead == TOKEN_DEREF || lookahead == TOKEN_IF ||
      lookahead == TOKEN_WHILE || lookahead == TOKEN_RETURN ||
      lookahead == TOKEN_NOT || lookahead == TOKEN_OPEN_PARENTHESIS ||
      lookahead == TOKEN_INT || lookahead == TOKEN_FLOAT ||
      lookahead == TOKEN_STRING || lookahead == TOKEN_TRUE ||
      lookahead == TOKEN_REF || lookahead == TOKEN_FALSE ||
      lookahead == TOKEN_NEW || lookahead == TOKEN_NULL) {
    Stmt();
    StmtList_();
  }
}

void StmtList_() {
  if (lookahead == TOKEN_SEMICOLON) {
    match(TOKEN_SEMICOLON);
    Stmt();
    StmtList_();
  }
}

void Stmt() {
  /// Muitos filhos precisam ser criados!
  if (lookahead == NAME) {
    match(NAME);
    Stmt_();
  } else if (lookahead == TOKEN_DEREF) {
    DerefVar();
    StmtDeref_();
    AssignStmt();
  } else if (lookahead == TOKEN_IF) {
    IfStmt();
  } else if (lookahead == TOKEN_WHILE) {
    WhileStmt();
  } else if (lookahead == TOKEN_RETURN) {
    ReturnStmt();
  } else if (lookahead == TOKEN_NOT || lookahead == TOKEN_OPEN_PARENTHESIS ||
             lookahead == TOKEN_INT || lookahead == TOKEN_FLOAT ||
             lookahead == TOKEN_STRING || lookahead == TOKEN_TRUE ||
             lookahead == TOKEN_REF || lookahead == TOKEN_FALSE ||
             lookahead == TOKEN_NEW || lookahead == TOKEN_NULL) {
    Exp5();
    match(TOKEN_DOT);
    match(NAME);
    Var2_();
    AssignStmt();
  }

  else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << NAME << " ou " << TOKEN_DEREF
              << " ou " << TOKEN_IF << " ou " << TOKEN_WHILE << " ou "
              << TOKEN_RETURN << " mas encontrado " << scanner.YYText() << "\n";
    exit(1);
  }
}

void Type() {
  if (lookahead == NAME) {
    match(NAME);
  } else if (lookahead == TOKEN_FLOAT) {
    match(TOKEN_FLOAT);
  } else if (lookahead == TOKEN_INT) {
    match(TOKEN_INT);
  } else if (lookahead == TOKEN_STRING) {
    match(TOKEN_STRING);
  } else if (lookahead == TOKEN_BOOL) {
    match(TOKEN_BOOL);
  } else if (lookahead == TOKEN_REF) {
    match(TOKEN_REF);
    match(TOKEN_OPEN_PARENTHESIS);
    Type();
    match(TOKEN_CLOSE_PARENTHESIS);
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << NAME << " ou " << TOKEN_FLOAT
              << " ou " << TOKEN_INT << " ou " << TOKEN_STRING << " ou "
              << TOKEN_BOOL << " ou " << TOKEN_REF << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}