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
void DerefVar();
void Var2_();
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