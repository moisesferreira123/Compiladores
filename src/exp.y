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

bool primitiveTypesAreEquivalent(TypeKind lhs, TypeKind rhs);
bool typesAreEquivalent(Type* lhs, Type* rhs);
bool typesAreEquivalent(std::string lhs, std::string rhs);
bool isArithmeticTypes(TypeKind lhs, TypeKind rhs);
TypeKind getPrimitiveTypeOfOperation(TypeKind lhs, TypeKind rhs);

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
%type <type> bool_literal
%type <type> var
%type <type> ref_var
%type <type> deref_var
%type <type> exp
%type <type> call_stmt
%type <type> var_decl2
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
      TOKEN_VAR NAME TOKEN_COLON type var_decl2 {
         if ($5->kind != TYPE_NULL && (!typesAreEquivalent($4, $5))) {
            yyerror(("A expressão de entrada não é de um tipo equivalente a definida: " + getType($4) + " e " + getType($5)).c_str());
         }

         std::string varName = std::string($2);
         std::string varKind = getType($4);

         Symbol sym = Variable(varName, varKind);
         symbolTable.insert(sym);
         free($2);
      }
      | TOKEN_VAR NAME TOKEN_ATTRIBUTION exp {
         if ($4->kind == TYPE_NULL) {
            yyerror(("A expressão não pode assumir o valor null na inicialização").c_str());
         }

         std::string varName = std::string($2);
         std::string varKind = getType($4);

         Symbol sym = Variable(varName, varKind);
         symbolTable.insert(sym);
         free($2);
      };


   var_decl2: // Variable declaration two
      TOKEN_ATTRIBUTION exp {
         $$ = $1;
      }
      | {
         $$ = createPrimitiveType(TYPE_NULL);
      }
      ;

   procedure_decl: // Procedure declaration
      TOKEN_PROCEDURE NAME {
         $$ = Procedure(std::string($2));
         symbolTable.enterScope();
      } TOKEN_OPEN_PARENTHESIS procedure_params TOKEN_CLOSE_PARENTHESIS return_type {
         /// TODO: Salve os parâmetros vindos de procedure_params
         $$->setType(getType($7))
      } TOKEN_BEGIN scope_declarations stmt_list TOKEN_END {
         symbolTable.exitScope();
         symbolTable.insert($$);
      }
      ;
   
   record_decl: // Record declaration
      TOKEN_STRUCT NAME {
         // TODO: Use o procedure como exemplo.
         // Crie o simbolo e abra o escopo, guarde os campos, feche o escopo e salve o simbolo.
      } TOKEN_OPEN_BRACES record_fields TOKEN_CLOSE_BRACES {

      }
      ;

   procedure_params: // Procedure params
      paramfield_decl procedure_params2 {
         // TODO: Faça como em call_args
      }
      | 
      ;

   record_fields: // Record fields
      paramfield_decl record_fields2 {
         // TODO: Faça como em call_args
      }
      | 
      ;

   procedure_params2: // Procedure params two
      TOKEN_COMMA paramfield_decl procedure_params2 {
         // TODO: Faça como em call_args2
      }
      | 
      ;

   record_fields2: // Record field two
      TOKEN_SEMICOLON paramfield_decl record_fields2 {
         // TODO: Faça como em call_args2
      }
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
         // TODO: Adicionar na tabela de simbolos e definir o tipo.
         // $$ = $3;

         // VariableType type;
         // if ($3->kind == TYPE_NAME) {
         //    Symbol* symName = symbolTable.lookup(std::string($3->name));

         //    if (nonIsSpecialType(symName)) {

         //    } /// Verificar se é tipo struct ou enum (typeid)
         // }
         // Symbol sym = Variable(std::string($1),  ,getType($3))
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
      exp TOKEN_AND exp {
         if ($1->kind != TYPE_BOOL || $3->kind != TYPE_BOOL) {
            yyerror(("As expressões devem ser do tipo booleano e foram definidos no tipo: " + getType($1) + " e " + getType($3)).c_str());
         } else {
            $$ = createPrimitiveType(TYPE_BOOL);
         }
      }
      | exp TOKEN_OR exp {
         if ($1->kind != TYPE_BOOL || $3->kind != TYPE_BOOL) {
            yyerror(("As expressões devem ser do tipo booleano e foram definidos no tipo: " + getType($1) + " e " + getType($3)).c_str());
         } else {
            $$ = createPrimitiveType(TYPE_BOOL);
         }
      }
      | TOKEN_NOT exp {
         if ($2->kind != TYPE_BOOL) {
            yyerror(("A expressão deve ser do tipo booleano e foi definido no tipo: " + getType($2)).c_str());
         } else {
            $$ = createPrimitiveType(TYPE_BOOL);
         }
      }
      | exp TOKEN_COMP exp {
         if (!primitiveTypesAreEquivalent($1->kind, $3->kind)) {
            yyerror(("A comparação deve ser realizada para tipos primitivos equivalentes").c_str());
         } else {
            $$ = createPrimitiveType(TYPE_BOOL);
         }
      }
      | exp TOKEN_EQUAL exp {
         if (!typesAreEquivalente($1, $3) || $1->kind == TYPE_NAME) {
            yyerror(("A comparação deve ser realizada para tipos equivalentes").c_str());
         } else {
            $$ = createPrimitiveType(TYPE_BOOL);
         }
      }
      | exp TOKEN_ADD exp {
         if (!primitiveTypesAreEquivalent($1->kind, $3->kind)) {
            yyerror(("A soma deve ser realizada para tipos primitivos equivalentes").c_str());
         } else {
            $$ = createPrimitiveType(getPrimitiveTypeOfOperation($1->kind, $3->kind));
         }
      }
      | exp TOKEN_SUB exp {
         if (!isArithmeticTypes($1->kind, $3->kind)) {
            yyerror(("A subtração deve ser realizada para tipos aritméticos equivalentes").c_str());
         } else {
            $$ = createPrimitiveType(getPrimitiveTypeOfOperation($1->kind, $3->kind));
         }
      }
      | exp TOKEN_MULT exp {
         if (!isArithmeticTypes($1->kind, $3->kind)) {
            yyerror(("A multiplicação deve ser realizada para tipos aritméticos equivalentes").c_str());
         } else {
            $$ = createPrimitiveType(getPrimitiveTypeOfOperation($1->kind, $3->kind));
         }
      }
      | exp TOKEN_DIV exp {
         if (!isArithmeticTypes($1->kind, $3->kind)) {
            yyerror(("A divisão deve ser realizada para tipos aritméticos equivalentes").c_str());
         } else {
            $$ = createPrimitiveType(getPrimitiveTypeOfOperation($1->kind, $3->kind));
         }
      }
      | exp TOKEN_POT exp {
         if (!isArithmeticTypes($1->kind, $3->kind)) {
            yyerror(("A potenciação deve ser realizada para tipos aritméticos equivalentes").c_str());
         } else {
            $$ = createPrimitiveType(getPrimitiveTypeOfOperation($1->kind, $3->kind));
         }
      }
      | literal {
         $$ = $1;
      }
      | call_stmt {
         $$ = $1;
      }
      | TOKEN_NEW NAME {
         auto sym = symbolTable.lookup(std::string($2)); // 1) Buscar na tabela de símbolos. 
         if (!isSpecialType(sym)) {
            yyerror(("Simbolo não encontrado ou não é um tipo especial: " + std::string($2)).c_str());
         }
         $$ = createReferenceType(createTypeByString(sym->getKind()));
      }
      | var {
         $$ = $1;
      }
      | ref_var {
         $$ = $1;
      }
      | deref_var {
         $$ = $1;
      }
      | TOKEN_OPEN_PARENTHESIS exp TOKEN_CLOSE_PARENTHESIS {
         $$ = $2;
      }
      | TOKEN_SUB exp %prec UMINUS {
         if (!isArithmeticTypes($2->kind, $2->kind)) {
            yyerror(("O menos unário deve ser realizada para tipos aritméticos").c_str());
         } else {
            $$ = createPrimitiveType(getPrimitiveTypeOfOperation($2->kind, $2->kind));
         }
      }
      ;

   ref_var: // Reference variable
      TOKEN_REF TOKEN_OPEN_PARENTHESIS var TOKEN_CLOSE_PARENTHESIS {
         $$ = createReferenceType($3);
      }
      ;

   deref_var: // Dereference variable
      TOKEN_DEREF TOKEN_OPEN_PARENTHESIS var TOKEN_CLOSE_PARENTHESIS {
         if ($3->kind != TYPE_REF) {
            yyerror(("A variável precisa ser uma referência: " + getType($3)).c_str());
         } else {
            $$ = $3->ref;
         }
      }
      | TOKEN_DEREF TOKEN_OPEN_PARENTHESIS deref_var TOKEN_CLOSE_PARENTHESIS {
         if ($3->kind != TYPE_REF) {
            yyerror(("A variável precisa ser uma referência: " + getType($3)).c_str());
         } else {
            $$ = $3->ref;
         }
      }
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
      TOKEN_TRUE {
         $$ = createPrimitiveType(TYPE_BOOL);
      }
      | TOKEN_FALSE {
         $$ = createPrimitiveType(TYPE_BOOL);
      }
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
            if (!typesAreEquivalent(procedureTypes[i], getType($3[i]))) {
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

bool primitiveTypesAreEquivalent(TypeKind lhs, TypeKind rhs) {
   if ((lhs == TYPE_INT && rhs == TYPE_FLOAT) || (rhs == TYPE_INT && lhs == TYPE_FLOAT)) {
      return true;
   } else if (lhs == TYPE_NAME || rhs == TYPE_NAME) {
      return false;
   } else if (lhs == TYPE_REF || rhs == TYPE_REF) {
      return false;
   } else if (lhs == rhs) {
      return true;
   }
   
   return false;
}

bool typesAreEquivalent(Type* lhs, Type* rhs) {
   if (primitiveTypesAreEquivalent(lhs->kind, rhs->kind)) {
      return true;
   } else if (lhs->kind == TYPE_REF && rhs->kind == TYPE_REF) {
      return typesAreEquivalent(lhs->ref, rhs->ref);
   } else if (lhs->kind == TYPE_NAME && rhs->kind == TYPE_NAME) {
      return lhs->name == rhs->name;
   } else {
      return false;
   }
}

TypeKind getPrimitiveTypeOfOperation(TypeKind lhs, TypeKind rhs) {
   if ((lhs == TYPE_INT && rhs == TYPE_FLOAT) || (rhs == TYPE_INT && lhs == TYPE_FLOAT)) {
      return TYPE_FLOAT;
   } else if (lhs == rhs) {
      return lhs;
   }
   
   return TYPE_NULL;
}

bool isArithmeticTypes(TypeKind lhs, TypeKind rhs) {
   if ((lhs == TYPE_INT || lhs == TYPE_FLOAT) && (rhs == TYPE_INT || rhs == TYPE_FLOAT)) {
      return true;
   } else if (lhs == TYPE_BOOL && rhs == TYPE_BOOL) {
      return true;
   }

   return false;
}

bool typesAreEquivalent(std::string lhs, std::string rhs) {
   auto newLhs = createTypeByString(lhs);
   auto newRhs = createTypeByString(rhs);

   return typesAreEquivalent(newLhs, newRhs);
}