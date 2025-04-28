#include "include/parser/Parser.hpp"
#include "include/predictive_parser/module/Grammar.hpp"
#include "include/predictive_parser/module/FirstFollowCalculator.hpp"
#include "include/predictive_parser/module/LL1Table.hpp"

int main() {
   // advance(); // Carrega o primeiro token
   // Program(); // Inicia a análise sintática
   Grammar grammar;
   grammar.loadFromFile(); // Carrega a gramática do arquivo
   grammar.printGrammar(); // Imprime a gramática carregada

   FirstFollowCalculator firstFollow(grammar); // Calcula os conjuntos FIRST e FOLLOW
   // firstFollow.computeFirst(); // Calcula o conjunto FIRST
   // firstFollow.computeFollow(); // Calcula o conjunto FOLLOW

   firstFollow.printFirst(); // Imprime o conjunto FIRST
   firstFollow.printFollow(); // Imprime o conjunto FOLLOW

   firstFollow.exportFirstToCSV(); // Exporta o conjunto FIRST para CSV
   firstFollow.exportFollowToCSV(); // Exporta o conjunto FOLLOW para CSV

   LL1Table ll1Table(grammar, firstFollow); // Cria a tabela LL(1)
   ll1Table.exportTableToCSV(); // Constrói a tabela LL(1)

   std::cout << "Programa válido!\n";
   return 0;
}
