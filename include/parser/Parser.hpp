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
void RecDecl();
void EnumDecl();
void Exp();
void Type();

#endif // PARSER_HPP