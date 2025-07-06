#include "utils.hpp"
#include <set>

bool program_ok = false;

void yyerror(const char* s) {
   Logger::error(std::string(s), numLines, numCols, false);
}

bool isErrorType(Type* type) {
   if (isErrorKind(type->kind)) {
      return true;
   } else if (isReferenceKind(type->kind)) {
      return isErrorType(type->ref);
   } else {
      return false;
   }
}

bool isErrorKind(TypeKind kind) { return kind == TYPE_ERROR; }

bool isVoidKind(TypeKind kind) { return kind == TYPE_VOID; }

bool isNullKind(TypeKind kind) { return kind == TYPE_NULL; }

bool isPrimitiveKind(TypeKind kind) {
   return kind == TYPE_INT || kind == TYPE_FLOAT || kind == TYPE_STRING
     || kind == TYPE_BOOL;
}

bool isSpecialKind(TypeKind kind) {
   return kind == TYPE_STRUCT || kind == TYPE_ENUM;
}

bool isReferenceKind(TypeKind kind) { return kind == TYPE_REF; }

bool isSubjectToExpansion(TypeKind to, TypeKind from) {
   if (to == TYPE_FLOAT && from == TYPE_INT) {
      return true;
   } else if (to == TYPE_INT && from == TYPE_BOOL) {
      return true;
   }

   return false;
}

bool isEqualType(Type* first, Type* second) {
   if (isPrimitiveKind(first->kind) && isPrimitiveKind(second->kind)) {
      return first->kind == second->kind;
   } else if (isReferenceKind(first->kind) && isReferenceKind(second->kind)) {
      return isEqualType(first->ref, second->ref);
   } else if (isSpecialKind(first->kind) && isSpecialKind(second->kind)) {
      return first->structured == second->structured;
   } else {
      return false;
   }
}

bool isAssignable(Type* to, Type* from) {
   if (isErrorType(to) || isErrorType(from)) {
      return false; // Um dos tipos era inválido
   } else if (isVoidKind(to->kind) || isVoidKind(from->kind)) {
      return false; // Um dos tipos era void
   } else if (isNullKind(from->kind)) {
      return true; // O tipo de origem é null (compatibilidade explícita)
   } else if (isPrimitiveKind(to->kind) && isPrimitiveKind(from->kind)) {
      // Os tipos eram primitivos
      if (to->kind == from->kind) {
         return true; // Os tipos eram iguais
      } else {
         return isSubjectToExpansion(to->kind, from->kind); // Substituição
      }
   } else if (isReferenceKind(to->kind) && isReferenceKind(from->kind)) {
      return isEqualType(to->ref, from->ref); // Ambos são referencias
   } else if (isSpecialKind(to->kind) && isSpecialKind(from->kind)) {
      return to->structured == from->structured; // Ambos eram estruturais
   } else if (to->kind == TYPE_ENUM) {
      return from->kind == TYPE_INT
        || (from->kind == TYPE_ENUM && to->structured == from->structured);
   } else {
      return false;
   }
}

Type* getExpandedType(Type* first, Type* second) {
   if (isPrimitiveKind(first->kind) && isPrimitiveKind(second->kind)) {
      if ((first->kind == TYPE_FLOAT && second->kind == TYPE_INT)
        || (first->kind == TYPE_INT && second->kind == TYPE_FLOAT)) {
         /// Int + Float = Float
         return createType(TYPE_FLOAT);
      } else if ((first->kind == TYPE_INT && second->kind == TYPE_BOOL)
        || (first->kind == TYPE_BOOL && second->kind == TYPE_INT)) {
         /// Int + Bool = Int
         return createType(TYPE_INT);
      } else if (first->kind == second->kind) {
         /// Os tipos eram iguais
         return new Type(*first);
      } else {
         return createTypeError();
      }
   } else if (isEqualType(first, second)) {
      /// Os tipos eram iguais (ref ou estrutural)
      return new Type(*first);
   } else {
      return createTypeError();
   }
}

void processProgram(bool ok) {
   if (ok) {
      Logger::info("Nenhum erro encontrado. Gerando código de máquina.");

      // TODO: Gerar código intermediário

      Logger::success("Análise sintática concluída com sucesso: estrutura do "
                      "programa válida.");
   } else {
      Logger::error("Análise sintática concluída com erro.");
   }
}

