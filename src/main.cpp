#include <iostream>
#include "utils.hpp"
#include "tac/codegen.hpp"  

extern int yyparse();
extern bool program_ok;
extern CodeEmitter emitter; 

int main() {
   return yyparse() == 0 && program_ok;
}