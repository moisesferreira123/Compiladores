#include "Parser2.hpp"
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
  if (lookahead == TOKEN_COMMA) {
    match(TOKEN_COMMA);
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
    match(TOKEN_EQUAL);
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

void Exp() {
  AndOp();
  OrOp_();
}

void AndOp() {
  NotOp();
  AndOp_();
}

void OrOp_() {
  if(lookahead == TOKEN_OR) {
    match(TOKEN_OR);
    AndOp();
    OrOp_();
  }
}

void AndOp_() {
  if(lookahead == TOKEN_AND) {
    match(TOKEN_AND);
    NotOp();
    AndOp_();
  }
}

void NotOp() {
  NotOp_();
  ExpRel();
}

void NotOp_() {
  if(lookahead == TOKEN_NOT) {
    match(TOKEN_NOT);
    NotOp_();
  }
}

void ExpRel() {
  ExpArith();
  ExpRel_();
}

void ExpRel_() {
  if(lookahead == TOKEN_COMP) {
    match(TOKEN_COMP);
    ExpArith();
  } else if(lookahead == TOKEN_EQUAL) {
    match(TOKEN_EQUAL);
    ExpArith();
  }
}

void ExpArith() {
  Term();
  ExpArith_();
}

void ExpArith_() {
  if(lookahead == TOKEN_ADD){
    match(TOKEN_ADD);
    Term();
    ExpArith_();
  } else if(lookahead == TOKEN_SUB){
    match(TOKEN_SUB);
    Term();
    ExpArith_();
  }
}

void Term() {
  Pow();
  Term_();
}

void Term_() {
  if(lookahead == TOKEN_MULT){
    match(TOKEN_MULT);
    Pow();
    Term_();
  } else if(lookahead == TOKEN_DIV){
    match(TOKEN_DIV);
    Pow();
    Term_();
  }
}

void Pow() {
  Var();
  Pow_();
}

void Pow_() {
  if(lookahead == TOKEN_POT) {
    match(TOKEN_POT);
    Pow();
  }
}

void Var() {
  Fact();
  Var_();
}

void Var_() {
  if(lookahead == TOKEN_DOT) {
    match(TOKEN_DOT);
    match(NAME);
    Var_();
  }
}

void Fact() {
  if(lookahead == TOKEN_OPEN_PARENTHESIS) {
    match(TOKEN_OPEN_PARENTHESIS);
    Exp();
    match(TOKEN_CLOSE_PARENTHESIS);
  } else if(lookahead == NAME) {
    match(NAME);
    CallStmt();
  } else if (lookahead == TOKEN_REF) {
    RefVar();
  } else if (lookahead == TOKEN_DEREF) {
    DerefVar();
  } else if(lookahead == FLOAT_LITERAL || lookahead == INT_LITERAL ||
            lookahead == STRING_LITERAL || lookahead == TOKEN_TRUE ||
            lookahead == TOKEN_FALSE || lookahead == TOKEN_NULL) {
    Literal();
  } else if(lookahead == TOKEN_NEW) {
    match(TOKEN_NEW);
    match(NAME);
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_OPEN_PARENTHESIS << " ou " << NAME << " ou " << TOKEN_REF
              << " ou " << TOKEN_DEREF << " ou " << FLOAT_LITERAL << " ou " << INT_LITERAL << " ou " << STRING_LITERAL << " ou "
              << TOKEN_TRUE << " ou " << TOKEN_FALSE << " ou " << TOKEN_NULL << " ou " << TOKEN_NEW << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void CallStmt() {
  if(lookahead == TOKEN_OPEN_PARENTHESIS) {
    match(TOKEN_OPEN_PARENTHESIS);
    CallArgs();
    match(TOKEN_CLOSE_PARENTHESIS);
  }
}

void CallArgs() {
  if(lookahead == TOKEN_OPEN_PARENTHESIS || lookahead == NAME ||
     lookahead == TOKEN_REF || lookahead == TOKEN_DEREF || 
     lookahead == FLOAT_LITERAL || lookahead == INT_LITERAL ||
     lookahead == STRING_LITERAL || lookahead == TOKEN_TRUE ||
     lookahead == TOKEN_FALSE || lookahead == TOKEN_NULL ||
     lookahead == TOKEN_NEW) {
    Exp();
    CallArgs_();
  }
}

void CallArgs_() {
  if(lookahead == TOKEN_COMMA) {
    match(TOKEN_COMMA);
    Exp();
    CallArgs_();
  }
}

void RefVar() {
  match(TOKEN_REF);
  match(TOKEN_OPEN_PARENTHESIS);
  Var2();
  match(TOKEN_CLOSE_PARENTHESIS);
}

void DerefVar() {
  match(TOKEN_DEREF);
  match(TOKEN_OPEN_PARENTHESIS);
  Var2();
  match(TOKEN_CLOSE_PARENTHESIS);
}

void Literal() {
  if(lookahead == FLOAT_LITERAL) {
    match(FLOAT_LITERAL);
  } else if(lookahead == INT_LITERAL) {
    match(INT_LITERAL);
  } else if(lookahead == STRING_LITERAL) {
    match(STRING_LITERAL);
  } else if(lookahead == TOKEN_TRUE || lookahead == TOKEN_FALSE) {
    BoolLiteral();
  } else if(lookahead == TOKEN_NULL) {
    match(TOKEN_NULL);
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << FLOAT_LITERAL << " ou " << INT_LITERAL << " ou " << STRING_LITERAL << " ou "
              << TOKEN_TRUE << " ou " << TOKEN_FALSE << " ou " << TOKEN_NULL << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void BoolLiteral() {
  if(lookahead == TOKEN_TRUE) {
    match(TOKEN_TRUE);
  } else if(lookahead == TOKEN_FALSE) {
    match(TOKEN_FALSE);
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_TRUE << " ou " << TOKEN_FALSE << 
              " mas encontrado " << scanner.YYText() << "\n";
    exit(1);
  }
}

void Var2() {
  if(lookahead == NAME) {
    match(NAME);
    Var2_();
  } else if (lookahead == TOKEN_NOT || lookahead == TOKEN_OPEN_PARENTHESIS ||
             lookahead == TOKEN_REF || lookahead == TOKEN_DEREF || 
             lookahead == FLOAT_LITERAL || lookahead == INT_LITERAL ||
             lookahead == STRING_LITERAL || lookahead == TOKEN_TRUE ||
             lookahead == TOKEN_FALSE || lookahead == TOKEN_NULL ||
             lookahead == TOKEN_NEW) {
    Exp2();
    match(TOKEN_DOT);
    match(NAME);
    Var2__();
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
            << numCols << ". Esperado token " << TOKEN_NOT << " ou " << TOKEN_OPEN_PARENTHESIS << " ou " << TOKEN_REF
              << " ou " << TOKEN_DEREF << " ou " << FLOAT_LITERAL << " ou " << INT_LITERAL << " ou " << STRING_LITERAL << " ou "
              << TOKEN_TRUE << " ou " << TOKEN_FALSE << " ou " << TOKEN_NULL << " ou " << TOKEN_NEW << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void Var2_() {
  if(lookahead == TOKEN_OR || lookahead == TOKEN_AND ||
     lookahead == TOKEN_COMP || lookahead == TOKEN_ADD ||
     lookahead == TOKEN_SUB || lookahead == TOKEN_DIV || 
     lookahead == TOKEN_MULT || lookahead == TOKEN_POT ||
     lookahead == TOKEN_EQUAL) {
    Exp3();
    match(TOKEN_DOT);
    match(NAME);
    Var2__();
  } else if(lookahead == TOKEN_DOT) {
    Var2__();
  }
}

void Var2__() {
  if(lookahead == TOKEN_DOT) {
    match(TOKEN_DOT);
    match(NAME);
    Var2__();
  }
}

void Exp2() {
  if(lookahead == TOKEN_NOT) {
    match(TOKEN_NOT);
    NotOp4();
  } else if(lookahead == TOKEN_OPEN_PARENTHESIS || lookahead == TOKEN_REF || 
             lookahead == TOKEN_DEREF || lookahead == FLOAT_LITERAL || 
             lookahead == INT_LITERAL || lookahead == STRING_LITERAL || 
             lookahead == TOKEN_TRUE || lookahead == TOKEN_FALSE || 
             lookahead == TOKEN_NULL || lookahead == TOKEN_NEW) {
    Fact2();
    Exp3();
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
            << numCols << ". Esperado token " << TOKEN_NOT << " ou " << TOKEN_OPEN_PARENTHESIS << " ou " << TOKEN_REF
              << " ou " << TOKEN_DEREF << " ou " << FLOAT_LITERAL << " ou " << INT_LITERAL << " ou " << STRING_LITERAL << " ou "
              << TOKEN_TRUE << " ou " << TOKEN_FALSE << " ou " << TOKEN_NULL << " ou " << TOKEN_NEW << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void Fact2() {
  if(lookahead == TOKEN_OPEN_PARENTHESIS) {
    match(TOKEN_OPEN_PARENTHESIS);
    Exp();
    match(TOKEN_CLOSE_PARENTHESIS);
  } else if(lookahead == TOKEN_REF) {
    RefVar();
  } else if(lookahead == TOKEN_DEREF) {
    DerefVar();
  } else if(lookahead == FLOAT_LITERAL || lookahead == INT_LITERAL ||
            lookahead == STRING_LITERAL || lookahead == TOKEN_TRUE ||
            lookahead == TOKEN_FALSE || lookahead == TOKEN_NULL) {
    Literal();
  } else if(lookahead == TOKEN_NEW) {
    match(TOKEN_NEW);
    match(NAME);
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
            << numCols << ". Esperado token " << TOKEN_OPEN_PARENTHESIS << " ou " << TOKEN_REF
              << " ou " << TOKEN_DEREF << " ou " << FLOAT_LITERAL << " ou " << INT_LITERAL << " ou " << STRING_LITERAL << " ou "
              << TOKEN_TRUE << " ou " << TOKEN_FALSE << " ou " << TOKEN_NULL << " ou " << TOKEN_NEW << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void Exp3() {
  OrOp3();
}

void OrOp3() {
  if(lookahead == TOKEN_OR) {
    match(TOKEN_OR);
    AndOp4();
    OrOp4_();
  } else if(lookahead == TOKEN_AND || lookahead == TOKEN_COMP ||
            lookahead == TOKEN_ADD || lookahead == TOKEN_SUB ||
            lookahead == TOKEN_DIV || lookahead == TOKEN_MULT ||
            lookahead == TOKEN_POT || lookahead == TOKEN_EQUAL) {
    AndOp3();
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_OR << " ou " << TOKEN_AND
              << " ou " << TOKEN_COMP << " ou " << TOKEN_EQUAL << " ou " << TOKEN_ADD << " ou " << TOKEN_SUB << " ou " << TOKEN_DIV << " ou "
              << TOKEN_MULT << " ou " << TOKEN_POT << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void AndOp3() {
  if(lookahead == TOKEN_AND) {
    match(TOKEN_AND);
    NotOp4();
    AndOp4_();
  } else if(lookahead == TOKEN_COMP || lookahead == TOKEN_ADD ||
            lookahead == TOKEN_SUB || lookahead == TOKEN_DIV || 
            lookahead == TOKEN_MULT || lookahead == TOKEN_POT ||
            lookahead == TOKEN_EQUAL) {
    ExpRel3();
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_AND
              << " ou " << TOKEN_COMP << " ou " << TOKEN_EQUAL << " ou " << TOKEN_ADD << " ou " << TOKEN_SUB << " ou " << TOKEN_DIV << " ou "
              << TOKEN_MULT << " ou " << TOKEN_POT << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void ExpRel3() {
  if(lookahead == TOKEN_COMP) {
    match(TOKEN_COMP);
    ExpArith4();
  } else if(lookahead == TOKEN_EQUAL){
    match(TOKEN_EQUAL);
    ExpArith4();
  } else if(lookahead == TOKEN_ADD || lookahead == TOKEN_SUB ||
            lookahead == TOKEN_DIV || lookahead == TOKEN_MULT ||
            lookahead == TOKEN_POT) {
    ExpArith3();
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_COMP << " ou " << TOKEN_EQUAL << " ou " << TOKEN_ADD << " ou " << TOKEN_SUB << " ou " << TOKEN_DIV << " ou "
              << TOKEN_MULT << " ou " << TOKEN_POT << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void ExpArith3() {
  if(lookahead == TOKEN_ADD) {
    match(TOKEN_ADD);
    Term4();
    ExpArith4_();
  } else if(lookahead == TOKEN_SUB) {
    match(TOKEN_SUB);
    Term4();
    ExpArith4_();
  } else if (lookahead == TOKEN_DIV || lookahead == TOKEN_MULT ||
            lookahead == TOKEN_POT) {
    Term3();
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_ADD << " ou " << TOKEN_SUB << " ou " << TOKEN_DIV << " ou "
              << TOKEN_MULT << " ou " << TOKEN_POT << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void Term3() {
  if(lookahead == TOKEN_DIV) {
    match(TOKEN_DIV);
    Pow4();
    Term4_();
  } else if(lookahead == TOKEN_MULT) {
    match(TOKEN_MULT);
    Pow4();
    Term4_();
  } else if(lookahead == TOKEN_POT) {
    Pow3();
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_DIV << " ou "
              << TOKEN_MULT << " ou " << TOKEN_POT << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void Pow3() {
  match(TOKEN_POT);
  Fact3();
  Pow4_();
}

void Fact3() {
  if(lookahead == TOKEN_OPEN_PARENTHESIS) {
    match(TOKEN_OPEN_PARENTHESIS);
    Exp();
    match(TOKEN_CLOSE_PARENTHESIS);
  } else if (lookahead == NAME) {
    match(NAME);
    CallStmt();
  } else if(lookahead == TOKEN_REF) {
    RefVar();
  } else if(lookahead == TOKEN_DEREF) {
    DerefVar();
  } else if(lookahead == FLOAT_LITERAL || lookahead == INT_LITERAL ||
            lookahead == STRING_LITERAL || lookahead == TOKEN_TRUE ||
            lookahead == TOKEN_FALSE || lookahead == TOKEN_NULL) {
    Literal();
  } else if(lookahead == TOKEN_NEW) {
    match(TOKEN_NEW);
    match(NAME);
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
            << numCols << ". Esperado token " << TOKEN_OPEN_PARENTHESIS << " ou " << NAME << " ou " << TOKEN_REF
              << " ou " << TOKEN_DEREF << " ou " << FLOAT_LITERAL << " ou " << INT_LITERAL << " ou " << STRING_LITERAL << " ou "
              << TOKEN_TRUE << " ou " << TOKEN_FALSE << " ou " << TOKEN_NULL << " ou " << TOKEN_NEW << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void Exp4() {
  AndOp4();
  OrOp4_();
}

void OrOp4_() {
  if(lookahead == TOKEN_OR) {
    match(TOKEN_OR);
    AndOp4();
    OrOp4_();
  }
}

void AndOp4() {
  NotOp4();
  AndOp4_();
}

void AndOp4_() {
  if(lookahead == TOKEN_AND) {
    match(TOKEN_AND);
    NotOp4();
    AndOp4_();
  }
}

 void NotOp4() {
  NotOp4_();
  ExpRel4();
}

void NotOp4_() {
  if(lookahead == TOKEN_NOT) {
    match(TOKEN_NOT);
    NotOp4_();
  }
}

void ExpRel4() {
  ExpArith4();
  ExpRel4_();
}

void ExpRel4_() {
  if(lookahead == TOKEN_COMP) {
    match(TOKEN_COMP);
    ExpArith4();
  } else if(lookahead == TOKEN_EQUAL) {
    match(TOKEN_EQUAL);
    ExpArith4();
  }
}

void ExpArith4() {
  Term4();
  ExpArith4_();
}

void ExpArith4_() {
  if(lookahead == TOKEN_ADD) {
    match(TOKEN_ADD);
    Term4();
    ExpArith4_();
  } else if(lookahead == TOKEN_SUB) {
    match(TOKEN_SUB);
    Term4();
    ExpArith4_();
  }
}

void Term4() {
  Pow4();
  Term4_();
}

void Term4_() {
  if(lookahead == TOKEN_MULT) {
    match(TOKEN_MULT);
    Pow4();
    Term4_();
  } else if(lookahead == TOKEN_DIV) {
    match(TOKEN_DIV);
    Pow4();
    Term4_();
  }
}

void Pow4() {
  // TODO: Trocar por Fact3.
  Fact4();
  Pow4_();
}

void Pow4_() {
  if(lookahead == TOKEN_POT) {
    match(TOKEN_POT);
    Pow4();
  }
}

// TODO: Trocar por Fact3.
void Fact4() {
  if(lookahead == TOKEN_OPEN_PARENTHESIS) {
    match(TOKEN_OPEN_PARENTHESIS);
    Exp();
    match(TOKEN_CLOSE_PARENTHESIS);
  } else if (lookahead == NAME) {
    match(NAME);
    CallStmt();
  } else if(lookahead == TOKEN_REF) {
    RefVar();
  } else if(lookahead == TOKEN_DEREF) {
    DerefVar();
  } else if(lookahead == FLOAT_LITERAL || lookahead == INT_LITERAL ||
            lookahead == STRING_LITERAL || lookahead == TOKEN_TRUE ||
            lookahead == TOKEN_FALSE || lookahead == TOKEN_NULL) {
    Literal();
  } else if(lookahead == TOKEN_NEW) {
    match(TOKEN_NEW);
    match(NAME);
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
            << numCols << ". Esperado token " << TOKEN_OPEN_PARENTHESIS << " ou " << NAME << " ou " << TOKEN_REF
              << " ou " << TOKEN_DEREF << " ou " << FLOAT_LITERAL << " ou " << INT_LITERAL << " ou " << STRING_LITERAL << " ou "
              << TOKEN_TRUE << " ou " << TOKEN_FALSE << " ou " << TOKEN_NULL << " ou " << TOKEN_NEW << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void Stmt_() {
  if(lookahead == TOKEN_OPEN_PARENTHESIS) {
    match(TOKEN_OPEN_PARENTHESIS);
    CallArgs();
    match(TOKEN_CLOSE_PARENTHESIS);
  } else if(lookahead == TOKEN_OR || lookahead == TOKEN_AND ||
            lookahead == TOKEN_COMP || lookahead == TOKEN_ADD ||
            lookahead == TOKEN_SUB || lookahead == TOKEN_DIV || 
            lookahead == TOKEN_MULT || lookahead == TOKEN_POT ||
            lookahead == TOKEN_DOT || lookahead == TOKEN_ATTRIBUTION ||
            lookahead == TOKEN_EQUAL) {
    Var2_();
    AssignStmt();
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_OPEN_PARENTHESIS << " ou " << TOKEN_OR << " ou " << TOKEN_AND
              << " ou " << TOKEN_COMP << " ou " << TOKEN_EQUAL << " ou " << TOKEN_ADD << " ou " << TOKEN_SUB << " ou " << TOKEN_DIV << " ou "
              << TOKEN_MULT << " ou " << TOKEN_POT << " ou " << TOKEN_DOT << " ou " << TOKEN_ATTRIBUTION << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void StmtDeref_() {
  if(lookahead == TOKEN_OR || lookahead == TOKEN_AND ||
     lookahead == TOKEN_COMP || lookahead == TOKEN_ADD ||
     lookahead == TOKEN_SUB || lookahead == TOKEN_DIV || 
     lookahead == TOKEN_MULT || lookahead == TOKEN_POT ||
     lookahead == TOKEN_EQUAL) {
    Exp3();
    match(TOKEN_DOT);
    match(NAME);
    Var2__();
  }
}

void AssignStmt() {
  match(TOKEN_ATTRIBUTION);
  Exp();
}

void Exp5() {
  if(lookahead == TOKEN_NOT) {
    match(TOKEN_NOT);
    NotOp4();
  } else if(lookahead == TOKEN_OPEN_PARENTHESIS || lookahead == TOKEN_REF ||
            lookahead == FLOAT_LITERAL || lookahead == INT_LITERAL ||
            lookahead == STRING_LITERAL || lookahead == TOKEN_TRUE ||
            lookahead == TOKEN_FALSE || lookahead == TOKEN_NULL || 
            lookahead == TOKEN_NEW) {
    Fact5();
    Exp3();
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_NOT << " ou " << TOKEN_OPEN_PARENTHESIS << " ou " << TOKEN_REF
              << " ou " << FLOAT_LITERAL << " ou " << INT_LITERAL << " ou " << STRING_LITERAL << " ou "
              << TOKEN_TRUE << " ou " << TOKEN_FALSE << " ou " << TOKEN_NULL << " ou " << TOKEN_NEW << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void Fact5() {
  if(lookahead == TOKEN_OPEN_PARENTHESIS) {
    match(TOKEN_OPEN_PARENTHESIS);
    Exp();
    match(TOKEN_CLOSE_PARENTHESIS);
  } else if(lookahead == TOKEN_REF) {
    RefVar();
  } else if(lookahead == lookahead == FLOAT_LITERAL || lookahead == INT_LITERAL ||
            lookahead == STRING_LITERAL || lookahead == TOKEN_TRUE ||
            lookahead == TOKEN_FALSE || lookahead == TOKEN_NULL) {
    Literal();
  } else if(lookahead == TOKEN_NEW) {
    match(TOKEN_NEW);
    match(NAME);
  } else {
    std::cerr << "Erro sintático na linha " << numLines << ", coluna "
              << numCols << ". Esperado token " << TOKEN_OPEN_PARENTHESIS << " ou "  << TOKEN_REF
              << " ou " << FLOAT_LITERAL << " ou " << INT_LITERAL << " ou " << STRING_LITERAL << " ou "
              << TOKEN_TRUE << " ou " << TOKEN_FALSE << " ou " << TOKEN_NULL << " ou " << TOKEN_NEW << " mas encontrado "
              << scanner.YYText() << "\n";
    exit(1);
  }
}

void IfStmt() {
  match(TOKEN_IF);
  Exp();
  match(TOKEN_THEN);
  StmtList();
  ElseStmt();
  match(TOKEN_FI);
}

void ElseStmt() {
  if(lookahead == TOKEN_ELSE) {
    match(TOKEN_ELSE);
    StmtList();
  }
}

void WhileStmt() {
  match(TOKEN_WHILE);
  Exp();
  match(TOKEN_DO);
  StmtList();
  match(TOKEN_OD);
}

void ReturnStmt() {
  match(TOKEN_RETURN);
  match(TOKEN_OPEN_PARENTHESIS);
  Exp();
  match(TOKEN_CLOSE_PARENTHESIS);
}