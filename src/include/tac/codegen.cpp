// Em um novo arquivo "codegen.cpp"

#include "codegen.hpp"
#include <filesystem>
#include <fstream>
#include <iostream>
#include <set>

CodeEmitter emitter;
std::vector<std::string> label_stack;
std::vector<std::string> procedure_context_stack;
// std::vector<std::vector<TAC_Instruction>> procedures_stack;
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
   if (procedure_name != "main") {
      std::string procedure_label_begin
        = procedure_name + "_" + std::to_string(symbolTable.getScopes());
      std::string procedure_label_end = new_label();
      emit(OpCode::TAC_GOTO, procedure_label_end);
      emit(OpCode::TAC_LABEL, procedure_label_begin);
      label_stack.push_back(procedure_label_end);
   }
}

void CodeEmitter::emitProcedureParams(
  std::vector<Paramfield*>* procedure_params) {
   for (auto param : *procedure_params) {
      std::string tacType = getTacType(param->type);
      std::string global_param
        = param->name + "_" + std::to_string(symbolTable.getScopes());
      emit(TAC_Instruction(tacType, OpCode::TAC_PARAM, global_param));
   }
}

void CodeEmitter::emitProcedureEnd() {
   std::string end_label = "_L_end" + std::to_string(symbolTable.getScopes());
   emit(OpCode::TAC_LABEL, end_label);
   std::string temp_comp = new_temp();
   emit(OpCode::TAC_SUB, "_size", "_size", "1");
   emit(TAC_Instruction("bool", OpCode::TAC_GE, temp_comp, "_size", "0"));
   emit(OpCode::TAC_IF_GOTO, "*_label_stack[_size]", temp_comp);
   if (!label_stack.empty()) {
      emit(OpCode::TAC_LABEL, label_stack.back());
      label_stack.pop_back();
   }
}

void CodeEmitter::emitProcedureReturn() {
   std::string end_label = "_L_end" + std::to_string(symbolTable.getScopes());
   emit(OpCode::TAC_GOTO, end_label);
}

bool CodeEmitter::emitDefaultCallStmt(const std::string& procedure_name,
  std::vector<TacOperand*>* call_args, std::string temp) {
   auto procedure_symbol = symbolTable.lookup(procedure_name);

   if (procedure_symbol == nullptr) {
      return false;
   }

   std::string procedure_label = procedure_symbol->getName() + "_"
     + std::to_string(procedure_symbol->getScopeId());

   std::string readFunctions[] = {
      "readint_1", "readfloat_1", "readchar_1", "readstring_1", "readline_1"
   };

   for (int i = 0; i < 5; i++) {
      if (procedure_label == readFunctions[i]) {
         if (auto procedure
           = std::dynamic_pointer_cast<Procedure>(procedure_symbol)) {
            Type* t = createType(procedure->getType());
            std::string tacType = getTacType(t);
            emit(TAC_Instruction(
              tacType, OpCode::TAC_DEFAULT_CALL_ASSIGN, temp, procedure_label));
            delete t;
            return true;
         }

         break;
      }
   }
   std::string printFunctions[]
     = { "printint_1", "printfloat_1", "printstr_1", "printline_1" };

   for (int i = 0; i < 4; i++) {
      if (procedure_label == printFunctions[i]) {
         if (auto procedure
           = std::dynamic_pointer_cast<Procedure>(procedure_symbol)) {
            emit(OpCode::TAC_DEFAULT_CALL, procedure_label);

            for (int i { 0 }; i < call_args->size(); i++) {
               if (i == 0) {
                  emit(OpCode::TAC_DEFAULT_FPARAM, call_args->at(i)->loc);
               } else {
                  emit(OpCode::TAC_DEFAULT_PARAM, call_args->at(i)->loc);
               }
            }

            emit(OpCode::TAC_DEFAULT_CALL_END, "");

            return true;
         }

         break;
      }
   }

   return false;
}

