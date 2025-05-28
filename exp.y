%{
#include <iostream>

extern int numLines;
extern int numCols;

int yylex(void);
void yyerror(char const* s);
%}

/// TOKENS
%token TOKEN_INT TOKEN_FLOAT TOKEN_STRING TOKEN_BOOL TOKEN_PROGRAM TOKEN_PROCEDURE
%token TOKEN_BEGIN TOKEN_END TOKEN_VAR TOKEN_IN TOKEN_STRUCT  TOKEN_NULL
%token TOKEN_NEW TOKEN_REF TOKEN_DEREF TOKEN_TRUE TOKEN_FALSE TOKEN_IF TOKEN_THEN
%token TOKEN_ELSE TOKEN_FI TOKEN_WHILE TOKEN_DO TOKEN_OD TOKEN_RETURN TOKEN_ENUM
%token TOKEN_ATTRIBUTION TOKEN_COLON TOKEN_OPEN_PARENTHESIS TOKEN_OF
%token TOKEN_CLOSE_PARENTHESIS TOKEN_SEMICOLON TOKEN_COMMA TOKEN_OPEN_BRACES
%token TOKEN_CLOSE_BRACES TOKEN_CIPHER TOKEN_ERROR
%token NAME INT_LITERAL FLOAT_LITERAL STRING_LITERAL 

/// PRECEDÊNCIA
%left TOKEN_OR
%left TOKEN_AND
%right TOKEN_NOT
%left TOKEN_COMP TOKEN_EQUAL  
%left TOKEN_ADD TOKEN_SUB
%left TOKEN_MULT TOKEN_DIV
%right TOKEN_POT
%left TOKEN_DOT
%right UMINUS

%start prog

%%
   prog:
      TOKEN_PROGRAM NAME TOKEN_BEGIN decl_block TOKEN_END
      ;

   decl:
      var_decl
      | proc_decl
      | rec_decl
      | enum_decl
      ;
   
   var_decl:
      TOKEN_VAR NAME TOKEN_COLON type var_decl2
      | TOKEN_VAR NAME TOKEN_ATTRIBUTION exp
      ;

   var_decl2:
      exp
      | /*Vazio*/
      ;

   proc_decl:
      TOKEN_PROCEDURE NAME TOKEN_OPEN_PARENTHESIS params TOKEN_CLOSE_PARENTHESIS pdt TOKEN_BEGIN pd2 stmt_list TOKEN_END
      ;
   
   rec_decl:
      TOKEN_STRUCT NAME TOKEN_OPEN_BRACES params TOKEN_CLOSE_BRACES
      ;

   params:
      pf_decl pd 
      | 
      ;

   pd:
      TOKEN_COMMA pf_decl pd
      | TOKEN_SEMICOLON pf_decl pd
      | 
      ;

   pdt:
      TOKEN_COLON type
      | 
      ;

   pd2:
      decl_block TOKEN_IN
      | 
      ;

   decl_block:
      decl decl_block2
      |
      ;

   decl_block2:
      TOKEN_SEMICOLON decl decl_block2
      | 
      ;

   enum_decl: 
      TOKEN_ENUM NAME TOKEN_EQUAL TOKEN_OPEN_BRACES NAME enum_field TOKEN_CLOSE_BRACES TOKEN_OF type
      ;

   enum_field:
      TOKEN_COMMA NAME enum_field
      | 
      ;

   pf_decl:
      NAME TOKEN_COLON type
      ;

   stmt_list:
      stmt stmt_list2
      |
      ;

   stmt_list2:
      TOKEN_SEMICOLON stmt stmt_list2
      |
      ;

   exp:
      exp TOKEN_AND exp
      | exp TOKEN_OR exp
      | TOKEN_NOT exp
      | exp TOKEN_COMP exp
      | exp TOKEN_EQUAL exp
      | exp TOKEN_ADD exp
      | exp TOKEN_SUB exp
      | exp TOKEN_MULT exp
      | exp TOKEN_DIV exp
      | exp TOKEN_POT exp
      | literal
      | call_stmt
      | TOKEN_NEW NAME
      | var
      | ref_var
      | deref_var
      | TOKEN_OPEN_PARENTHESIS exp TOKEN_CLOSE_PARENTHESIS
      | TOKEN_SUB exp %prec UMINUS
      ;

   ref_var:
      TOKEN_REF TOKEN_OPEN_PARENTHESIS var TOKEN_CLOSE_PARENTHESIS
      ;

   deref_var:
      TOKEN_DEREF TOKEN_OPEN_PARENTHESIS var TOKEN_CLOSE_PARENTHESIS
      | TOKEN_DEREF TOKEN_OPEN_PARENTHESIS deref_var TOKEN_CLOSE_PARENTHESIS
      ;

   var:
      NAME
      | exp TOKEN_DOT NAME
      ;

   literal:
      FLOAT_LITERAL
      | INT_LITERAL
      | STRING_LITERAL
      | bool_literal
      | TOKEN_NULL
      ;

   bool_literal:
      TOKEN_TRUE
      | TOKEN_FALSE
      ;

   stmt: 
      assign_stmt
      | if_stmt
      | while_stmt
      | return_stmt
      | call_stmt
      ;

   assign_stmt:
      var TOKEN_ATTRIBUTION exp
      | deref_var TOKEN_ATTRIBUTION exp
      ;

   if_stmt:
      TOKEN_IF exp TOKEN_THEN stmt_list if_stmt2 TOKEN_FI
      ;

   if_stmt2:
      TOKEN_ELSE stmt_list
      |
      ;

   while_stmt:
      TOKEN_WHILE exp TOKEN_DO stmt_list TOKEN_OD
      ;

   return_stmt: 
      TOKEN_RETURN return_stmt2
      ;

   return_stmt2:
      exp
      |
      ;

   call_stmt:
      NAME TOKEN_OPEN_PARENTHESIS call_args TOKEN_CLOSE_PARENTHESIS
      ;

   call_args:
      exp call_args2
      |
      ;

   call_args2:
      TOKEN_COMMA exp call_args2
      |
      ;

   type:
      TOKEN_FLOAT
      | TOKEN_INT
      | TOKEN_STRING
      | TOKEN_BOOL
      | NAME
      | TOKEN_REF TOKEN_OPEN_PARENTHESIS type TOKEN_CLOSE_PARENTHESIS
      ;

%%

void yyerror(const char* s) {
    std::cerr << "Erro: " << s << " na linha " << numLines << ", coluna " << numCols << std::endl;
}
