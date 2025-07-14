#ifndef UTILS_HPP
#define UTILS_HPP

/// Importações
#include "logger.hpp"
#include "symbol_table.hpp"
// #include "tac/codegen.hpp"
#include <iostream>
#include <memory>
#include <string>

/// Variáveis globais
extern int numLines;
extern int numCols;
extern SymbolTable symbolTable;
extern bool program_ok;
// extern CodeEmitter emitter;

/// Tipos
enum TypeKind {
   TYPE_INT,
   TYPE_FLOAT,
   TYPE_STRING,
   TYPE_BOOL,
   TYPE_VOID,
   TYPE_NULL,
   TYPE_REF,
   TYPE_STRUCT,
   TYPE_ENUM_VAR,
   TYPE_ENUM_VALUE,
   TYPE_ENUM,
   TYPE_ERROR
};

/// Tipos estruturais
struct Type {
   TypeKind kind;
   std::shared_ptr<Symbol> structured;
   Type* ref;
};

struct Paramfield {
   std::string name;
   Type* type;
};

struct TacOperand {
   Type* type; // O tipo do resultado (que você já tem)
   std::string loc; // Onde o valor está (ex: "x", "5", "t3")
};

/// Protótipos do Lexer
int yylex(void);
void yyerror(char const* s);

/// Funções de validação
bool isErrorType(Type* type);
bool isErrorKind(TypeKind kind);
bool isVoidKind(TypeKind kind);
bool isNullKind(TypeKind kind);
bool isPrimitiveKind(TypeKind kind);
bool isSpecialKind(TypeKind kind);
bool isReferenceKind(TypeKind kind);
bool isEnumValueKind(TypeKind kind);
bool isEnumVarKind(TypeKind kind);
bool isAssignable(Type* to, Type* from);
bool isEqualType(Type* first, Type* second);
bool isSubjectToExpansion(TypeKind to, TypeKind from);

/// Função que pega o tipo com alargamento
Type* getExpandedType(Type* first, Type* second);

/// Funções de processamento
void processProgram(bool ok);
bool processVarDecl(Type* type, Type* var_decl_2, char* name);
bool processVarDecl(Type* exp, char* name);
bool processProcedureDecl(char* name,
  std::vector<Paramfield*>* procedure_params, Type* return_type,
  bool scope_declarations, Type* stmt_list);
bool processRecordDecl(char* name, std::vector<Paramfield*>* record_fields);
bool processEnumDecl(char* name, std::vector<std::string>* values);
Type* processStmtList(Type* first_stmt, Type* second_stmt);
void processParamfieldDecl(Paramfield* paramfield);
Type* processVar(char* name);
Type* processVar(Type* exp, char* name);
Type* processDerefVar(Type* var);
bool processAssignStmt(Type* var, Type* exp);
Type* processAssignStmtToStmt(bool assign_stmt);
Type* processCallStmtToStmt(Type* call_stmt);
Type* processIfStmt(Type* exp, Type* stmt_list, Type* if_stmt2);
Type* processWhileStmt(Type* exp, Type* stmt_list);
std::vector<TacOperand*>* processCallArgs(
  TacOperand* exp, std::vector<TacOperand*>* call_args);
TacOperand* processCallStmt(char* name, std::vector<TacOperand*>* call_args);
Type* processTypeName(char* name);
Type* processExp(Type* exp1, std::string op, Type* exp2);
Type* processExp(std::string op, Type* exp1);
Type* processExp(std::string name);

/// Funções de inserção
void insertVariable(std::string name, Type* type);
bool insertProcedure(
  std::string name, Type* type, std::vector<std::shared_ptr<Variable>> params);
bool insertRecord(
  std::string name, std::vector<std::shared_ptr<Variable>> fields);
bool insertEnum(std::string name, std::vector<std::string>* values);

/// Funções de criação de tipos
Type* createTypeError();
Type* createTypeVoid();
Type* createTypeNull();
Type* createType(TypeKind kind);
Type* createType(TypeKind kind, std::shared_ptr<Symbol> symbol);
Type* createType(Type* ref);
Type* createType(VariableType* varType);
VariableType* createVariableType(Type* type);

/// Funções de conversão
std::string getTypeStr(Type* type);

/// Funções de chamada de erro
void variableRedeclaredError(std::string name);
void variableInvalidError(std::string name);
void variableDeclaredNullError(std::string name);
void variableNotAssignableError(std::string name, Type* to, Type* from);
void variableNotDeclaredError(std::string name);
void expectedVariableError(std::string name);
void procedureDeclaredError(std::string name);
void procedureReturnTypeError(std::string name);
void procedureRedeclaredError(std::string name);
void procedureNotAssignableError(std::string name, Type* to, Type* from);
void recordFieldsNotDeclaredError(std::string name);
void recordRedeclaredError(std::string name);
void enumRedeclaredValueError(std::string name, std::string value);
void enumRedeclaredError(std::string name);
void enumValueNotDeclaredError(std::string name, std::string value);
void statementsNotAssignableError(Type* to, Type* from);
void expectedSpecialTypeError(Type* type);
void expectedRecordError(std::string name);
void expectedReferenceTypeError(Type* type);
void expectedBooleanTypeError(Type* type);
void statementNotValidError();
void varAssignmentError(Type* var, Type* exp);
void argumentNotValidError();
void procedureNotDeclaredError(std::string name);
void expectedProcedureError(std::string name);
void argumentSizeError(int expected, int actual);
void argumentTypeError(int index, Type* expected, Type* actual);
void specialTypeNotDeclaredError(std::string name);
void expectedSpecialSymbolError(std::string name);
void operationNotValidError(std::string op);
void operationNotValidError(Type* exp1, std::string op, Type* exp2);
void minusUnitaryNotValidError(Type* exp);

/// Funções do Tac
std::string getUniqueName(std::string name);
std::string getTacType(Type* type);

#endif /// UTILS_HPP