bool processVarDecl(Type* type, Type* var_decl_2, char* name) {
   // Busca na tabela de símbolos apenas no nó atual
   std::shared_ptr<Symbol> symbol
     = symbolTable.single_lookup(std::string(name));

   if (symbol != nullptr) {
      // Variável redeclarada
      variableRedeclaredError(std::string(name));
      return false;
   } else if (isErrorType(type) || isErrorType(var_decl_2)) {
      // Um dos tipos era inválido
      variableInvalidError(std::string(name));
      return false;
   } else if (isNullKind(type->kind)) {
      // O tipo da variável era null
      variableDeclaredNullError(std::string(name));
      return false;
   } else if (!isAssignable(type, var_decl_2)) {
      // Os tipos eram incompatíveis
      variableNotAssignableError(std::string(name), type, var_decl_2);
      return false;
   } else {
      // Variável declarada
      insertVariable(std::string(name), type);
      return true;
   }
}

bool processVarDecl(Type* exp, char* name) {
   return processVarDecl(exp, exp, name);
}

bool processProcedureDecl(char* name,
  std::vector<Paramfield*>* procedure_params, Type* return_type,
  bool scope_declarations, Type* stmt_list) {
   if (!scope_declarations) {
      procedureDeclaredError(std::string(name));
      symbolTable.exitScope();
      return false;
   } else if (isErrorType(return_type)) {
      // O tipo de retorno era inválido
      procedureReturnTypeError(std::string(name));
      symbolTable.exitScope();
      return false;
   } else if (isErrorType(stmt_list)) {
      // O tipo do corpo era inválido
      procedureDeclaredError(std::string(name));
      symbolTable.exitScope();
      return false;
   } else if (!isVoidKind(return_type->kind)
     && !isAssignable(return_type, stmt_list)) {
      // Os tipos eram incompatíveis
      procedureNotAssignableError(std::string(name), return_type, stmt_list);
      symbolTable.exitScope();
      return false;
   } else {
      // Verificação dos tipos dos parâmetros
      std::vector<std::shared_ptr<Variable>> procedureParams;
      for (Paramfield* param : *procedure_params) {
         if (isErrorType(param->type)) {
            variableInvalidError(param->name);
            return false;
         }

         std::shared_ptr<Symbol> symbol
           = symbolTable.single_lookup(param->name);

         if (symbol == nullptr) {
            // Variável não declarada
            variableNotDeclaredError(param->name);
            return false;
         } else if (auto var = std::dynamic_pointer_cast<Variable>(symbol)) {
            //  Variável existente
            procedureParams.push_back(var);
         } else {
            expectedVariableError(param->name);
            return false;
         }
      }

      // Procedimento declarado
      return insertProcedure(name, return_type, procedureParams);
   }
}

void processParamfieldDecl(Paramfield* paramfield) {
   // Busca na tabela de símbolos apenas no nó atual
   std::shared_ptr<Symbol> symbol = symbolTable.single_lookup(paramfield->name);

   if (symbol != nullptr) {
      // Variável redeclarada
      variableRedeclaredError(paramfield->name);
   } else if (isErrorType(paramfield->type)) {
      //  O tipo da variável era inválido
      variableInvalidError(paramfield->name);
   } else if (isNullKind(paramfield->type->kind)) {
      // O tipo da variável era null
      variableDeclaredNullError(paramfield->name);
   } else {
      // Variável declarada
      insertVariable(paramfield->name, paramfield->type);
   }
}

bool processRecordDecl(char* name, std::vector<Paramfield*>* record_fields) {
   if (!record_fields) {
      recordFieldsNotDeclaredError(std::string(name));
      symbolTable.exitScope();
      return false;
   } else {
      // Verificação dos tipos dos campos
      std::vector<std::shared_ptr<Variable>> recordFields;
      for (Paramfield* field : *record_fields) {
         if (isErrorType(field->type)) {
            // O tipo do campo era inválido
            variableInvalidError(field->name);
            return false;
         }

         std::shared_ptr<Symbol> symbol
           = symbolTable.single_lookup(field->name);

         if (symbol == nullptr) {
            // Variável não declarada
            variableNotDeclaredError(field->name);
            return false;
         } else if (auto var = std::dynamic_pointer_cast<Variable>(symbol)) {
            //  Variável existente
            recordFields.push_back(var);
         } else {
            // Campo não é uma variável
            expectedVariableError(field->name);
            return false;
            break;
         }
      }

      // Registro declarado
      return insertRecord(name, recordFields);
   }
}

