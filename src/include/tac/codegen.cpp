// Em um novo arquivo "codegen.cpp"

#include "codegen.hpp"
#include "utils.hpp"
#include <filesystem>
#include <fstream>   
#include <iostream> 
#include <set>       

CodeEmitter emitter;
std::vector<std::string> label_stack;
// std::vector<std::string> procedure_context_stack;
std::vector<std::vector<TAC_Instruction>> procedures_stack;
std::set<std::string> variables;

static int count_temp = 0;
static int count_label = 0;
static int count_procedure = 0;

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


void CodeEmitter::emit(const TAC_Instruction& instr) {
   this->instructions.push_back(instr);
}

void CodeEmitter::emit(
  OpCode op, std::string result, std::string arg1, std::string arg2) {
   this->instructions.push_back(
     TAC_Instruction(op, std::move(result), std::move(arg1), std::move(arg2)));
}

void CodeEmitter::emitProcedureBegin(const std::string& procedure_name) {
    std::string procedure_label;
    if(procedure_name == "main") procedure_label = "main";
    else procedure_label = new_label();
    std::vector<TAC_Instruction> procedure_instructions;
    procedure_instructions.push_back(TAC_Instruction(OpCode::TAC_LABEL, procedure_label));
    procedures_stack.push_back(procedure_instructions);
}

void CodeEmitter::emitProcedureParams(std::vector<Paramfield*>* procedure_params) {
    
}

void CodeEmitter::emitProcedureEnd() {
    for(auto instr: procedures_stack.back()) {
        emit(instr);
    }
    procedures_stack.pop_back();
    // Colquei essa sitring, pois foi o nome que eu dei para a variável geral que será usada para ir para outro label nas chamadas de procedures
    emit(OpCode::TAC_STACK_POP_LABEL, "change_label");
}

