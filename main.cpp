#include "include/parser/Parser.hpp"

int main() {
   advance(); // Carrega o primeiro token
   Program(); // Inicia a análise sintática
   std::cout << "Programa válido!\n";
   return 0;
}
