%{
#include <iostream>
#include "symbol_table.hpp"

extern int numLines;
extern int numCols;
extern SymbolTable symbolTable;

int yylex(void);
void yyerror(char const* s);

typedef enum {
   TYPE_NAME,
   TYPE_INT,
   TYPE_FLOAT,
   TYPE_BOOL,
   TYPE_REF
} TypeKind;

typedef struct {
   TypeKind kind;
   char* name;
   struct Type* ref;
} Type;

typedef struct {
   Type type;
} Expr;
%}

%union {
    int ival;
    float fval;
    char* nval;
    char* sval;
    Type type;
    Expr expr;
}

/// TOKENS
%token <ival> INT_LITERAL
%token <fval> FLOAT_LITERAL
%token <sval> STRING_LITERAL
%token <nval> NAME
%token TOKEN_BOOL TOKEN_PROGRAM TOKEN_PROCEDURE
%token TOKEN_BEGIN TOKEN_END TOKEN_VAR TOKEN_IN TOKEN_STRUCT  TOKEN_NULL
%token TOKEN_NEW TOKEN_REF TOKEN_DEREF TOKEN_TRUE TOKEN_FALSE TOKEN_IF TOKEN_THEN
%token TOKEN_ELSE TOKEN_FI TOKEN_WHILE TOKEN_DO TOKEN_OD TOKEN_RETURN TOKEN_ENUM
%token TOKEN_ATTRIBUTION TOKEN_COLON TOKEN_OPEN_PARENTHESIS TOKEN_OF
%token TOKEN_CLOSE_PARENTHESIS TOKEN_SEMICOLON TOKEN_COMMA TOKEN_OPEN_BRACES
%token TOKEN_CLOSE_BRACES TOKEN_CIPHER TOKEN_ERROR
%token TOKEN_INT TOKEN_FLOAT TOKEN_STRING

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

/// Associação dos não terminais aos tipos
%type <type> type

%%
   prog:
      TOKEN_PROGRAM NAME {
         Symbol sym = Symbol(std::string($2), SymbolType::PROGRAM);
         symbolTable.insert(sym);
         free($2);
    } TOKEN_BEGIN decl_block TOKEN_END 
    ;

   decl:
      var_decl
      | proc_decl
      | rec_decl
      | enum_decl
      ;
   
   var_decl:
      TOKEN_VAR NAME {
        Symbol sym = Symbol(std::string($2), SymbolType::VARIABLE);
        symbolTable.insert(sym);
        free($2);    
      } TOKEN_COLON type var_decl2 
      | TOKEN_VAR NAME {
        Symbol sym = Symbol(std::string($2), SymbolType::VARIABLE);
        symbolTable.insert(sym);
        free($2);    
      } TOKEN_ATTRIBUTION exp;


   var_decl2:
      exp
      | /*Vazio*/
      ;

   proc_decl:
      TOKEN_PROCEDURE NAME {
         Symbol sym = Symbol(std::string($2), SymbolType::PROCEDURE);
         symbolTable.insert(sym);
         free($2);
         symbolTable.enterScope();
      } TOKEN_OPEN_PARENTHESIS params TOKEN_CLOSE_PARENTHESIS pdt TOKEN_BEGIN pd2 stmt_list TOKEN_END {
         symbolTable.exitScope();
      }
      ;
   
   rec_decl:
      TOKEN_STRUCT NAME {
         Symbol sym = Symbol(std::string($2), SymbolType::STRUCT);
         symbolTable.insert(sym);
         free($2);
         symbolTable.enterScope();
      } TOKEN_OPEN_BRACES params TOKEN_CLOSE_BRACES {
         symbolTable.exitScope();
      }
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
      TOKEN_ENUM NAME {
         Symbol sym = Symbol(std::string($2), SymbolType::ENUM);
         symbolTable.insert(sym);
         free($2);
      } TOKEN_EQUAL TOKEN_OPEN_BRACES NAME {
         Symbol sym = Symbol(std::string($6), SymbolType::VARIABLE);
         symbolTable.insert(sym);
         free($6);
      } enum_field TOKEN_CLOSE_BRACES TOKEN_OF type
      ;

   enum_field:
      TOKEN_COMMA NAME {
         Symbol sym = Symbol(std::string($2), SymbolType::VARIABLE);
         symbolTable.insert(sym);
         free($2);
      } enum_field 
      | 
      ;

   pf_decl:
      NAME {
         Symbol sym = Symbol(std::string($1), SymbolType::VARIABLE);
         symbolTable.insert(sym);
         free($1);
      } TOKEN_COLON type
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
      | TOKEN_NEW NAME {
         auto sym = symbolTable.lookup(std::string($2));
         if (!sym || (sym->type != SymbolType::STRUCT && sym->type != SymbolType::ENUM)) {
            yyerror(("Tipo não declarado ou inválido para NEW: " + std::string($2)).c_str());
         }
         free($2);
      }
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
      NAME {
         auto sym = symbolTable.lookup(std::string($1));
         if (!sym || sym->type != SymbolType::VARIABLE) {
            yyerror(("Identificador não declarado: " + std::string($1)).c_str());
         }
         free($1);
      }
      | exp TOKEN_DOT NAME {
         auto sym = symbolTable.lookup(std::string($3));
         if (!sym) {
            yyerror(("Identificador não declarado: " + std::string($3)).c_str());
         }
         free($3);
      }
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
      NAME {
         auto sym = symbolTable.lookup(std::string($1));
         if (!sym || sym->type != SymbolType::PROCEDURE) {
            yyerror(("Identificador não declarado: " + std::string($1)).c_str());
         }
         free($1);
      } TOKEN_OPEN_PARENTHESIS call_args TOKEN_CLOSE_PARENTHESIS
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
      TOKEN_FLOAT {
         $$ = new Type;
         $$->kind = TYPE_FLOAT;
         $$->name = nullptr;
         $$->ref = nullptr;
      }
    | TOKEN_INT {
         $$ = new Type;
         $$->kind = TYPE_INT;
         $$->name = nullptr;
         $$->ref = nullptr;
      }
    | TOKEN_STRING {
         $$ = new Type;
         $$->kind = TYPE_STRING;
         $$->name = nullptr;
         $$->ref = nullptr;
      }
    | TOKEN_BOOL {
         $$ = new Type;
         $$->kind = TYPE_BOOL;
         $$->name = nullptr;
         $$->ref = nullptr;
      }
    | NAME {
         auto sym = symbolTable.lookup(std::string($1));
         if (!sym || (sym->type != SymbolType::STRUCT && sym->type != SymbolType::ENUM)) {
            yyerror(("Tipo não declarado ou inválido para type: " + std::string($1)).c_str());
         }
         $$ = new Type;
         $$->kind = TYPE_NAME;
         $$->name = $1;
         $$->ref = nullptr;
      }
    | TOKEN_REF TOKEN_OPEN_PARENTHESIS type TOKEN_CLOSE_PARENTHESIS {
         $$ = new Type;
         $$->kind = TYPE_REF;
         $$->name = nullptr;
         $$->ref = $3;  // guarda o type referenciado
      }
    ;

%%

void yyerror(const char* s) {
    std::cerr << "Erro: " << s << " na linha " << numLines << ", coluna " << numCols << std::endl;
}
