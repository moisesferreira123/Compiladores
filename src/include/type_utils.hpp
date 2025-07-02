#include "symbol_table.hpp"
#include <cstring>
#include <iostream>
#include <memory>
#include <string>
#include <typeinfo>
#include <unordered_map>
#include <utility>
#include <vector>

typedef enum {
   TYPE_NAME,
   TYPE_VOID,
   TYPE_INT,
   TYPE_FLOAT,
   TYPE_BOOL,
   TYPE_STRING,
   TYPE_NULL,
   TYPE_REF,
   TYPE_ERROR
} TypeKind;

struct Type {
   TypeKind kind;
   char* name;
   Type* ref;
};

struct ExpResult {
    Type* type;         // O tipo do resultado (que você já tem)
    std::string address;  // Onde o valor está (ex: "x", "5", "t3")
};

class Symbol;
class Variable;
class Program;
class Procedure;
class Struct;
class Enum;

int yylex(void);
void yyerror(char const* s);

bool isSpecialType(Symbol* sym);
bool isVariable(Symbol* sym);
bool isStruct(Symbol* sym);
bool isProcedure(Symbol* sym);
bool isEnum(Symbol* sym);

bool primitiveTypesAreEquivalent(TypeKind lhs, TypeKind rhs);
bool typesAreEquivalent(Type* lhs, Type* rhs);
bool attributionTypesAreEquivalent(Type* lhs, Type* rhs);
bool typesAreEquals(Type* lhs, Type* rhs);
bool typesAreEquivalent(std::string lhs, std::string rhs);
bool isArithmeticTypes(TypeKind lhs, TypeKind rhs);
TypeKind getPrimitiveTypeOfOperation(TypeKind lhs, TypeKind rhs);

std::string getType(Type* type);
Type* createPrimitiveType(TypeKind kind);
Type* createNonPrimitiveType(std::string name);
Type* createReferenceType(Type* refType);
Type* createTypeByString(std::string name);