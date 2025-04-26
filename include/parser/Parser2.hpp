#ifndef PARSER_HPP
#define PARSER_HPP

#include "Tokens.hpp"
#include <iostream>

extern int numLines, numCols;
extern int lookahead; // Armazena o token atual

void advance();
void match(int expected);

void Program();
void ProgramDecl();
void ProgramDecl_();
void Decl();
void VarDecl();
void VarDecl_();
void VarExpDecl();
void ProcDecl();
void ProcParamFieldDecl();
void ProcParamFieldDecl_();
void ProcTypeDecl();
void ProcDeclDecl();
void RecDecl();
void RecParamFieldDecl();
void RecParamFieldDecl_();
void EnumDecl();
void EnumFieldDecl();
void ParamFieldDecl();
void StmtList();
void StmtList_();
void Exp();
void OrOp_();
void AndOp();
void AndOp_();
void NotOp();
void NotOp_();
void ExpRel();
void ExpRel_();
void ExpArith();
void ExpArith_();
void Term();
void Term_();
void Pow();
void Pow_();
void Var();
void Var_();
void Fact();
void CallStmt();
void CallArgs();
void CallArgs_();
void RefVar();
void DerefVar();
// É chamado no DerefVar.
// void DerefVar_();
void Literal();
void BoolLiteral();
// Eu não criei essa função. Fiz direto.
// void RelOp();
void Var2();
void Var2_();
void Var2__();
void Exp2();
void Fact2();
void Exp3();
void OrOp3();
void AndOp3();
void ExpRel3();
void ExpArith3();
void Term3();
void Pow3();
void Fact3();
void Exp4();
void OrOp4_();
void AndOp4();
void AndOp4_();
void NotOp4();
void NotOp4_();
void ExpRel4();
void ExpRel4_();
void ExpArith4();
void ExpArith4_();
void Term4();
void Term4_();
void Pow4();
void Pow4_();
void Fact4();
void Stmt();
void Stmt_();
void StmtDeref_();
void AssignStmt();
void Exp5();
void Fact5();
void IfStmt();
void ElseStmt();
void WhileStmt();
void ReturnStmt();
void Type();

#endif // PARSER_HPP