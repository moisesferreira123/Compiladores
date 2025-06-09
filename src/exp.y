%{
#include <iostream>
#include <typeinfo>
#include "symbol_table.hpp"

extern int numLines;
extern int numCols;
extern SymbolTable symbolTable;

int yylex(void);
void yyerror(char const* s);

typedef enum {
   TYPE_NAME,
   TYPE_VOID,
   TYPE_INT,
   TYPE_FLOAT,
   TYPE_BOOL,
   TYPE_STRING,
   TYPE_REF
} TypeKind;

typedef struct {
   TypeKind kind;
   char* name;
   struct Type* ref;
} Type;

std::string getType(Type* type);

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
    Procedure procedure;
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

%start program

/// Associação dos não terminais aos tipos
%type <type> type
%type <type> return_type
%type <type> paramfield_decl
%type <procedure> procedure_decl

%%
   program:
      TOKEN_PROGRAM NAME {
         Symbol sym = Program(std::string($2));
         symbolTable.insert(sym);
         free($2);
    } TOKEN_BEGIN decl_block TOKEN_END 
    ;

   decl: // Declaration
      var_decl
      | procedure_decl
      | record_decl
      | enum_decl
      ;
   
   var_decl: // Variable declaration
      TOKEN_VAR NAME TOKEN_COLON type var_decl2 
      | TOKEN_VAR NAME TOKEN_ATTRIBUTION exp;


   var_decl2: // Variable declaration two
      exp
      | /*Vazio*/
      ;

   procedure_decl: // Procedure declaration
      TOKEN_PROCEDURE NAME {
         $$ = Procedure(std::string($2));
         symbolTable.enterScope();
      } TOKEN_OPEN_PARENTHESIS procedure_params  TOKEN_CLOSE_PARENTHESIS return_type {
         $$->setType(getType($7))
      } TOKEN_BEGIN scope_declarations stmt_list TOKEN_END {
         symbolTable.exitScope();
         symbolTable.insert($$);
      }
      ;
   
   record_decl: // Record declaration
      TOKEN_STRUCT NAME TOKEN_OPEN_BRACES record_fields TOKEN_CLOSE_BRACES
      ;

   procedure_params: // Procedure params
      paramfield_decl procedure_params2 
      | 
      ;

   record_fields: // Record fields
      paramfield_decl record_fields2
      | 
      ;

   procedure_params2: // Procedure params two
      TOKEN_COMMA paramfield_decl procedure_params2
      | 
      ;

   record_fields2: // Record field two
      TOKEN_SEMICOLON paramfield_decl record_fields2
      |
      ;

   return_type: // Return type
      TOKEN_COLON type {
         $$ = $2
      }
      | {
         $$ = new Type;
         $$->kind = TYPE_VOID;
         $$->name = nullptr;
         $$->ref = nullptr;
      }
      ;

   scope_declarations: // Scope declarations
      decl_block TOKEN_IN
      | 
      ;

   decl_block: // Declaration block
      decl decl_block2
      |
      ;

   decl_block2: // Declaration block two
      TOKEN_SEMICOLON decl decl_block2
      | 
      ;

   enum_decl: // Enum declaration
      TOKEN_ENUM NAME TOKEN_EQUAL TOKEN_OPEN_BRACES NAME enum_field TOKEN_CLOSE_BRACES
      ;

   enum_field: // Enum field
      TOKEN_COMMA NAME enum_field 
      | 
      ;

   paramfield_decl: // Param field declaration
      NAME TOKEN_COLON type {
         $$ = $3;

         VariableType type;
         if ($3->kind == TYPE_NAME) {
            Symbol* symName = symbolTable.lookup(std::string($3->name));

            if (!symName || symName) /// Verificar se é tipo struct ou enum (typeid)
         }
         Symbol sym = Variable(std::string($1),  ,getType($3))
      }
      ;

   stmt_list: // Statement list
      stmt stmt_list2
      |
      ;

   stmt_list2: // Statement list two
      TOKEN_SEMICOLON stmt stmt_list2
      |
      ;

   exp: // Expression
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

   ref_var: // Reference variable
      TOKEN_REF TOKEN_OPEN_PARENTHESIS var TOKEN_CLOSE_PARENTHESIS
      ;

   deref_var: // Dereference variable
      TOKEN_DEREF TOKEN_OPEN_PARENTHESIS var TOKEN_CLOSE_PARENTHESIS
      | TOKEN_DEREF TOKEN_OPEN_PARENTHESIS deref_var TOKEN_CLOSE_PARENTHESIS
      ;

   var: // Variable
      NAME
      | exp TOKEN_DOT NAME
      ;

   literal: // Literal
      FLOAT_LITERAL
      | INT_LITERAL
      | STRING_LITERAL
      | bool_literal
      | TOKEN_NULL
      ;

   bool_literal: // Bool literal
      TOKEN_TRUE
      | TOKEN_FALSE
      ;

   stmt: // Statement
      assign_stmt
      | if_stmt
      | while_stmt
      | return_stmt
      | call_stmt
      ;

   assign_stmt: // Assign statement
      var TOKEN_ATTRIBUTION exp
      | deref_var TOKEN_ATTRIBUTION exp
      ;

   if_stmt: // If statement
      TOKEN_IF exp TOKEN_THEN stmt_list if_stmt2 TOKEN_FI
      ;

   if_stmt2: // If statement two
      TOKEN_ELSE stmt_list
      |
      ;

   while_stmt: // While statement
      TOKEN_WHILE exp TOKEN_DO stmt_list TOKEN_OD
      ;

   return_stmt: // Return statement
      TOKEN_RETURN return_stmt2
      ;

   return_stmt2: // Return statement two
      exp
      |
      ;

   call_stmt: // Call procedure statement
      NAME TOKEN_OPEN_PARENTHESIS call_args TOKEN_CLOSE_PARENTHESIS
      ;

   call_args: // Call args
      exp call_args2
      |
      ;

   call_args2: // Call args two
      TOKEN_COMMA exp call_args2
      |
      ;

   type: // Type
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
         if (!sym || (sym->getType() != VariableType::STRUCT && sym->getType() != VariableType::ENUM)) {
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

std::string getType(Type* type) {
   if (type->kind == TYPE_INT) {
      return "int";
   } else if (type->kind == TYPE_FLOAT) {
      return "float";
   } else if (type->kind == TYPE_BOOL) {
      return "bool";
   } else if (type->kind == TYPE_STRING) {
      return "string";
   } else if (type->kind == TYPE_VOID) {
      return "void";
   } else if (type->kind == TYPE_NAME) {
      return type->name;
   }

   return "*" + getType(type->ref);
}