bool processEnumDecl(char* name, std::vector<std::string>* values) {
   std::set<std::string> unique_values;

   for (std::string value : *values) {
      if (unique_values.count(value) > 0) {
         enumRedeclaredValueError(name, value);
         return false;
      }
      unique_values.insert(value);
   }

   return insertEnum(name, values);
}

Type* processStmtList(Type* first_stmt, Type* second_stmt) {
   if (isVoidKind(first_stmt->kind) && isVoidKind(second_stmt->kind)) {
      return createTypeVoid();
   } else if (isVoidKind(first_stmt->kind)) {
      return new Type(*second_stmt);
   } else if (isVoidKind(second_stmt->kind)) {
      return new Type(*first_stmt);
   } else if (isErrorType(first_stmt) || isErrorType(second_stmt)) {
      return createTypeError();
   } else if (isAssignable(first_stmt, second_stmt)
     || isAssignable(second_stmt, first_stmt)) {
      return getExpandedType(first_stmt, second_stmt);
   } else {
      statementsNotAssignableError(first_stmt, second_stmt);
      return createTypeError();
   }
}

Type* processVar(char* name) {
   std::shared_ptr<Symbol> symbol = symbolTable.lookup(name);
   if (symbol == nullptr) {
      variableNotDeclaredError(name);
      return createTypeError();
   } else if (auto var = std::dynamic_pointer_cast<Variable>(symbol)) {
      return createType(var->getType());
   } else if (auto enumerate = std::dynamic_pointer_cast<Enum>(symbol)) {
      return createType(TYPE_ENUM, symbol);
   } else {
      expectedVariableError(name);
      return createTypeError();
   }
}

Type* processVar(Type* exp, char* name) {
   if (isSpecialKind(exp->kind) && exp->structured) {
      std::shared_ptr<Symbol> structured = exp->structured;

      if (exp->kind == TYPE_STRUCT) {
         if (auto record = std::dynamic_pointer_cast<Struct>(structured)) {
            for (std::shared_ptr<Variable> field : record->getFields()) {
               if (field->getName() == name) {
                  return createType(field->getType());
               }
            }

            variableNotDeclaredError(name);
            return createTypeError();
         } else {
            expectedRecordError(structured->getName());
            return createTypeError();
         }
      } else {
         if (auto enumerate = std::dynamic_pointer_cast<Enum>(structured)) {
            for (std::string value : enumerate->getValues()) {
               if (value == name) {
                  return createType(TYPE_INT);
               }
            }

            enumValueNotDeclaredError(enumerate->getName(), name);
            return createTypeError();
         } else {
            expectedRecordError(structured->getName());
            return createTypeError();
         }
      }
   } else {
      expectedSpecialTypeError(exp);
      return createTypeError();
   }
}

Type* processDerefVar(Type* var) {
   if (isReferenceKind(var->kind)) {
      return var->ref;
   } else {
      expectedReferenceTypeError(var);
      return createTypeError();
   }
}

bool processAssignStmt(Type* var, Type* exp) {
   if (!isAssignable(var, exp)) {
      varAssignmentError(var, exp);
      return false;
   } else {
      return true;
   }
}

Type* processAssignStmtToStmt(bool assign_stmt) {
   if (assign_stmt) {
      return createTypeVoid();
   } else {
      statementNotValidError();
      return createTypeError();
   }
}

Type* processCallStmtToStmt(Type* call_stmt) {
   if (isErrorType(call_stmt)) {
      statementNotValidError();
      return createTypeError();
   } else {
      return createTypeVoid();
   }
}

Type* processIfStmt(Type* exp, Type* stmt_list, Type* if_stmt2) {
   if (exp->kind != TYPE_BOOL) {
      expectedBooleanTypeError(exp);
      return createTypeError();
   } else {
      return processStmtList(stmt_list, if_stmt2);
   }
}

