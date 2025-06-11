%{
#include <iostream>
#include <typeinfo>
#include "symbol_table.hpp"
#include <vector>

extern int numLines;
extern int numCols;
extern SymbolTable symbolTable;

int yylex(void);
void yyerror(char const* s);
bool isSpecialType(Symbol* sym);
bool isVariable(Symbol* sym);
bool isStruct(Symbol* sym);
bool isProcedure(Symbol* sym);

typedef enum {
   TYPE_NAME,
   TYPE_VOID,
   TYPE_INT,
   TYPE_FLOAT,
   TYPE_BOOL,
   TYPE_STRING,
   TYPE_NULL,
   TYPE_REF
} TypeKind;

typedef struct {
   TypeKind kind;
   char* name;
   struct Type* ref;
} Type;

std::string getType(Type* type);
Type* createPrimitiveType(TypeKind kind);
Type* createNonPrimitiveType(std::string name);
Type* createReferenceType(Type* refType);
Type* createTypeByString(std::string name);

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
    std::vector<Type> args;
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
%type <type> literal
%type <type> var
%type <type> exp
%type <type> call_stmt
%type <args> call_args
%type <args> call_args2
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
      TOKEN_ATTRIBUTION exp
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

            if (nonIsSpecialType(symName)) {

            } /// Verificar se é tipo struct ou enum (typeid)
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
      NAME {
         auto sym = symbolTable.lookup(std::string($1));
         if (!isVariable(sym)) {
            yyerror(("Simbolo não encontrado: " + std::string($1)).c_str());
         }
         $$ = createTypeByString(sym->getKind());
      }
      | exp TOKEN_DOT NAME {
         if ($1->kind == TYPE_NAME) {
            Symbol* symName = symbolTable.lookup(std::string($1->name));

            if (!isStruct(symName)) {
               yyerror(("Tipo não declarado ou inválido para var: " + getType($1)).c_str());
            }

            auto fields = symName->getFields();
            if (fields.find(std::string($3)) == fields.end()) {
               yyerror(("Campo não declarado para: " + getType($1)).c_str());
            }
            
            $$ = createTypeByString(fields[std::string($3)]);
         } else {
            yyerror(("Tipo não inválido para var: " + getType($1)).c_str());
         }
      }
      ;

   literal: // Literal
      FLOAT_LITERAL {
         $$ = createPrimitiveType(TYPE_FLOAT);
      }
      | INT_LITERAL {
         $$ = createPrimitiveType(TYPE_INT);
      }
      | STRING_LITERAL  {
         $$ = createPrimitiveType(TYPE_STRING);
      }
      | bool_literal {
         $$ = createPrimitiveType(TYPE_BOOL);
      }
      | TOKEN_NULL {
         $$ = createPrimitiveType(TYPE_NULL);
      }
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
      TOKEN_IF exp {
         if ($2->kind != TYPE_BOOL) {
            yyerror(("Tipo inválido para if: " + getType($2)).c_str());
         }
      } TOKEN_THEN stmt_list if_stmt2 TOKEN_FI
      ;

   if_stmt2: // If statement two
      TOKEN_ELSE stmt_list
      |
      ;

   while_stmt: // While statement
      TOKEN_WHILE exp {
         if ($2->kind != TYPE_BOOL) {
            yyerror(("Tipo inválido para while: " + getType($2)).c_str());
         }
      } TOKEN_DO stmt_list TOKEN_OD
      ;

   return_stmt: // Return statement
      TOKEN_RETURN return_stmt2
      ;

   return_stmt2: // Return statement two
      exp
      |
      ;

   call_stmt: // Call procedure statement
      NAME TOKEN_OPEN_PARENTHESIS call_args TOKEN_CLOSE_PARENTHESIS {
         auto sym = symbolTable.lookup(std::string($1));

         if (!isProcedure(sym)) {
            yyerror(("Procedimento não declarado: " + std::string($1)).c_str());
         }

         auto procedureTypes = sym->getParams();

         if (procedureTypes.size() != $3.size()) {
            yyerror(("Quantidade de parâmetros diferentes.").c_str());
         }

         for (auto i = 0; i < procedureTypes.size(); i++) {
            if (procedureTypes[i] != getType($3[i])) {
               yyerror(("Tipo do parâmetro incorreto: pos " + to_string(i)).c_str());
            }
         }

         $$ = createTypeByString(sym->getType());
      }
      ;

   call_args: // Call args
      exp call_args2 {
         $$ = std::vector<Type>({$1});
         $$->insert($$->end(), $2->begin(), $2->end());
      }
      | {
         $$ = std::vector<Type>();
      }
      ;

   call_args2: // Call args two
      TOKEN_COMMA exp call_args2 {
         $$ = std::vector<Type>({$2});
         $$->insert($$->end(), $3->begin(), $3->end());
      }
      | {
         $$ = std::vector<Type>();
      }
      ;

   type: // Type
      TOKEN_FLOAT {
         $$ = createPrimitiveType(TYPE_FLOAT);
      }
    | TOKEN_INT {
         $$ = createPrimitiveType(TYPE_INT);
      }
    | TOKEN_STRING {
         $$ = createPrimitiveType(TYPE_STRING);
      }
    | TOKEN_BOOL {
         $$ = createPrimitiveType(TYPE_BOOL);
      }
    | NAME {
         auto sym = symbolTable.lookup(std::string($1));
         if (!isSpecialType(sym)) {
            yyerror(("Tipo não declarado ou inválido para type: " + std::string($1)).c_str());
         }
         $$ = createNonPrimitiveType(std::string($1));
      }
    | TOKEN_REF TOKEN_OPEN_PARENTHESIS type TOKEN_CLOSE_PARENTHESIS {
         $$ = createReferenceType($3);
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

bool isSpecialType(Symbol* sym) {
   return sym && (typeid(*sym) == typeid(Struct) || typeid(*sym) == typeid(Enum));
}

bool isVariable(Symbol* sym) {
   return sym && (typeid(*sym) == typeid(Variable));
}

bool isStruct(Symbol* sym) {
   return sym && (typeid(*sym) == typeid(Struct));
}

bool isProcedure(Symbol* sym) {
   return sym && (typeid(*sym) == typeid(Procedure));
}

Type* createPrimitiveType(TypeKind kind) {
   auto t = new Type;
   t->kind = kind;
   t->name = nullptr;
   t->ref = nullptr;

   return t;
}
Type* createNonPrimitiveType(std::string name) {
   auto t = new Type;
   t->kind = TYPE_NAME;
   t->name = $1;
   t->ref = nullptr;

   return t;
}
Type* createReferenceType(Type* refType) {
   auto t = new Type;
   t->kind = TYPE_REF;
   t->name = nullptr;
   t->ref = $3;

   return t;
}

Type* createTypeByString(std::string name) {
   auto t = new Type;
   t->name = nullptr;
   t->ref = nullptr;

   switch(name) {
      case "int":
         t->kind = TYPE_INT;
         break;
      case "float":
         t->kind = TYPE_FLOAT;
         break;
      case "bool":
         t->kind = TYPE_BOOL;
         break;
      case "string":
         t->kind = TYPE_STRING;
         break;
      case "void":
         t->kind = TYPE_VOID;
         break;
      default:
         if (name[0] == '*') {
            t->kind = TYPE_REF;
            t->ref = createTypeByString(name.substr(1));
         } else {
            t->kind = TYPE_NAME;
            t->name = name;
         }
   }

   return t;
}