#ifndef TAC_HPP
#define TAC_HPP

#include <string>
#include <vector>

// Enum para todos os tipos de operação possíveis no nosso TAC.
enum class OpCode {
   TAC_ATR, // result = arg1

   // Operadores Aritméticos
   TAC_ADD, // result = arg1 + arg2
   TAC_SUB, // result = arg1 - arg2
   TAC_MULT, // result = arg1 * arg2
   TAC_DIV, // result = arg1 / arg2
   TAC_POT, // result = arg1 ^ arg2
   TAC_UNARY_MINUS, // result = -arg1 (Menos unário)

   TAC_EQ, // result = (arg1 == arg2)
   TAC_NEQ, // result = (arg1 != arg2)
   TAC_LT, // result = (arg1 <  arg2)
   TAC_GT, // result = (arg1 >  arg2)
   TAC_LE, // result = (arg1 <= arg2)
   TAC_GE, // result = (arg1 >= arg2)

   TAC_OR, // result = (arg1 > arg2)
   TAC_AND, // result = (arg1 > arg2)
   TAC_NOT, // result = (arg1 > arg2)

   // Controle de Fluxo
   TAC_GOTO, // goto result
   TAC_IF_GOTO, // if (arg1 != 0) goto result
   TAC_IF_FALSE_GOTO,
   TAC_LABEL, // result:

   // Atribuição e Chamadas
   TAC_ASSIGN, // result = arg1
   TAC_PARAM, // Declara um parâmetro para a próxima chamada
   TAC_CALL, // result = call arg1 (arg1 é o nome da função)
   TAC_RETURN, // return result

   TAC_REF, // result = &arg1          (para ref(var))
   TAC_DEREF, // result = *arg1          (para x = *p)
   TAC_DEREF_ASSIGN, // *result = arg1          (para *p = x)

   TAC_MEMBER_READ, // result = arg1.arg2       (para x = s.f)
   TAC_MEMBER_ASSIGN, // result.arg1 = arg2       (para s.f = x)

   TAC_MEMBER_ACCESS,
   TAC_NEW,

   /// Declaração
   TAC_VAR_DECL,
<<<<<<< HEAD
   // Para acesso a membros de struct, etc. (Podemos adicionar depois)
   TAC_STRUCT_DECL,
   TAC_STRUCT_DECL_CLOSE,
=======
   TAC_STRUCT_DECL,
   TAC_STRUCT_DECL_CLOSE,
    // Para acesso a membros de struct, etc. (Podemos adicionar depois)
>>>>>>> d31d2ecb684635b3e82eb1c6c407635355855dde
};

// A estrutura que representa uma única instrução TAC.
struct TAC_Instruction {
   OpCode op;
   std::string type;
   std::string result;
   std::string arg1; // Primeiro operando ou condição do if.
   std::string arg2; // Segundo operando.

   // Um construtor para facilitar a criação de novas instruções.
   TAC_Instruction(
     OpCode o, std::string r, std::string a1 = "", std::string a2 = "")
       : op(o)
       , result(std::move(r))
       , arg1(std::move(a1))
       , arg2(std::move(a2)) { }

   TAC_Instruction(std::string t, OpCode o, std::string r, std::string a1 = "",
     std::string a2 = "")
       : op(o)
       , type(t)
       , result(std::move(r))
       , arg1(std::move(a1))
       , arg2(std::move(a2)) { }
};

#endif // TAC_HPP
