%{
#include <stdio.h>
#include <stdlib.h>

// Declarações auxiliares (como ast, etc.) podem ser colocadas aqui
%}

/* Declaração de tokens */
%token PROGRAM ID BEGIN END VAR COLON ASSIGN PROCEDURE STRUCT OF
%token COMMA SEMICOLON LPAREN RPAREN LBRACE RBRACE
%token IF THEN ELSE FI WHILE DO OD RETURN
%token TRUE FALSE NULL_LITERAL
%token FLOAT_LIT INT_LIT STRING_LIT
%token AND OR NOT LT LE GT GE EQ NE
%token PLUS MINUS TIMES DIVIDE POWER
%token NEW REF DEREF

/* Tipos para valores semânticos podem ser declarados aqui */
%start program

%%

program
    : PROGRAM ID BEGIN decl_block END
    ;

decl
    : var_decl
    | proc_decl
    | rec_decl
    | enum_decl
    ;

var_decl
    : VAR ID COLON type var_decl2
    | VAR ID ASSIGN exp
    ;

var_decl2
    : ASSIGN exp
    | /* vazio */
    ;

proc_decl
    : PROCEDURE ID LPAREN params RPAREN pdt BEGIN pd2 stmt_list END
    ;

rec_decl
    : STRUCT ID LBRACE params RBRACE
    ;

params
    : pf_decl pd
    | /* vazio */
    ;

pd
    : COMMA pf_decl pd
    | SEMICOLON pf_decl pd
    | /* vazio */
    ;

pdt
    : COLON type
    | /* vazio */
    ;

pd2
    : decl_block IN
    | /* vazio */
    ;

decl_block
    : decl decl_block2
    | /* vazio */
    ;

decl_block2
    : SEMICOLON decl decl_block2
    | /* vazio */
    ;

enum_decl
    : ID EQ LBRACE ID enum_field RBRACE OF type
    ;

enum_field
    : COMMA ID enum_field
    | /* vazio */
    ;

pf_decl
    : ID COLON type
    ;

stmt_list
    : stmt stmt_list2
    | /* vazio */
    ;

stmt_list2
    : SEMICOLON stmt stmt_list2
    | /* vazio */
    ;

exp
    : exp LOG_OP exp
    | NOT exp
    | exp REL_OP exp
    | exp ARITH_OP exp
    | literal
    | call_stmt
    | NEW name
    | var
    | ref_var
    | deref_var
    | LPAREN exp RPAREN
    ;

ref_var
    : REF LPAREN var RPAREN
    ;

deref_var
    : DEREF LPAREN var RPAREN
    | DEREF LPAREN deref_var RPAREN
    ;

var
    : name
    | exp '.' name
    ;

literal
    : FLOAT_LIT
    | INT_LIT
    | STRING_LIT
    | BOOL_LIT
    | NULL_LITERAL
    ;

bool_lit
    : TRUE
    | FALSE
    ;

stmt
    : assign_stmt
    | if_stmt
    | while_stmt
    | return_stmt
    | call_stmt
    ;

assign_stmt
    : var ASSIGN exp
    | deref_var ASSIGN exp
    ;

if_stmt
    : IF exp THEN stmt_list if_stmt2 FI
    ;

if_stmt2
    : ELSE stmt_list
    | /* vazio */
    ;

while_stmt
    : WHILE exp DO stmt_list OD
    ;

return_stmt
    : RETURN return_stmt2
    ;

return_stmt2
    : exp
    | /* vazio */
    ;

call_stmt
    : name LPAREN call_args RPAREN
    ;

call_args
    : exp call_args2
    | /* vazio */
    ;

call_args2
    : COMMA exp call_args2
    | /* vazio */
    ;

type
    : FLOAT
    | INT
    | STRING
    | BOOL
    | name
    | REF LPAREN type RPAREN
    ;

name
    : ID
    ;

LOG_OP
    : AND
    | OR
    ;

REL_OP
    : LT
    | LE
    | GT
    | GE
    | EQ
    | NE
    ;

ARITH_OP
    : PLUS
    | MINUS
    | TIMES
    | DIVIDE
    | POWER
    ;

%%

int main() {
    return yyparse();
}

void yyerror(const char *s) {
    fprintf(stderr, "Erro: %s\n", s);
}
