#include "include/predictive_parser/module/FirstFollowCalculator.hpp"
#include "include/predictive_parser/module/Grammar.hpp"
#include "include/predictive_parser/module/LL1Table.hpp"
#include "include/predictive_parser/module/PredictiveParser.hpp"
#include <iostream>

int main() {
   LL1Table ll1Table; // Cria a tabela LL(1)

   ll1Table.exportTableToCSV(); // Constrói a tabela LL(1)
   ll1Table.exportParsingTableToCSV(); // Exporta a tabela de parsing para CSV
   ll1Table.exportFirstAndFollowToCSV(); // Exporta os conjuntos FIRST e CSV

   PredictiveParser parser;

   if (parser.isValid()) {
      std::cout << "Programa válido!\n";
   } else {
      std::cout << "Programa invalido!\n";
   }

   return 0;
}
