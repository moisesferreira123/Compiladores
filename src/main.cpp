#include <iostream>
#include "utils.hpp"

extern int yyparse();
extern bool program_ok;

int main() {
   return yyparse() && program_ok;
}
