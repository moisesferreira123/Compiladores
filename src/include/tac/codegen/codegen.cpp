// Em um novo arquivo "codegen.cpp"

#include "codegen.hpp"
#include <fstream>   
#include <set>       
#include <iostream>  

CodeEmitter emitter;
std::vector<std::string> label_stack;
std::vector<std::string> procedure_context_stack;

static int count_temp = 0;
static int count_label = 0;

std::string new_temp() {
    std::string nome_temp = "_t" + std::to_string(count_temp);
    count_temp++; 
    return nome_temp;
}

std::string new_label() {
    std::string nome_label = "_L" + std::to_string(count_label);
    count_label++; 
    return nome_label;
}


void CodeEmitter::emit(const Instruction& instr) {
    this->instructions.push_back(instr);
}

void CodeEmitter::emit(OpCode op, std::string result, std::string arg1, std::string arg2) {
    this->instructions.push_back(Instruction(op, std::move(result), std::move(arg1), std::move(arg2)));
}

void CodeEmitter::write_to_file(const std::string& filename) {
    std::ofstream outfile(filename);
    if (!outfile.is_open()) {
        std::cerr << "Erro: Não foi possível abrir o arquivo de saída: " << filename << std::endl;
        return;
    }

   
    std::set<std::string> variables;
    for (const auto& instr : this->instructions) {
        //percorrer todas as instruções e coletar variáveis
    }

    // Escrever no arquivo
}