Type* processWhileStmt(Type* exp, Type* stmt_list) {
   if (exp->kind != TYPE_BOOL) {
      expectedBooleanTypeError(exp);
      return createTypeError();
   } else {
      return processStmtList(stmt_list, stmt_list);
   }
}

std::vector<Type*>* processCallArgs(Type* exp, std::vector<Type*>* call_args) {
   if (isErrorType(exp)) {
      argumentNotValidError();
      return call_args;
   } else {
      call_args->insert(call_args->begin(), exp);
      return call_args;
   }
}

Type* processCallStmt(char* name, std::vector<Type*>* call_args) {
   std::shared_ptr<Symbol> symbol = symbolTable.lookup(name);

   if (symbol == nullptr) {
      procedureNotDeclaredError(name);
      return createTypeError();
   } else if (auto procedure = std::dynamic_pointer_cast<Procedure>(symbol)) {
      std::vector<std::shared_ptr<Variable>> params = procedure->getParams();
      int argumentsCount = params.size();

      if (argumentsCount != call_args->size()) {
         argumentSizeError(argumentsCount, call_args->size());

         return createTypeError();
      }

      for (int i = 0; i < argumentsCount; i++) {
         Type* argumentType = createType(params[i]->getType());
         Type* callArgType = call_args->at(i);

         if (!isAssignable(argumentType, callArgType)) {
            argumentTypeError(i, argumentType, callArgType);
            delete argumentType;
            return createTypeError();
         } else {
            delete argumentType;
         }
      }

      return createType(procedure->getType());
   } else {
      expectedProcedureError(name);
      return createTypeError();
   }
}

Type* processTypeName(char* name) {
   std::shared_ptr<Symbol> symbol = symbolTable.lookup(name);

   if (symbol == nullptr) {
      specialTypeNotDeclaredError(name);
      return createTypeError();
   } else if (std::dynamic_pointer_cast<Struct>(symbol)) {
      return createType(TYPE_STRUCT, symbol);
   } else if (std::dynamic_pointer_cast<Enum>(symbol)) {
      return createType(TYPE_ENUM, symbol);
   } else {
      expectedSpecialSymbolError(name);
      return createTypeError();
   }
}

Type* processExp(Type* exp1, std::string op, Type* exp2) {
   if (isErrorType(exp1) || isErrorType(exp2)) {
      return createTypeError();
   }

   if (op == "||" || op == "&&") {
      if (exp1->kind != TYPE_BOOL) {
         expectedBooleanTypeError(exp1);
         return createTypeError();
      } else if (exp2->kind != TYPE_BOOL) {
         expectedBooleanTypeError(exp2);
         return createTypeError();
      } else {
         return createType(TYPE_BOOL);
      }
   } else if (op == "rel") {
      if (isPrimitiveKind(exp1->kind) && isPrimitiveKind(exp2->kind)) {
         if (isAssignable(exp1, exp2) || isAssignable(exp2, exp1)) {
            return createType(TYPE_BOOL);
         } else {
            operationNotValidError(exp1, op, exp2);
            return createTypeError();
         }
      } else {
         operationNotValidError(exp1, op, exp2);
         return createTypeError();
      }
   } else if (op == "+" || op == "-" || op == "*" || op == "/") {
      if ((exp1->kind == TYPE_INT || exp1->kind == TYPE_FLOAT)
        && (exp2->kind == TYPE_INT || exp2->kind == TYPE_FLOAT)) {
         return getExpandedType(exp1, exp2);
      } else {
         operationNotValidError(exp1, op, exp2);
         return createTypeError();
      }
   } else if (op == "^") {
      if ((exp1->kind == TYPE_INT || exp1->kind == TYPE_FLOAT)
        && (exp2->kind == TYPE_INT || exp2->kind == TYPE_FLOAT)) {
         return createType(TYPE_FLOAT);
      } else {
         operationNotValidError(exp1, op, exp2);
         return createTypeError();
      }
   } else {
      operationNotValidError(exp1, op, exp2);
      return createTypeError();
   }
}

Type* processExp(std::string op, Type* exp1) {
   if (isErrorType(exp1)) {
      return createTypeError();
   }

   if (op == "not") {
      if (exp1->kind != TYPE_BOOL) {
         expectedBooleanTypeError(exp1);
         return createTypeError();
      } else {
         return createType(TYPE_BOOL);
      }
   } else if (op == "-") {
      if (exp1->kind == TYPE_INT || exp1->kind == TYPE_FLOAT) {
         return new Type(*exp1);
      } else {
         minusUnitaryNotValidError(exp1);
         return createTypeError();
      }
   } else {
      return createTypeError();
   }
}

