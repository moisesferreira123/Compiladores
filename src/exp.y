%{
#include "symbol_table.hpp"
#include "codegen.hpp"
#include "tac.hpp"

extern int numLines;
extern int numCols;
extern SymbolTable symbolTable;
extern CodeEmitter emitter;
%}

%code requires {
   #include "type_utils.hpp"
}

%union {
   int                              ival;
   float                            fval;
   char* nval;
   char* sval;
   Type* type; // Type* é conhecido pelo %code requires
   ExpResult* exp_res;
   Procedure* procedure; // Procedure* é conhecido pelo %code requires
   Struct* stc;          // Struct* é conhecido pelo %code requires
   Enum* enm;            // Enum* é conhecido pelo %code requires
   std::pair<std::string,Type*>* param; // std::pair é conhecido pelo include global
   std::vector<std::string>* enumfld;   // std::vector é conhecido pelo include global
   std::vector<std::pair<std::string,Type*>>* args; // std::vector e std::pair conhecidos
   OpCode* opCode;
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
%nonassoc TOKEN_LESS TOKEN_LESS_EQUAL TOKEN_GREATER TOKEN_GREATER_EQUAL TOKEN_DIFF TOKEN_EQUAL
%left TOKEN_ADD TOKEN_SUB
%left TOKEN_MULT TOKEN_DIV
%right TOKEN_POT
%left TOKEN_DOT
%right UMINUS

%start program

/// Associação dos não terminais aos tipos
%type <type>  type return_type 
%type <param> paramfield_decl
%type <args>  call_args call_args2 procedure_params procedure_params2 record_fields record_fields2
%type <stc>   record_header
%type <enm>   enum_header
%type <enumfld> enum_field
%type <procedure> procedure_header

%type <exp_res> literal bool_literal var ref_var deref_var exp call_stmt var_decl2 return_stmt2 return_stmt
%type <opCode> rel_op


%%

   program:
      TOKEN_PROGRAM NAME {
         symbolTable.insert(std::make_unique<Program>(std::string($2)));
         free($2);
    } TOKEN_BEGIN decl_block TOKEN_END
    ;

   decl:
      var_decl
      | procedure_decl
      | record_decl
      | enum_decl
      ;

   var_decl:
      TOKEN_VAR NAME TOKEN_COLON type var_decl2 {
         if ($4->kind == TYPE_ERROR || $5->type->kind == TYPE_ERROR) {
            // Ignora a regra pois já houve erro anteriormente.
         } else if (!attributionTypesAreEquivalent($4, $5->type)) {
            yyerror(("A expressão de entrada não é de um tipo equivalente a definida: " + getType($4) + " e " + getType($5)).c_str());
         } else {
            std::string varName = std::string($2);
            std::string varKind = getType($4);

            if($5->type->kind != TYPE_NULL) {
               emmiter.emit(OpCode::TAC_VAR, varName, $5->address, ""); 
            } 

            symbolTable.insert(std::make_unique<Variable>(varName, varKind));
            free($2);
            delete $5;
         }
      }
      | TOKEN_VAR NAME TOKEN_ATTRIBUTION exp {
         if ($4->type->kind == TYPE_ERROR) {
            // Ignora a regra pois já houve erro anteriormente.
         } else if ($4->type->kind == TYPE_NULL) {
            yyerror("A expressão não pode assumir o valor null na inicialização");
         } else {
            std::string varName = std::string($2);
            std::string varKind = getType($4);

            emmiter.emit(OpCode::TAC_VAR, varName, $4->address, "");

            symbolTable.insert(std::make_unique<Variable>(varName, varKind));
            free($2);
            delete $4;
         }
      };


   var_decl2:
      TOKEN_ATTRIBUTION exp {
         $$ = $2;
      }
      | {
         $$->type = createPrimitiveType(TYPE_NULL);
      }
      ;

   procedure_decl:
      procedure_header TOKEN_OPEN_PARENTHESIS procedure_params TOKEN_CLOSE_PARENTHESIS return_type {
         std::vector<std::string> paramTypes;
         if ($3) {
            for (const auto& param : *$3) {
               paramTypes.push_back(getType(param.second));
            }
         }
         $1->setParams(paramTypes);
         $1->setType(getType($5));
      } TOKEN_BEGIN scope_declarations stmt_list TOKEN_END {
         /// TODO: Definir um tipo para stmt_list e verificar se é igual ao return_type:
            /// stmt_list tem um tipo definido por seus stmt
            /// stmt tem seu tipo definido por return_stmt
            /// Caso não seja definido tipo, é void
         symbolTable.exitScope();
         symbolTable.insert(std::unique_ptr<Procedure>($1));
      }
      ;

   procedure_header:
    TOKEN_PROCEDURE NAME {
        $$ = new Procedure(std::string($2));
        symbolTable.enterScope();
        free($2);
    };

   record_decl:
      record_header TOKEN_OPEN_BRACES record_fields TOKEN_CLOSE_BRACES {
         std::unordered_map<std::string, std::string> fields;
         if ($3) {
            for (const auto& field : *$3) {
               fields[field.first] = getType(field.second);
            }
         }
         $1->setFields(fields);
         symbolTable.exitScope();
         symbolTable.insert(std::unique_ptr<Struct>($1));
      }
      ;

   record_header:
      TOKEN_STRUCT NAME {
         $$ = new Struct(std::string($2));
         symbolTable.enterScope();
         free($2);
      }

   procedure_params:
      paramfield_decl procedure_params2 {
         $$ = new std::vector<std::pair<std::string, Type*>>();
         $$->push_back(*$1);
         if ($2) {
            $$->insert($$->end(), $2->begin(), $2->end());
            delete $2;
         }
         delete $1;
      }
      | {
         $$ = new std::vector<std::pair<std::string, Type*>>();
      }
      ;

   record_fields:
      paramfield_decl record_fields2 {
         $$ = new std::vector<std::pair<std::string, Type*>>();
         $$->push_back(*$1);
         if ($2) {
            $$->insert($$->end(), $2->begin(), $2->end());
            delete $2;
         }
         delete $1;
      }
      | {
         $$ = new std::vector<std::pair<std::string, Type*>>();
      }
      ;

   procedure_params2:
      TOKEN_COMMA paramfield_decl procedure_params2 {
         $$ = new std::vector<std::pair<std::string, Type*>>();
         $$->push_back(*$2);
         if ($3) {
            $$->insert($$->end(), $3->begin(), $3->end());
            delete $3;
         }
         delete $2;
      }
      | {
         $$ = new std::vector<std::pair<std::string, Type*>>();
      }
      ;

   record_fields2:
      TOKEN_SEMICOLON paramfield_decl record_fields2 {
         $$ = new std::vector<std::pair<std::string, Type*>>();
         $$->push_back(*$2);
         if ($3) {
            $$->insert($$->end(), $3->begin(), $3->end());
            delete $3;
         }
         delete $2;
      }
      | {
         $$ = new std::vector<std::pair<std::string, Type*>>();
      }
      ;

   return_type:
      TOKEN_COLON type {
         $$ = $2;
      }
      | {
         $$ = new Type;
         $$->type->kind = TYPE_VOID;
         $$->name = nullptr;
         $$->ref = nullptr;
      }
      ;

   scope_declarations:
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
      enum_header TOKEN_EQUAL TOKEN_OPEN_BRACES NAME enum_field TOKEN_CLOSE_BRACES {
         std::vector<std::string> enumValues;
         enumValues.push_back(std::string($4));
         if ($5) {
            enumValues.insert(enumValues.end(), $5->begin(), $5->end());
            delete $5;
         }

         $1->setValues(enumValues);
         symbolTable.exitScope();
         symbolTable.insert(std::unique_ptr<Enum>($1));
         free($4);
      }
      ;

   enum_header:
      TOKEN_ENUM NAME {
         $$ = new Enum(std::string($2));
         symbolTable.enterScope();
         free($2);
      }

   enum_field:
      TOKEN_COMMA NAME enum_field {
         $$ = new std::vector<std::string>();
         $$->push_back(std::string($2));
         if ($3) {
            $$->insert($$->end(), $3->begin(), $3->end());
            delete $3;
         }
         free($2);
      }
      | {
         $$ = new std::vector<std::string>();
      }
      ;

   paramfield_decl:
      NAME TOKEN_COLON type {
         $$ = new std::pair<std::string,Type*>(std::string($1), $3);
         std::string varName = std::string($1);
         std::string varKind = getType($3);

         symbolTable.insert(std::make_unique<Variable>(varName, varKind));
         free($1);
      }
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
      exp TOKEN_AND exp {
         if ($1->type->kind == TYPE_ERROR || $3->type->kind == TYPE_ERROR) {
            $$ = ExpResult{ createPrimitiveType(TYPE_ERROR), ""};
         } else if ($1->type->kind != TYPE_BOOL || $3->type->kind != TYPE_BOOL) {
            yyerror(("As expressões devem ser do tipo booleano e foram definidos no tipo: " + getType($1) + " e " + getType($3)).c_str());
            $$ = ExpResult{ createPrimitiveType(TYPE_ERROR), ""};
         } else {
            std::string temp = new_temp(); 
            emitter.emit(OpCode::TAC_AND, temp, $1->address, $3->address);

            $$ = new ExpResult();
            $$->type = createPrimitiveType(TYPE_BOOL);
            $$->address = temp; 
         }
         delete $1;
         delete $3;
      }
      | exp TOKEN_OR exp {
         if ($1->type->kind == TYPE_ERROR || $3->type->kind == TYPE_ERROR) {
            $$ = ExpResult{ createPrimitiveType(TYPE_ERROR), ""};
         } else if ($1->type->kind != TYPE_BOOL || $3->type->kind != TYPE_BOOL) {
            yyerror(("As expressões devem ser do tipo booleano e foram definidos no tipo: " + getType($1) + " e " + getType($3)).c_str());
            $$ = ExpResult{ createPrimitiveType(TYPE_ERROR), ""};
         } else {
            std::string temp = new_temp(); 
            emitter.emit(OpCode::TAC_OR, temp, $1->address, $3->address);

            $$ = new ExpResult();
            $$->type = createPrimitiveType(TYPE_BOOL);
            $$->address = temp; 
         }
         delete $1;
         delete $3;
      }
      | TOKEN_NOT exp {
         if ($2->type->kind == TYPE_ERROR) {
            $$ = ExpResult{ createPrimitiveType(TYPE_ERROR), ""};
         } else if ($2->type->kind != TYPE_BOOL) {
            yyerror(("A expressão deve ser do tipo booleano e foi definido no tipo: " + getType($2)).c_str());
            $$ = ExpResult{ createPrimitiveType(TYPE_ERROR), ""};
         } else {
            std::string temp = new_temp();

            emitter.emit(OpCode::TAC_NOT, temp, $2->address, "");
            $$ = new ExpResult();
            $$->type = createPrimitiveType(TYPE_BOOL);
            $$->address = temp; 
         }
         delete $2;
      }
      | exp rel_op exp {
        if (!primitiveTypesAreEquivalent($1->type->kind, $3->type->kind)) {
            yyerror("A comparação deve ser realizada para tipos primitivos equivalentes");
            $$ = ExpResult{ createPrimitiveType(TYPE_ERROR), ""};
         } else {
            std::string temp = new_temp();

            OpCode opCode = $2;
            
            emitter.emit(opCode, temp, $1->address, $3->address);
            $$ = new ExpResult();
            $$->type = createPrimitiveType(TYPE_BOOL);
            $$->address = temp; 
         }
         delete $1;
         delete $2;
         delete $3;
      }
      | exp TOKEN_ADD exp {
        if (!primitiveTypesAreEquivalent($1->type->kind, $3->type->kind)) {
            yyerror("A soma deve ser realizada para tipos primitivos equivalentes");
            $$ = new ExpResult{ createPrimitiveType(TYPE_ERROR), "" };
        } else {
            std::string temp = new_temp(); // Pega um novo temporário, ex: "_tx"
            
            // Emite a instrução TAC! Usa os endereços dos filhos
            emitter.emit(OpCode::TAC_ADD, temp, $1->address, $3->address);

            $$ = new ExpResult();
            $$->type = createPrimitiveType(getPrimitiveTypeOfOperation($1->type->kind, $3->type->kind));
            $$->address = temp; // O resultado desta soma está agora em "_tx"
        }
        delete $1;
        delete $3;
      }
      | exp TOKEN_SUB exp {
         if (!isArithmeticTypes($1->type->kind, $3->type->kind)) {
            yyerror("A subtração deve ser realizada para tipos aritméticos equivalentes");
            $$ = new ExpResult{ createPrimitiveType(TYPE_ERROR), "" };
         } else {
            std::string temp = new_temp();  
            emitter.emit(OpCode::TAC_SUB, temp, $1->address, $3->address);

            $$ = new ExpResult();
            $$->type = createPrimitiveType(getPrimitiveTypeOfOperation($1->type->kind, $3->type->kind));
            $$->address = temp;
         }
         delete $1;
         delete $3;

      }
      | exp TOKEN_MULT exp {
         if (!isArithmeticTypes($1->type->kind, $3->type->kind)) {
            yyerror("A multiplicação deve ser realizada para tipos aritméticos equivalentes");
            $$ = new ExpResult{ createPrimitiveType(TYPE_ERROR), ""};
         } else {
            std::string temp = new_temp();
            emitter.emit(OpCode::TAC_MULT, temp, $1->address, $3->address);

            $$ = new ExpResult();
            $$->type = createPrimitiveType(getPrimitiveTypeOfOperation($1->type->kind, $3->type->kind));
            $$->address = temp;
         }
         delete $1;
         delete $3;
      }
      | exp TOKEN_DIV exp {
         if (!isArithmeticTypes($1->type->kind, $3->type->kind)) {
            yyerror("A divisão deve ser realizada para tipos aritméticos equivalentes");
            $$ = new ExpResult{ createPrimitiveType(TYPE_ERROR), ""};
         } else {
            std::string temp = new_temp();
            emitter.emit(OpCode::TAC_DIV, temp, $1->address, $3->address);

            $$ = new ExpResult();
            $$->type = createPrimitiveType(getPrimitiveTypeOfOperation($1->type->kind, $3->type->kind));
            $$->address = temp;
         }
         delete $1;
         delete $3;
      }
      | exp TOKEN_POT exp {
         if (!isArithmeticTypes($1->type->kind, $3->type->kind)) {
            yyerror("A potenciação deve ser realizada para tipos aritméticos equivalentes");
            $$ = new ExpResult{ createPrimitiveType(TYPE_ERROR), ""};
         } else {
            std::string temp = new_temp();
            emitter.emit(OpCode::TAC_POT, temp, $1->address, $3->address);

            $$ = new ExpResult();
            $$->type = createPrimitiveType(getPrimitiveTypeOfOperation($1->type->kind, $3->type->kind));
            $$->address = temp;
         }
         delete $1;
         delete $3;
      }
      | literal {
         $$ = new ExpResult();
         $$->type = $1->type; 
         $$->address = $1->address; 
      }
      | call_stmt {
         $$ = new ExpResult();
         $$->type = $1->type; 
         $$->address = $1->address; 
      }
      | TOKEN_NEW NAME {
         auto sym = symbolTable.lookup(std::string($2));
         if (!isSpecialType(sym)) {
            yyerror(("Simbolo não encontrado ou não é um tipo especial: " + std::string($2)).c_str());
            $$ = createPrimitiveType(TYPE_ERROR);
         } else {
            $$ = createReferenceType(createTypeByString(sym->getName()));
            free($2);
         }
      }
      | var {
         $$ = new ExpResult();
         $$->type = $1->type; 
         $$->address = $1->address;
      }
      | ref_var {
         $$ = new ExpResult();
         $$->type = $1->type; 
         $$->address = $1->address;
      }
      | deref_var {
         $$ = new ExpResult();
         $$->type = $1->type; 
         $$->address = $1->address;
      }
      | TOKEN_OPEN_PARENTHESIS exp TOKEN_CLOSE_PARENTHESIS {
         $$ = $2;
      }
      | TOKEN_SUB exp %prec UMINUS {
         if (!isArithmeticTypes($2->type->kind, $2->type->kind)) {
            yyerror("O menos unário deve ser realizada para tipos aritméticos");
            $$ = new ExpResult{ createPrimitiveType(TYPE_ERROR), ""};
         } else {
            std::string temp = new_temp();

            emitter.emit(OpCode::TAC_UNARY_MINUS, temp, $2->address, "");
            $$ = new ExpResult();
            $$->type = createPrimitiveType(getPrimitiveTypeOfOperation($2->type->kind, $2->type->kind));
            $$->address = temp;
         }
         delete $2;
      }
      ;
   rel_op:
      TOKEN_GREATER{
         $$ = OpCode::TAC_GT;
      } 
      | TOKEN_GREATER_EQUAL{
         $$ = OpCode::TAC_GE;
      }
      | TOKEN_LESS{
         $$ = OpCode::TAC_LT;
      } 
      | TOKEN_LESS_EQUAL{
         $$ = OpCode::TAC_LE;
      } 
      | TOKEN_DIFF{
         $$ = OpCode::TAC_NEQ;
      } 
      | TOKEN_EQUAL{
         $$ = OpCode::TAC_EQ;
      }
    ;

   ref_var:
      TOKEN_REF TOKEN_OPEN_PARENTHESIS var TOKEN_CLOSE_PARENTHESIS {
         $$ = new ExpResult();   
         if ($3->type->kind == TYPE_ERROR) {
            yyerror(("A variável precisa ser um tipo válido: " + getType($3)).c_str());
            $$->type = createPrimitiveType(TYPE_ERROR);
         } else if ($3->type->kind == TYPE_REF) {
            yyerror(("A variável não pode ser uma referência: " + getType($3)).c_str());
            $$->type = createPrimitiveType(TYPE_ERROR);
         } else {
            $$->type = createReferenceType($3->type); 
            $$->address = $3->address; 
         }
         delete $3;
      }
      ;

   deref_var:
      TOKEN_DEREF TOKEN_OPEN_PARENTHESIS var TOKEN_CLOSE_PARENTHESIS {
         if ($3->type->kind != TYPE_REF) {
            yyerror(("A variável precisa ser uma referência: " + getType($3)).c_str());
            $$ = new ExpResult{createPrimitiveType(TYPE_ERROR), ""};
         } else {
            td::string temp = new_temp();

            emitter.emit(OpCode::TAC_DEREF, temp, $3->address, "");
            $$ = new ExpResult();
            $$->type = $3->type->ref; 
            $$->address = $3->address;  
         }
         delete $3;
      }
      | TOKEN_DEREF TOKEN_OPEN_PARENTHESIS deref_var TOKEN_CLOSE_PARENTHESIS {
         if ($3->type->kind != TYPE_REF) {
            yyerror(("A variável precisa ser uma referência: " + getType($3)).c_str());
            $$ = new ExpResult{ createPrimitiveType(TYPE_ERROR), ""};
         } else {
            std::string temp = new_temp();

            emitter.emit(OpCode::TAC_DEREF, temp, $3->address, "");
            $$ = new ExpResult();
            $$->type = $3->type->ref; 
            $$->address = $3->address;             
         }
         delete $3; 
      }
      ;

      var:
         NAME {
            $$ = new ExpResult();
            std::string varName = std::string($1);

            auto sym = symbolTable.lookup(varName);
            if (sym == nullptr) {
               yyerror(("Símbolo não encontrado: " + varName).c_str());
               $$->type = createPrimitiveType(TYPE_ERROR);
            } else if (isVariable(sym)) {
               Variable* var = dynamic_cast<Variable*>(sym);
               $$->type = createTypeByString(var->getKind());
               $$->address = varName;  // Nome da variável é o endereço no TAC
            } else if (isEnum(sym)) {
               Enum* enumSym = dynamic_cast<Enum*>(sym);
               $$->type = createNonPrimitiveType(enumSym->getName());
               $$->address = varName;

               // Ver se precisa emitir enum para o TAC
               // emitter.emit(OpCode::TAC_VAR, varName, "", "");
            } else {
                  yyerror(("Símbolo de tipo desconhecido: " + varName).c_str());
                  $$->type = createPrimitiveType(TYPE_ERROR);
            }

        free($1);
         }
         | exp TOKEN_DOT NAME {
            $$ = new ExpResult();
            if ($1->type->kind == TYPE_NAME) {
               Symbol* symName = symbolTable.lookup(std::string($1->name));

               if (isStruct(symName)) {
                  Struct* structType = dynamic_cast<Struct*>(symName);
                  auto fields = structType->getFields();
                  std::string memberName = std::string($3);

                  if (fields.find(memberName) == fields.end()) {
                     yyerror(("Campo não declarado para: " + getType($1)).c_str());
                     $$->type = createPrimitiveType(TYPE_ERROR);
                  } else {
                     $$->type = createTypeByString(fields[memberName]);
                     std::string temp = new_temp();
                     emitter.emit(OpCode::TAC_MEMBER_ACCESS, temp, $1->address, memberName);
                  }
               } else if (isEnum(symName)) {
                  Enum* enumType = dynamic_cast<Enum*>(symName);

                  auto values = enumType->getValues();
                  bool found = false;
                  for (const auto& value : values) {
                     if (value == std::string($3)) {
                        $$->type = createPrimitiveType(TYPE_INT);
                        $$->address = std::to_string(enumType->getValue(value));
                        found = true;
                        break;
                     }
                  }

                  if (!found) {
                     yyerror(("Campo não declarado para: " + getType($1)).c_str());
                     $$->type = createPrimitiveType(TYPE_ERROR);
                  }
               } else if (isSpecialType(symName)) {
                  yyerror(("Tipo não declarado ou inválido para var: " + getType($1)).c_str());
                  $$->type = createPrimitiveType(TYPE_ERROR);

               } else {
                  yyerror(("Tipo não declarado ou inválido para var: " + getType($1)).c_str());
                  $$->type = createPrimitiveType(TYPE_ERROR);
               }
            } else if ($1->type->kind == TYPE_ERROR) {
               // Ignora
            } else {
               yyerror(("Tipo inválido para var: " + getType($1)).c_str());
               $$->type = createPrimitiveType(TYPE_ERROR);
            }
            free($3);
            delete $1; 
         }
      ;

   literal:
      FLOAT_LITERAL {
         $$ = new ExpResult();
         $$->type = createPrimitiveType(TYPE_FLOAT);
         $$->address = std::to_string($1); 
      }
      | INT_LITERAL {
         $$ = new ExpResult();
         $$->type = createPrimitiveType(TYPE_INT);
         $$->address = std::to_string($1); 
      }
      | STRING_LITERAL  {
         $$ = new ExpResult();
         $$->type = createPrimitiveType(TYPE_STRING);
         $$->address = std::to_string($1); 
      }
      | bool_literal {
         $$ = new ExpResult();
         $$->type = createPrimitiveType(TYPE_BOOL);
         $$->address = std::to_string($1); 
      }
      | TOKEN_NULL {
         $$ = new ExpResult();
         $$->type = createPrimitiveType(TYPE_NULL);
         $$->address = "null"; 
      }
      ;

   bool_literal:
      TOKEN_TRUE {
         $$ = new ExpResult();
         $$->type = createPrimitiveType(TYPE_BOOL);
         $$->address = "true";

      }
      | TOKEN_FALSE {
         $$ = new ExpResult();
         $$->type = createPrimitiveType(TYPE_BOOL);
         $$->address = "false";
      }
      ;

   stmt:
      assign_stmt
      | if_stmt
      | while_stmt
      | return_stmt
      | call_stmt
      ;

   assign_stmt:
      var TOKEN_ATTRIBUTION exp {
         if ($1->type->kind == TYPE_ERROR || $3->type->kind == TYPE_ERROR) {
            // Ignora a regra pois já houve erro anteriormente.
         } else if ($1->type->kind == TYPE_NAME) {
            auto sym = symbolTable.lookup(std::string($1->name));
            
            if (isEnum(sym)) {
               Enum* enumType = dynamic_cast<Enum*>(sym);
               if ($3->type->kind != TYPE_INT) {
                  yyerror(("A expressão de entrada não é do tipo inteiro para enum: " + getType($3)).c_str());
               } else {
                  // Atribuição válida para enum
               }
            } else if (!attributionTypesAreEquivalent($1, $3)) {
               yyerror(("A expressão de entrada não é de um tipo equivalente a definida: " + getType($1) + " e " + getType($3)).c_str());
            }
         } else if (!attributionTypesAreEquivalent($1, $3)) {
            yyerror(("A expressão de entrada não é de um tipo equivalente a definida: " + getType($1) + " e " + getType($3)).c_str());
         } else{
            emitter.emit(OpCode::TAC_ASSIGN, $1->address, $3->address);
         }
         delete $1;
         delete $3;
      }
      | deref_var TOKEN_ATTRIBUTION exp {
         if ($1->type->kind == TYPE_ERROR || $3->type->kind == TYPE_ERROR) {
            // Ignora a regra pois já houve erro anteriormente.
         } else if (!attributionTypesAreEquivalent($1, $3)) {
            yyerror(("A expressão de entrada não é de um tipo equivalente a definida: " + getType($1) + " e " + getType($3)).c_str());
         } else{
            emitter.emit(OpCode::TAC_DEREF_ASSIGN, $1->address, $3->address);
         }
         delete $1;
         delete $3;
      }
      ;

   if_stmt:
      TOKEN_IF exp {
         if ($2->type->kind == TYPE_ERROR) {
            // Ignora
         } else if ($2->type->kind != TYPE_BOOL) {
            yyerror(("Tipo inválido para if: " + getType($2)).c_str());
         } else{
            std::string label_false  = new_label();
            emitter.emit(OpCode::TAC_IF_FALSE_GOTO, label_false, $2->address);

            // Guardamos esse rótulo na pilha para usá-lo depois.
            label_stack.push_back(label_false);

         }
         delete $2;
      } TOKEN_THEN stmt_list if_stmt2 TOKEN_FI
      ;

   if_stmt2:
      TOKEN_ELSE {
         std::string label_end = new_label(); // evitar o else
         emitter.emit(OpCode::TAC_GOTO, label_end);

         std::string label_false = label_stack.back();
         label_stack.pop_back();

         emitter.emit(OpCode::TAC_LABEL, label_false);
         label_stack.push_back(label_end);
      }
      stmt_list{
         std::string label_end = label_stack.back();
         label_stack.pop_back();
         emitter.emit(OpCode::TAC_LABEL, label_end);
      }
      | {
         std::string label_end = label_stack.back();
         label_stack.pop_back();
         emitter.emit(OpCode::TAC_LABEL, label_end);
      }
      ;

   while_stmt:
      TOKEN_WHILE{
         std::string label_begin = new_label();
         emitter.emit(OpCode::TAC_LABEL, label_begin);
         label_stack.push_back(label_begin);

      } exp {
         if ($3->type->kind == TYPE_ERROR) {
            // Ignora
         } else if ($3->type->kind != TYPE_BOOL) {
            yyerror(("Tipo inválido para while: " + getType($3)).c_str());
         } else{
            std::string label_end = new_label();
            emitter.emit(OpCode::TAC_IF_FALSE_GOTO, label_end , $3->address);
            label_stack.push_back(label_end);
         }
         delete $3;
      } TOKEN_DO stmt_list{

         std::string label_end = label_stack.back(); label_stack.pop_back();
         std::string label_begin = label_stack.back(); label_stack.pop_back();

         emitter.emit(OpCode::TAC_GOTO, label_begin);
         emitter.emit(OpCode::TAC_LABEL, label_end);
      } TOKEN_OD
      ;

   return_stmt:
      TOKEN_RETURN return_stmt2 { 
         $$ = $2;
         emitter.emit(OpCode::TAC_RETURN, $2->address);
         delete $2;
      }
      ;

   return_stmt2:
      exp {
         $$ = $1;
      }
      | {
        $$ = new ExpResult();
        $$->type = createPrimitiveType(TYPE_VOID);
        $$->address = ""; 

      }
      ;

   call_stmt:
      NAME TOKEN_OPEN_PARENTHESIS call_args TOKEN_CLOSE_PARENTHESIS {
         auto sym = symbolTable.lookup(std::string($1));

         $$ = new ExpResult();
         $$->address = "";

         if (!isProcedure(sym)) {
            yyerror(("Procedimento não declarado: " + std::string($1)).c_str());
            $$->type = createPrimitiveType(TYPE_ERROR);
         } else {
            Procedure* proc = dynamic_cast<Procedure*>(sym);
            auto procedureTypes = proc->getParams();

            std::vector<Type*> actualArgs;
            if ($3) {
               for (const auto& arg_pair : *$3) {
                  actualArgs.push_back(arg_pair.second);
                  std::string temp = new_temp();
                  emmiter.emit(OpCode::TAC_ATR, temp, arg_pair.second);
               }
               std::string label_begin_function = new_label();
               emmiter.emit(OpCode::TAC_GOTO, label_begin_function);
               label_stack.push_back(label_begin_function);

               delete $3;
            }

            if (procedureTypes.size() != actualArgs.size()) {
               yyerror("Quantidade de parâmetros diferentes.");
               $$_->type = createPrimitiveType(TYPE_ERROR);
            } else {
               bool error = false;
               for (size_t i = 0; i < procedureTypes.size(); i++) {
                  Type* expectedType = createTypeByString(procedureTypes[i]);
                  if (!attributionTypesAreEquivalent(expectedType, actualArgs[i])) {
                     yyerror(("Tipo do parâmetro incorreto: pos " + std::to_string(i)).c_str());
                     $$->type = createPrimitiveType(TYPE_ERROR);
                     error = true;
                  }
                  if (expectedType->name) free(expectedType->name);
                  delete expectedType;
                  if (!error) {
                     $$->type = createTypeByString(proc->getType());
                  }
               }
            }
         }
         free($1);
      }
      ;

   call_args:
      exp call_args2 {
         $$ = new std::vector<std::pair<std::string, Type*>>();
         $$->push_back({"",$1});
         if ($2) {
            $$->insert($$->end(), $2->begin(), $2->end());
            delete $2;
         }
      }
      | {
         $$ = new std::vector<std::pair<std::string, Type*>>();
      }
      ;

   call_args2:
      TOKEN_COMMA exp call_args2 {
         $$ = new std::vector<std::pair<std::string, Type*>>();
         $$->push_back({"",$2});
         if ($3) {
            $$->insert($$->end(), $3->begin(), $3->end());
            delete $3;
         }
      }
      | {
         $$ = new std::vector<std::pair<std::string, Type*>>();
      }
      ;

   type:
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
            $$ = createPrimitiveType(TYPE_ERROR);
         } else {
            $$ = createNonPrimitiveType(std::string($1));
         }
         free($1);
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
   if (type->type->kind == TYPE_INT) {
      return "int";
   } else if (type->type->kind == TYPE_FLOAT) {
      return "float";
   } else if (type->type->kind == TYPE_BOOL) {
      return "bool";
   } else if (type->type->kind == TYPE_STRING) {
      return "string";
   } else if (type->type->kind == TYPE_VOID) {
      return "void";
   } else if (type->type->kind == TYPE_NAME) {
      return type->name;
   } else if (type->type->kind == TYPE_NULL) {
      return "null";
   } else if (type->type->kind == TYPE_ERROR) {
      return "error";
   }

   return "*" + getType(type->ref);
}