void CodeEmitter::emitCallStmt(const std::string& procedure_name,
  std::vector<TacOperand*>* call_args, std::string temp) {
   if (emitDefaultCallStmt(procedure_name, call_args, temp)) {
      return;
   }

   auto procedure_symbol = symbolTable.lookup(procedure_name);

   if (procedure_symbol == nullptr) {
      return;
   }

   std::shared_ptr<Procedure> procedure;
   if (procedure = std::dynamic_pointer_cast<Procedure>(procedure_symbol)) {
      auto params = procedure->getParams();

      for (int i { 0 }; i < call_args->size(); i++) {
         std::string param_name = params.at(i)->getName() + "_"
           + std::to_string(params.at(i)->getScopeId());
         std::string arg_name = call_args->at(i)->loc;
         emit(OpCode::TAC_ASSIGN, param_name, arg_name);
      }
   }

   std::string procedure_label
     = procedure_name + "_" + std::to_string(procedure_symbol->getScopeId());
   std::string return_label = new_label();
   emit(OpCode::TAC_INSERT_LABEL_STACK, return_label);
   emit(OpCode::TAC_ADD, "_size", "_size", "1");
   emit(OpCode::TAC_GOTO, procedure_label);
   emit(OpCode::TAC_LABEL, return_label);

   /// BUG: getScopeId() pega o escopo onde o procedimento está, mas não o do
   /// return.
   std::string return_str
     = "_return_" + std::to_string(procedure_symbol->getScopeId());

   Type* type = createType(procedure->getType());
   if (!isVoidKind(type->kind)) {
      std::string tacType = getTacType(type);
      emit(TAC_Instruction(tacType, OpCode::TAC_ASSIGN, return_str, temp));
   }
   delete type;
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

   outfile << "#include <stdbool.h>\n";
   outfile << "#include \"iosystem.h\"\n";
   outfile << "\nint main() {\n";
   outfile << "void* _label_stack[2048];\n";
   outfile << "int _size = 0;\n";

   for (const auto& instr : this->instructions) {
      switch (instr.op) {
         case OpCode::TAC_ATR:
            outfile << indentation << instr.result << " = " << instr.arg1
                    << ";\n";
            break;
         case OpCode::TAC_ADD:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << " + " << instr.arg2 << ";\n";
            break;
         case OpCode::TAC_SUB:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << " - " << instr.arg2 << ";\n";
            break;
         case OpCode::TAC_MULT:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << " * " << instr.arg2 << ";\n";
            break;
         case OpCode::TAC_DIV:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << " / " << instr.arg2 << ";\n";
            break;
         case OpCode::TAC_POT: {
            // TODO: Tem que lidar com o tipo do temp_arg1
            std::string pot_loop = new_label();
            std::string temp_comp = new_temp();
            std::string temp_arg1 = new_temp();
            outfile << indentation << "int " << temp_comp << " = 1;\n";
            outfile << indentation << "float " << temp_arg1 << " = "
                    << instr.arg1 << ";\n";
            outfile << pot_loop << ":\n";
            outfile << indentation << temp_comp << " = " << temp_comp
                    << " + 1;\n";
            outfile << indentation << instr.arg1 << " = " << instr.arg1 << " * "
                    << temp_comp << ";\n";
            outfile << indentation << "if(" << temp_comp << " < " << instr.arg2
                    << ") goto " << pot_loop << ";\n";
            break;
         }
         case OpCode::TAC_UNARY_MINUS:
            outfile << indentation << instr.type << " " << instr.result
                    << " = -" << instr.arg1 << ";\n";
            break;
         case OpCode::TAC_EQ:
            // TODO: Acho que tem que analisar se é um tipo enum para ver como
            // comparar
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << " == " << instr.arg2 << ";\n";
            break;
         case OpCode::TAC_NEQ:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << " != " << instr.arg2 << ";\n";
            break;
         case OpCode::TAC_LT:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << " < " << instr.arg2 << ";\n";
            break;
         case OpCode::TAC_GT:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << " > " << instr.arg2 << ";\n";
            break;
         case OpCode::TAC_LE:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << " <= " << instr.arg2 << ";\n";
            break;
         case OpCode::TAC_GE:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << " >= " << instr.arg2 << ";\n";
            break;
         case OpCode::TAC_OR:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << " || " << instr.arg2 << ";\n";
            break;
         case OpCode::TAC_AND:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << " && " << instr.arg2 << ";\n";
            break;
         case OpCode::TAC_NOT:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << "!" << instr.arg1 << ";\n";
            break;
         case OpCode::TAC_GOTO:
            outfile << indentation << "goto " << instr.result << ";\n";
            break;
         case OpCode::TAC_IF_GOTO:
            outfile << indentation << "if(" << instr.arg1 << ") goto "
                    << instr.result << ";\n";
            break;
         case OpCode::TAC_IF_FALSE_GOTO:
            outfile << indentation << "if(!" << instr.arg1 << ") goto "
                    << instr.result << ";\n";
            break;
         case OpCode::TAC_LABEL:
            outfile << instr.result << ":\n";
            break;
         case OpCode::TAC_ASSIGN:
            outfile << indentation << instr.result << " = " << instr.arg1
                    << ";\n";
            break;
         case OpCode::TAC_PARAM:
            outfile << indentation << instr.type << " " << instr.result
                    << ";\n";
            break;
         case OpCode::TAC_INSERT_LABEL_STACK:
            outfile << indentation << "_label_stack[_size] = &&" << instr.result
                    << ";\n";
            break;
         case OpCode::TAC_RETURN:
            // TODO: Errado. Não pode ter return algo; no nosso código.
            outfile << indentation << "return " << instr.result << ";\n";
            break;
         case OpCode::TAC_REF:
            outfile << indentation << instr.type << " " << instr.result
                    << " = &" << instr.arg1 << ";\n";
            break;
         case OpCode::TAC_DEREF:
            outfile << indentation << instr.type << " " << instr.result
                    << " = *" << instr.arg1 << ";\n";
            break;
         case OpCode::TAC_DEREF_ASSIGN:
            outfile << indentation << instr.result << " = " << instr.arg1
                    << ";\n";
            break;
         case OpCode::TAC_MEMBER_READ:
            break;
         case OpCode::TAC_MEMBER_ASSIGN:
            break;
         case OpCode::TAC_MEMBER_ACCESS:
            break;
         case OpCode::TAC_NEW:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << "{0};\n";
            break;
         case OpCode::TAC_VAR_DECL:
            outfile << indentation << instr.type << " " << instr.result
                    << ";\n";
            break;
         case OpCode::TAC_STRUCT_DECL:
            outfile << indentation << "typedef struct {\n";
            break;
         case OpCode::TAC_STRUCT_DECL_CLOSE:
            outfile << indentation << "} " << instr.result << ";\n";
            break;
         case OpCode::TAC_DEFAULT_CALL:
            outfile << indentation << instr.result << "(";
            break;
         case OpCode::TAC_DEFAULT_FPARAM:
            outfile << "" << instr.result;
            break;
         case OpCode::TAC_DEFAULT_PARAM:
            outfile << ", " << instr.result;
            break;
         case OpCode::TAC_DEFAULT_CALL_END:
            outfile << ");\n";
            break;
         case OpCode::TAC_RETURN_VOID:
            emitProcedureReturn();
            break;
         case OpCode::TAC_RETURN_VALUE:
            outfile << indentation << "_return_" << instr.arg1 << " = "
                    << instr.result << ";\n";
            emitProcedureReturn();
            break;
         case OpCode::TAC_PROCEDURE_RETURN:
            outfile << indentation << instr.result << " _return_" << instr.arg1
                    << ";\n";
            emitProcedureReturn();
            break;
         case OpCode::TAC_DEFAULT_CALL_ASSIGN:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << "();\n";
            break;
         case OpCode::TAC_CALL_ASSIGN:
            outfile << indentation << instr.type << " " << instr.result << " = "
                    << instr.arg1 << ";\n";
            break;
      }
   }

   outfile << indentation << "return 0;\n";
   outfile << "}\n";

   outfile.close(); // Fecha explicitamente para garantir gravação

   // Escrever no arquivo
}