Type* processExp(std::string name) {
   std::shared_ptr<Symbol> symbol = symbolTable.lookup(name);

   if (symbol == nullptr) {
      specialTypeNotDeclaredError(name);
      return createTypeError();
   } else if (auto structured = std::dynamic_pointer_cast<Struct>(symbol)) {
      return createType(TYPE_STRUCT, symbol);
   } else if (auto enumerate = std::dynamic_pointer_cast<Enum>(symbol)) {
      return createType(TYPE_ENUM, enumerate);
   } else {
      expectedSpecialSymbolError(name);
      return createTypeError();
   }
}

void insertVariable(std::string name, Type* type) {
   VariableType* varType = createVariableType(type);
   symbolTable.insert(std::make_shared<Variable>(name, varType));
}

bool insertProcedure(
  std::string name, Type* type, std::vector<std::shared_ptr<Variable>> params) {
   symbolTable.exitScope();

   std::shared_ptr<Symbol> symbol = symbolTable.single_lookup(name);
   if (symbol != nullptr) {
      // Procedimento redeclarado
      procedureRedeclaredError(name);
      return false;
   }

   VariableType* procedureType = createVariableType(type);
   symbolTable.insert(std::make_shared<Procedure>(name, procedureType, params));

   return true;
}

bool insertRecord(
  std::string name, std::vector<std::shared_ptr<Variable>> fields) {
   symbolTable.exitScope();

   std::shared_ptr<Symbol> symbol = symbolTable.single_lookup(name);
   if (symbol != nullptr) {
      // Registro redeclarado
      recordRedeclaredError(name);
      return false;
   }

   symbolTable.insert(std::make_shared<Struct>(name, fields));

   return true;
}

bool insertEnum(std::string name, std::vector<std::string>* values) {
   std::shared_ptr<Symbol> symbol = symbolTable.single_lookup(name);

   if (symbol != nullptr) {
      // Enum redeclarado
      enumRedeclaredError(name);
      return false;
   }

   symbolTable.insert(std::make_shared<Enum>(name, *values));
   return true;
}

Type* createTypeError() { return new Type { TYPE_ERROR, nullptr, nullptr }; }
Type* createTypeVoid() { return new Type { TYPE_VOID, nullptr, nullptr }; }
Type* createTypeNull() { return new Type { TYPE_NULL, nullptr, nullptr }; }

Type* createType(TypeKind kind) {
   if (isPrimitiveKind(kind)) {
      return new Type { kind, nullptr, nullptr };
   }

   return createTypeError();
}

Type* createType(TypeKind kind, std::shared_ptr<Symbol> symbol) {
   if (isSpecialKind(kind) && symbol) {
      return new Type { kind, symbol, nullptr };
   }

   return createTypeError();
}

Type* createType(Type* ref) {
   if (ref != nullptr) {
      return new Type { TYPE_REF, nullptr, ref };
   }

   return createTypeError();
}

Type* createType(VariableType* varType) {
   if (varType && dynamic_cast<PrimitiveType*>(varType)) {
      PrimitiveType* primitiveType = dynamic_cast<PrimitiveType*>(varType);

      if (primitiveType->getType() == "int") {
         return createType(TYPE_INT);
      } else if (primitiveType->getType() == "float") {
         return createType(TYPE_FLOAT);
      } else if (primitiveType->getType() == "bool") {
         return createType(TYPE_BOOL);
      } else if (primitiveType->getType() == "string") {
         return createType(TYPE_STRING);
      } else if (primitiveType->getType() == "void") {
         return createTypeVoid();
      } else {
         return createTypeError();
      }
   } else if (varType && dynamic_cast<StructuredType*>(varType)) {
      StructuredType* structuredType = dynamic_cast<StructuredType*>(varType);
      std::shared_ptr<Symbol> type = structuredType->getType();

      if (dynamic_cast<Struct*>(type.get())) {
         return createType(TYPE_STRUCT, type);
      } else if (dynamic_cast<Enum*>(type.get())) {
         return createType(TYPE_ENUM, type);
      } else {
         return createTypeError();
      }
   } else if (varType && dynamic_cast<ReferenceType*>(varType)) {
      ReferenceType* referenceType = dynamic_cast<ReferenceType*>(varType);
      return createType(createType(referenceType->getType()));
   } else {
      return createTypeError();
   }
}

