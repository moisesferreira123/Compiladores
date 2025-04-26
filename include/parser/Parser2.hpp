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
void AndOp();
void OrOp_();
void NotOp();
void AndOp_();
void NotOp_();
void ExpRel();
void ExpArith();
void ExpRel_();
void Term();
void ExpArith_();
void Pow();
void Term_();
void Var();
void Pow_();
void Fact();
void Var_();
void CallStmt();
void CallArgs();
void CallArgs_();
void RefVar();
void DerefVar();
void Literal();
void BoolLiteral();
void Var2_();
void Var2__();
void Exp2();
void NotOp4();
void Fact2();
void Exp3();
void OrOp3();
void Stmt();
void Stmt_();
void StmtDeref_();
void AssignStmt();
void IfStmt();
void WhileStmt();
void ReturnStmt();
void Type();
void Exp5();

#endif // PARSER_HPP