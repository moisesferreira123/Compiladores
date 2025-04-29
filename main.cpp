#include "include/parser/Parser.hpp"
#include "include/predictive_parser/module/Grammar.hpp"
#include "include/predictive_parser/module/FirstFollowCalculator.hpp"
#include "include/predictive_parser/module/LL1Table.hpp"


int main() {
   // advance(); // Carrega o primeiro token
   // Program(); // Inicia a análise sintática

   LL1Table ll1Table; // Cria a tabela LL(1)
   
   ll1Table.exportTableToCSV(); // Constrói a tabela LL(1)
   ll1Table.exportParsingTableToCSV(); // Exporta a tabela de parsing para CSV
   ll1Table.exportFirstAndFollowToCSV(); // Exporta os conjuntos FIRST e FOLLOW para CSV

   std::cout << "Programa válido!\n";
   return 0;
}