VariableType* createVariableType(Type* type) {
   if (isPrimitiveKind(type->kind)) {
      return new PrimitiveType(getTypeStr(type));
   } else if (isSpecialKind(type->kind)) {
      return new StructuredType(type->structured);
   } else if (isReferenceKind(type->kind)) {
      return new ReferenceType(createVariableType(type->ref));
   } else if (isVoidKind(type->kind)) {
      return new PrimitiveType(getTypeStr(type));
   }

   return nullptr;
}

std::string getTypeStr(Type* type) {
   if (type == nullptr) {
      return "null";
   } else if (type->kind == TYPE_ERROR) {
      return "error";
   } else if (type->kind == TYPE_VOID) {
      return "void";
   } else if (type->kind == TYPE_INT) {
      return "int";
   } else if (type->kind == TYPE_FLOAT) {
      return "float";
   } else if (type->kind == TYPE_STRING) {
      return "string";
   } else if (type->kind == TYPE_BOOL) {
      return "bool";
   } else if (type->kind == TYPE_NULL) {
      return "null";
   } else if (type->kind == TYPE_REF) {
      return "*" + getTypeStr(type->ref);
   } else if (type->kind == TYPE_STRUCT || type->kind == TYPE_ENUM) {
      return type->structured->getName() + "["
        + std::to_string(
          reinterpret_cast<std::uintptr_t>(type->structured.get()))
        + "]";
   } else {
      return "error";
   }
}

void variableRedeclaredError(std::string name) {
   std::string error
     = "Erro semântico: redeclaração da variável \"" + name + "\".";
   yyerror(error.c_str());
}
void variableInvalidError(std::string name) {
   std::string error
     = "Erro semântico: declaração da variável \"" + name + "\" inválida.";
   yyerror(error.c_str());
}
void variableDeclaredNullError(std::string name) {
   std::string error = "Erro semântico: declaração da variável \"" + name
     + "\" não pode ser null.";
   yyerror(error.c_str());
}

void variableNotAssignableError(std::string name, Type* to, Type* from) {
   std::string error
     = std::string("Erro semântico: a variável \"" + name + "\" do tipo \"")
     + getTypeStr(to) + "\" não pode ser atribuída com o tipo \""
     + getTypeStr(from) + "\".";
   yyerror(error.c_str());
}

void variableNotDeclaredError(std::string name) {
   std::string error
     = "Erro semântico: a variável \"" + name + "\" não foi declarada.";
   yyerror(error.c_str());
}

void procedureDeclaredError(std::string name) {
   std::string error
     = "Erro semântico: declaração do procedimento \"" + name + "\" inválida.";
   yyerror(error.c_str());
}

void procedureReturnTypeError(std::string name) {
   std::string error = "Erro semântico: declaração do procedimento \"" + name
     + "\" com retorno de tipo inválido.";
   yyerror(error.c_str());
}

void procedureNotAssignableError(std::string name, Type* to, Type* from) {
   std::string error
     = std::string("Erro semântico: o procedimento \"" + name + "\" do tipo \"")
     + getTypeStr(to) + "\" não pode ser atribuído com o tipo \""
     + getTypeStr(from) + "\".";
   yyerror(error.c_str());
}

void procedureRedeclaredError(std::string name) {
   std::string error
     = "Erro semântico: redeclaração do procedimento \"" + name + "\".";
   yyerror(error.c_str());
}

void expectedVariableError(std::string name) {
   std::string error = "Erro semântico: o símbolo \"" + name
     + "\" não representa uma variável.";
   yyerror(error.c_str());
}

void recordFieldsNotDeclaredError(std::string name) {
   std::string error = "Erro semântico: o struct \"" + name
     + "\" possui campos não declarados.";
   yyerror(error.c_str());
}

void recordRedeclaredError(std::string name) {
   std::string error
     = "Erro semântico: redeclaração do struct \"" + name + "\".";
   yyerror(error.c_str());
}

