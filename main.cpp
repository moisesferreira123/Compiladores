#include "include/parser/Parser.hpp"
#include "include/predictive_parser/include/Grammar.hpp"
#include "include/predictive_parser/include/FirstFollowCalculator.hpp"

int main() {
   // advance(); // Carrega o primeiro token
   // Program(); // Inicia a análise sintática
   Grammar grammar;
   grammar.loadFromFile(filePath); // Carrega a gramática do arquivo
   // grammar.printGrammar(); // Imprime a gramática carregada

   FirstFollowCalculator firstFollow(grammar); // Calcula os conjuntos FIRST e FOLLOW
   firstFollow.computeFirst(); // Calcula o conjunto FIRST
   firstFollow.computeFollow(); // Calcula o conjunto FOLLOW
   // firstFollow.printFirst(); // Imprime o conjunto FIRST
   firstFollow.printFollow(); // Imprime o conjunto FOLLOW
   std::cout << "Programa válido!\n";
   return 0;
}
