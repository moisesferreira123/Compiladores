#include <iostream>
#include "utils.hpp"
#include "tac/codegen.hpp"  


extern int yyparse();
extern bool program_ok;
extern CodeEmitter emitter; 


int main() {
   if (yyparse() == 0 && program_ok) {
      emitter.write_to_file("tac.c");
      std::cout << "Código C gerado com sucesso em 'tac.c'.\n";
   } else {
      std::cerr << "Erro durante análise. Código não gerado.\n";
   }

   return 0;
}