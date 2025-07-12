#include "logger.hpp"
#include "tac/codegen.hpp"
#include "utils.hpp"
#include <cstdlib>
#include <filesystem>
#include <iostream>

extern int yyparse();
extern bool program_ok;
extern CodeEmitter emitter;

int main() {
   int result = yyparse() == 0 && program_ok;

   if (result) {
      std::filesystem::create_directories("output/build");
      emitter.write_to_file("tac.c");

      int compile_result = system("gcc ./output/tac.c -Ilibs -o ./output/build/tac > ./output/gcc_log.txt 2>&1");

      if (compile_result != 0) {
         Logger::error("Erro ao compilar o código de máquina.");
         return 1;
      }
   }

   return result;
}