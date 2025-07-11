// Em um novo arquivo "codegen.hpp"

#ifndef CODEGEN_HPP
#define CODEGEN_HPP

#include <string>
#include "tac.hpp" 


// Gera um novo nome de variável temporária (ex: "_t0", "_t1", "_t2", ...)
std::string new_temp();

// Gera um novo nome de rótulo (ex: "_L0", "_L1", "_L2", ...)
std::string new_label();

extern std::vector<std::string> label_stack;

// Nova pilha para o contexto do procedimento
extern std::vector<std::string> procedure_context_stack;

class CodeEmitter {
private:
    std::vector<TAC_Instruction> instructions; 

public:
    // Método principal para adicionar uma instrução à lista.
    void emit(const TAC_Instruction& instr);

    // Uma sobrecarga (helper) para facilitar a vida. Cria e adiciona a instrução em um só passo.
    void emit(OpCode op, std::string result, std::string arg1 = "", std::string arg2 = "");

    ///void emitProcedureBegin(const std::string& procedure_name);
    
    ///void emitProcedureParams(std::vector<Paramfield*>* procedure_params);
    
    void emitProcedureEnd();

    // Escreve o código C final no arquivo.
    void write_to_file(const std::string& filename);
};

extern CodeEmitter emitter;


#endif // CODEGEN_HPP