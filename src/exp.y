%{
#include <iostream>
#include <typeinfo>
#include "symbol_table.hpp"
#include <vector>
#include <string>
#include <unordered_map>
#include <utility>    // Required for std::pair

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
   TYPE_NAME, TYPE_VOID, TYPE_INT, TYPE_FLOAT,
   TYPE_BOOL, TYPE_STRING, TYPE_NULL, TYPE_REF
} TypeKind;

struct Type {
   TypeKind kind;
   char* name;
   Type* ref;
};

struct Procedure;
struct Struct;
struct Enum;

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
%}

%union {
    int                              ival;
    float                            fval;
    char* nval;
    char* sval;
    Type* type; // Corrected to pointer as per your previous edit
    Procedure* procedure;
    Struct* stc;
    Enum* enm;
    std::pair<std::string,Type*>* param;
    std::vector<std::string>* enumfld;
    std::vector<std::pair<std::string,Type*>>* args;
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
%type <type>  type return_type literal bool_literal var ref_var deref_var exp call_stmt var_decl2
%type <param> paramfield_decl
%type <args>  call_args call_args2 procedure_params procedure_params2 record_fields record_fields2
%type <stc>   record_header
%type <enm>   enum_header
%type <enumfld> enum_field
%type <procedure> procedure_header

%%

// Rest of your grammar rules follow here
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
         $$ = $2;
      }
      | {
         $$ = createPrimitiveType(TYPE_NULL);
      }
      ;

   procedure_decl: // Procedure declaration
      procedure_header TOKEN_OPEN_PARENTHESIS procedure_params TOKEN_CLOSE_PARENTHESIS return_type {
         std::vector<std::string> paramTypes;
         for (const auto& param : $3) {
            paramTypes.push_back(getType(param.second));
         }
         $1->setParams(paramTypes);

         $1->setType(getType($5))
      } TOKEN_BEGIN scope_declarations stmt_list TOKEN_END {
         symbolTable.exitScope();
         symbolTable.insert($1);
      }
      ;

   procedure_header:
    TOKEN_PROCEDURE NAME {
        $$ = new Procedure(std::string($2));
        symbolTable.enterScope();
    };
   
   record_decl: // Record declaration
      record_header TOKEN_OPEN_BRACES record_fields TOKEN_CLOSE_BRACES {
         std::unordered_map<std::string, std::string> fields;
         for (const auto& field : $3) {
            fields[field.first] = getType(field.second);
         }
         $1->setFields(fields);
         symbolTable.exitScope();
         symbolTable.insert($1);
      }
      ;
   
   record_header:
      TOKEN_STRUCT NAME {
         $$ = new Struct(std::string($2));
         symbolTable.enterScope();
         free($2);
      }

   procedure_params: // Procedure params
      paramfield_decl procedure_params2 {
         $$ = std::vector<std::pair<std::string, Type>>({$1});
         $$->insert($$->end(), $2->begin(), $2->end());
      }
      | {
         $$ = std::vector<std::pair<std::string, Type>>();
      }
      ;

   record_fields: // Record fields
      paramfield_decl record_fields2 {
         $$ = std::vector<std::pair<std::string, Type>>({$1});
         $$->insert($$->end(), $2->begin(), $2->end());
      }
      | {
         $$ = std::vector<std::pair<std::string, Type>>();
      }
      ;

   procedure_params2: // Procedure params two
      TOKEN_COMMA paramfield_decl procedure_params2 {
         $$ = std::vector<std::pair<std::string, Type>>({$2});
         $$->insert($$->end(), $3->begin(), $3->end());
      }
      | {
         $$ = std::vector<std::pair<std::string, Type>>();
      }
      ;

   record_fields2: // Record field two
      TOKEN_SEMICOLON paramfield_decl record_fields2 {
         $$ = std::vector<std::pair<std::string, Type>>({$2});
         $$->insert($$->end(), $3->begin(), $3->end());         
      }
      | {
         $$ = std::vector<std::pair<std::string, Type>>();
      }
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
      enum_header TOKEN_EQUAL TOKEN_OPEN_BRACES NAME enum_field TOKEN_CLOSE_BRACES {  
         // TODO: Salvar os fields na tabela de simbolos?
         std::vector<std::string> enumFields = {$4};
         for (const auto& field : $5) {
            enumFields.push_back(field);
         }

         $1->setFields(enumFields);
         symbolTable.exitScope();
         symbolTable.insert($1);
      }
      ;
   
   enum_header:
      TOKEN_ENUM NAME {
         $$ = new Enum(std::string($2));
         symbolTable.enterScope();
         free($2);
      }

   enum_field: // Enum field
      TOKEN_COMMA NAME enum_field {
         $$ = std::vector<std::string>({std::string($2)});
         $$->insert($$->end(), $3.begin(), $3.end());
         free($2);
      } 
      | {
         $$ = std::vector<std::string>();
      }
      ;

   paramfield_decl: // Param field declaration
      NAME TOKEN_COLON type {
         $$ = {std::string($1), $3};
         std::string varName = std::string($1);
         std::string varKind = getType($3);

         Symbol sym = Variable(varName, varKind);
         symbolTable.insert(sym);
         free($1);
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
         $$ = createReferenceType(createTypeByString(sym->getName()));
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
         Variable* var = dynamic_cast<Variable*>(sym);
         $$ = createTypeByString(var->getKind());
      }
      | exp TOKEN_DOT NAME {
         if ($1->kind == TYPE_NAME) {
            Symbol* symName = symbolTable.lookup(std::string($1->name));

            if (!isStruct(symName)) {
               yyerror(("Tipo não declarado ou inválido para var: " + getType($1)).c_str());
            }

            Struct* structType = dynamic_cast<Struct*>(symName);

            auto fields = structType->getFields();
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

         Procedure* proc = dynamic_cast<Procedure*>(sym);
         auto procedureTypes = proc->getParams();

         if (procedureTypes.size() != $3.size()) {
            yyerror(("Quantidade de parâmetros diferentes.").c_str());
         }

         for (auto i = 0; i < procedureTypes.size(); i++) {
            if (!typesAreEquivalent(procedureTypes[i], getType($3[i].second))) {
               yyerror(("Tipo do parâmetro incorreto: pos " + to_string(i)).c_str());
            }
         }

         $$ = createTypeByString(proc->getType());
      }
      ;

   call_args: // Call args
      exp call_args2 {
         $$ = std::vector<Type>({{"",$1}});
         $$->insert($$->end(), $2->begin(), $2->end());
      }
      | {
         $$ = std::vector<Type>();
      }
      ;

   call_args2: // Call args two
      TOKEN_COMMA exp call_args2 {
         $$ = std::vector<Type>({{"",$2}});
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
   return sym && (Struct* s = dynamic_cast<Struct*>(sym) || Enum* e = dynamic_cast<Enum*>(sym));
}

bool isVariable(Symbol* sym) {
   return sym && (Variable* s = dynamic_cast<Variable*>(sym));
}

bool isStruct(Symbol* sym) {
   return sym && (Struct* s = dynamic_cast<Struct*>(sym));
}

bool isProcedure(Symbol* sym) {
   return sym && (Procedure* s = dynamic_cast<Procedure*>(sym));
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
   t->name = name;
   t->ref = nullptr;

   return t;
}
Type* createReferenceType(Type* refType) {
   auto t = new Type;
   t->kind = TYPE_REF;
   t->name = nullptr;
   t->ref = refType;

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