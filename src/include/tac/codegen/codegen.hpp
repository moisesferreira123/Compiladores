// Em um novo arquivo "codegen.hpp"

#ifndef CODEGEN_HPP
#define CODEGEN_HPP

#include <string>
#include "tac/tac.hpp" 


// Gera um novo nome de variável temporária (ex: "_t0", "_t1", "_t2", ...)
std::string new_temp();

// Gera um novo nome de rótulo (ex: "_L0", "_L1", "_L2", ...)
std::string new_label();

std::vector<std::string> label_stack;


class CodeEmitter {
private:
    std::vector<Instruction> instructions; 

public:
    // Método principal para adicionar uma instrução à lista.
    void emit(const Instruction& instr);

    // Uma sobrecarga (helper) para facilitar a vida. Cria e adiciona a instrução em um só passo.
    void emit(OpCode op, std::string result, std::string arg1 = "", std::string arg2 = "");

    // Escreve o código C final no arquivo.
    void write_to_file(const std::string& filename);
};


#endif // CODEGEN_HPP