void enumRedeclaredValueError(std::string name, std::string value) {
   std::string error = "Erro semântico: redeclaração do valor \"" + value
     + "\" no enum \"" + name + "\".";
   yyerror(error.c_str());
}

void enumRedeclaredError(std::string name) {
   std::string error = "Erro semântico: redeclaração do enum \"" + name + "\".";
   yyerror(error.c_str());
}

void statementsNotAssignableError(Type* to, Type* from) {
   std::string error = std::string("Erro semântico: as declarações do tipo \"")
     + getTypeStr(to) + "\" e do tipo \"" + getTypeStr(from)
     + "\" não são compatíveis no mesmo escopo.";
   yyerror(error.c_str());
}

void expectedSpecialTypeError(Type* type) {
   std::string error = "Erro semântico: o tipo \"" + getTypeStr(type)
     + "\" não é um tipo especial.";
   yyerror(error.c_str());
}

void expectedRecordError(std::string name) {
   std::string error = "Erro semântico: o símbolo \"" + name
     + "\" não representa uma estrutura.";
   yyerror(error.c_str());
}

void enumValueNotDeclaredError(std::string name, std::string value) {
   std::string error = "Erro semântico: o valor \"" + value
     + "\" não existe no enum \"" + name + "\".";
   yyerror(error.c_str());
}

void expectedReferenceTypeError(Type* type) {
   std::string error = "Erro semântico: o tipo \"" + getTypeStr(type)
     + "\" precisa ser uma referência.";
   yyerror(error.c_str());
}

void expectedBooleanTypeError(Type* type) {
   std::string error = "Erro semântico: o tipo \"" + getTypeStr(type)
     + "\" precisa ser booleano.";
   yyerror(error.c_str());
}

void statementNotValidError() {
   std::string error = "Erro semântico: declarações inválidas.";
   yyerror(error.c_str());
}

void varAssignmentError(Type* var, Type* exp) {
   std::string error = "Erro semântico: a variável do tipo \"" + getTypeStr(var)
     + "\" não pode ser atribuída com o tipo \"" + getTypeStr(exp) + "\".";
   yyerror(error.c_str());
}

void argumentNotValidError() {
   std::string error
     = "Erro semântico: argumento inválido para chamada de função";
   yyerror(error.c_str());
}

void procedureNotDeclaredError(std::string name) {
   std::string error
     = "Erro semântico: o procedimento \"" + name + "\" não foi declarado.";
   yyerror(error.c_str());
}

void expectedProcedureError(std::string name) {
   std::string error = "Erro semântico: o símbolo \"" + name
     + "\" não representa um procedimento.";
   yyerror(error.c_str());
}

void argumentSizeError(int expected, int actual) {
   std::string error = "Erro semântico: o procedimento recebe "
     + std::to_string(expected) + " argumentos, mas recebeu "
     + std::to_string(actual) + ".";
   yyerror(error.c_str());
}

void argumentTypeError(int index, Type* expected, Type* actual) {
   std::string error = "Erro semântico: o argumento " + std::to_string(index)
     + " do procedimento recebe o tipo \"" + getTypeStr(expected)
     + "\", mas recebeu o tipo \"" + getTypeStr(actual) + "\".";
   yyerror(error.c_str());
}

void specialTypeNotDeclaredError(std::string name) {
   std::string error
     = "Erro semântico: o tipo especial \"" + name + "\" não foi declarado.";
   yyerror(error.c_str());
}

void expectedSpecialSymbolError(std::string name) {
   std::string error = "Erro semântico: o símbolo \"" + name
     + "\" não representa um tipo especial.";
   yyerror(error.c_str());
}

void operationNotValidError(std::string op) {
   std::string error = "Erro semântico: operador \"" + op + "\" inválido.";
   yyerror(error.c_str());
}

void operationNotValidError(Type* exp1, std::string op, Type* exp2) {
   std::string error = "Erro semântico: operador \"" + op
     + "\" inválido entre os tipos \"" + getTypeStr(exp1) + "\" e \""
     + getTypeStr(exp2) + "\".";
   yyerror(error.c_str());
}

void minusUnitaryNotValidError(Type* exp) {
   std::string error = "Erro semântico: operador \"-\" inválido para o tipo \""
     + getTypeStr(exp) + "\".";
   yyerror(error.c_str());
}