bool isSpecialType(Symbol* sym) {
   return sym && (dynamic_cast<Struct*>(sym) != nullptr || dynamic_cast<Enum*>(sym) != nullptr);
}

bool isVariable(Symbol* sym) {
   return sym && dynamic_cast<Variable*>(sym) != nullptr;
}

bool isStruct(Symbol* sym) {
   return sym && dynamic_cast<Struct*>(sym) != nullptr;
}

bool isProcedure(Symbol* sym) {
   return sym && dynamic_cast<Procedure*>(sym) != nullptr;
}

bool isEnum(Symbol* sym) {
   return sym && dynamic_cast<Enum*>(sym) != nullptr;
}

Type* createPrimitiveType(TypeKind kind) {
   auto t = new Type;
   t->type->kind = kind;
   t->name = nullptr;
   t->ref = nullptr;

   return t;
}
Type* createNonPrimitiveType(std::string name) {
   auto t = new Type;
   t->type->kind = TYPE_NAME;
   t->name = strdup(name.c_str());
   t->ref = nullptr;

   return t;
}
Type* createReferenceType(Type* refType) {
   auto t = new Type;
   t->type->kind = TYPE_REF;
   t->name = nullptr;
   t->ref = refType;

   return t;
}

Type* createTypeByString(std::string name) {
   auto t = new Type;
   t->name = nullptr;
   t->ref = nullptr;

   if (name == "int") {
      t->type->kind = TYPE_INT;
   } else if (name == "float") {
      t->type->kind = TYPE_FLOAT;
   } else if (name == "bool") {
      t->type->kind = TYPE_BOOL;
   } else if (name == "string") {
      t->type->kind = TYPE_STRING;
   } else if (name == "void") {
      t->type->kind = TYPE_VOID;
   } else if (name == "null") {
      t->type->kind = TYPE_NULL;
   } else if (name == "error") {
      t->type->kind = TYPE_ERROR;
   } else {
      if (!name.empty() && name[0] == '*') {
         t->type->kind = TYPE_REF;
         t->ref = createTypeByString(name.substr(1));
      } else {
         t->type->kind = TYPE_NAME;
         t->name = strdup(name.c_str());
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
   } else if (lhs == TYPE_ERROR || rhs == TYPE_ERROR) {
      return false;
   } else if (lhs == rhs) {
      return true;
   }

   return false;
}

bool typesAreEquivalent(Type* lhs, Type* rhs) {
   if (!lhs || !rhs) {
       return false;
   }

   if (lhs->type->kind == TYPE_NULL || rhs->type->kind == TYPE_NULL) {
      return true;
   }

   if (primitiveTypesAreEquivalent(lhs->type->kind, rhs->type->kind)) {
      return true;
   } else if (lhs->type->kind == TYPE_REF && rhs->type->kind == TYPE_REF) {
      return typesAreEquals(lhs->ref, rhs->ref);
   } else if (lhs->type->kind == TYPE_NAME && rhs->type->kind == TYPE_NAME) {
      return strcmp(lhs->name, rhs->name) == 0;
   } else {
      return false;
   }
}

bool attributionTypesAreEquivalent(Type* lhs, Type* rhs) {
   if (!lhs || !rhs) {
       return false;
   } else if (rhs->type->kind == TYPE_NULL) {
      return true;
   } else if (primitiveTypesAreEquivalent(lhs->type->kind, rhs->type->kind)) {
      return  !(lhs->type->kind == TYPE_INT && rhs->type->kind == TYPE_FLOAT);
   } else if (lhs->type->kind == TYPE_REF && rhs->type->kind == TYPE_REF) {
      return typesAreEquals(lhs->ref, rhs->ref);
   } else if (lhs->type->kind == TYPE_NAME && rhs->type->kind == TYPE_NAME) {
      return strcmp(lhs->name, rhs->name) == 0;
   } else {
      return false;
   }
}

bool typesAreEquals(Type* lhs, Type* rhs) {
   if (!lhs || !rhs) {
      return false;
   } else if (lhs->type->kind == TYPE_REF && rhs->type->kind == TYPE_REF) {
      return typesAreEquals(lhs->ref, rhs->ref);
   } else if (lhs->type->kind == TYPE_NAME && rhs->type->kind == TYPE_NAME) {
      return strcmp(lhs->name, rhs->name) == 0;
   }
   
   return lhs->type->kind == rhs->type->kind;
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
   } else {
      return false;
   }
}

bool typesAreEquivalent(std::string lhs, std::string rhs) {
   Type* newLhs = createTypeByString(lhs);
   Type* newRhs = createTypeByString(rhs);

   bool result = typesAreEquivalent(newLhs, newRhs);

   if (newLhs) {
       if (newLhs->name) free(newLhs->name);
       delete newLhs;
   }
   if (newRhs) {
       if (newRhs->name) free(newRhs->name);
       delete newRhs;
   }

   return result;
}