void CodeEmitter::write_to_file(const std::string& filename) {
   std::filesystem::create_directory("output"); /// Criando pasta de saída

   std::ofstream outfile("output/" + filename);
   std::string indentation = "   ";
   if (!outfile.is_open()) {
      std::cerr << "Erro: Não foi possível abrir o arquivo de saída: "
                << filename << std::endl;
      return;
   }

    // TODO: Colocar todas as variáveis com seus tipos.
    // Tem que fazer a tabela de símbolos enviar o tipo da variável
    

    outfile << "\nint main() {\n";
    outfile << "void* change_label;\n";


    for (const auto& instr : this->instructions) {
        switch(instr.op) {
            case OpCode::TAC_ATR:
                outfile << indentation << instr.result << " = " << instr.arg1 << ";\n";
                break;
            case OpCode::TAC_ADD:
                outfile << indentation << instr.result << " = " << instr.arg1 << " + " << instr.arg2 << ";\n";
                break;
            case OpCode::TAC_SUB:
                outfile << indentation << instr.result << " = " << instr.arg1 << " - " << instr.arg2 << ";\n";
                break;
            case OpCode::TAC_MULT:
                outfile << indentation << instr.result << " = " << instr.arg1 << " * " << instr.arg2 << ";\n";
                break;
            case OpCode::TAC_DIV:
                outfile << indentation << instr.result << " = " << instr.arg1 << " / " << instr.arg2 << ";\n";
                break;
            case OpCode::TAC_POT: {
                // TODO: Tem que lidar com o tipo do temp_arg1
                std::string pot_loop = new_label();
                std::string temp_comp = new_temp();
                std::string temp_arg1 = new_temp();
                outfile << indentation << "int " << temp_comp << " = 1;\n";
                outfile << indentation << "float " << temp_arg1 << " = " << instr.arg1 << ";\n";
                outfile << pot_loop << ":\n";
                outfile << indentation << temp_comp << " = " << temp_comp << " + 1;\n";
                outfile << indentation << instr.arg1 << " = " << instr.arg1 <<  " * " << temp_comp << ";\n";
                outfile << indentation << "if(" << temp_comp << " < " << instr.arg2 << ") goto " << pot_loop << ";\n";
                break;
            }
            case OpCode::TAC_UNARY_MINUS:
                outfile << indentation << instr.result << " = -" << instr.arg1 << ";\n";
                break;
            case OpCode::TAC_EQ:
            //TODO: Acho que tem que analisar se é um tipo enum para ver como comparar
                outfile << indentation << instr.result << " = " << instr.arg1 << " == " << instr.arg2 << ";\n";
                break;
            case OpCode::TAC_NEQ:
                outfile << indentation << instr.result << " = " << instr.arg1 << " != " << instr.arg2 << ";\n";
                break;
            case OpCode::TAC_LT:
                outfile << indentation << instr.result << " = " << instr.arg1 << " < " << instr.arg2 << ";\n";
                break;
            case OpCode::TAC_GT:
                outfile << indentation << instr.result << " = " << instr.arg1 << " > " << instr.arg2 << ";\n";
                break;
            case OpCode::TAC_LE:
                outfile << indentation << instr.result << " = " << instr.arg1 << " <= " << instr.arg2 << ";\n";
                break;
            case OpCode::TAC_GE:
                outfile << indentation << instr.result << " = " << instr.arg1 << " >= " << instr.arg2 << ";\n";
                break;
            case OpCode::TAC_OR:
                outfile << indentation << instr.result << " = " << instr.arg1 << " || " << instr.arg2 << ";\n";
                break;
            case OpCode::TAC_AND:
                outfile << indentation << instr.result << " = " << instr.arg1 << " && " << instr.arg2 << ";\n";
                break;
            case OpCode::TAC_NOT:
                outfile << indentation << instr.result << " = " << "!" << instr.arg1 << ";\n";
                break;
            case OpCode::TAC_GOTO:
                outfile << indentation << "goto " << instr.result << ";\n";
                break;
            case OpCode::TAC_IF_GOTO:
                outfile << indentation << "if(" << instr.arg1 << ") goto " << instr.result << ";\n";
                break;
            case OpCode::TAC_IF_FALSE_GOTO:
                outfile << indentation << "if(!" << instr.arg1 << ") goto " << instr.result << ";\n";
                break;
            case OpCode::TAC_LABEL:
                outfile << instr.result << ":\n";
                break;
            case OpCode::TAC_ASSIGN:
                outfile << indentation << instr.result << " = " << instr.arg1 << ";\n";
                break;
            case OpCode::TAC_PARAM:
            // TODO:
            break;
         case OpCode::TAC_CALL:
            // TODO:
                break;
            case OpCode::TAC_RETURN:
            // TODO: Errado. Não pode ter return algo; no nosso código.
                outfile << indentation << "return " << instr.result << ";\n";
                break;
            case OpCode::TAC_REF:
                outfile << indentation << instr.result << " = &" << instr.arg1 << ";\n";
                break;
            case OpCode::TAC_DEREF:
                outfile << indentation << instr.result << " = *" << instr.arg1 << ";\n";
                break;
            case OpCode::TAC_DEREF_ASSIGN:
                outfile << indentation << instr.result << "* = &" << instr.arg1 << ";\n";
                break;
            case OpCode::TAC_MEMBER_READ:
                break;
            case OpCode::TAC_MEMBER_ASSIGN:
                break;
            case OpCode::TAC_MEMBER_ACCESS:
                break;
            case OpCode::TAC_NEW:
                outfile << indentation << instr.type << " " << instr.result << " = "
                        << instr.arg1 << "();\n";
                break;
             case OpCode::TAC_VAR_DECL:
                outfile << indentation << instr.type << " " << instr.result << ";\n";
                break;
        }
    }

   outfile << indentation << "return 0;\n";
   outfile << "}\n";

   outfile.close(); // Fecha explicitamente para garantir gravação

   // Escrever no arquivo
}