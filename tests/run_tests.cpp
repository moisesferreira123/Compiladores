// run_tests.cpp
#include "logger.hpp" // sua classe Logger
#include "utils.hpp" // extern bool program_ok;
#include <fstream>
#include <getopt.h> // para getopt_long
#include <iostream>
#include <string>
#include <vector>

// protótipo gerado pelo Bison/Flex
int yyparse();
extern FILE* yyin;
extern SymbolTable symbolTable;

struct TestCase {
   std::string path;
   bool shouldPass; // true se for teste “válido”, false para teste de erro
};

static const std::vector<TestCase> ALL_TESTS = {
   {        "tests/files/swap.c25", true },
   {      "tests/files/person.c25", true },
   { "tests/files/day_of_week.c25", true },
   // adicione outros testes aqui
};

void printHelp(const char* progName) {
   std::cout << "Uso: " << progName << " [OPÇÕES]\n"
             << "Opções:\n"
             << "  --file=<arquivo>    Testa apenas este arquivo\n"
             << "  --all               Testa todos os arquivos predefinidos\n"
             << "  --success           Só testa casos que devem passar\n"
             << "  --error             Só testa casos que devem falhar\n"
             << "  --help              Mostra este texto\n";
}

int main(int argc, char* argv[]) {
   bool flagAll = false;
   bool flagHelp = false;
   bool flagSuccess = false;
   bool flagError = false;
   std::string fileToTest;

   static struct option longOpts[] = {
      {    "file", required_argument, nullptr, 'f' },
      {     "all",       no_argument, nullptr, 'a' },
      { "success",       no_argument, nullptr, 's' },
      {   "error",       no_argument, nullptr, 'e' },
      {    "help",       no_argument, nullptr, 'h' },
      {   nullptr,                 0, nullptr,   0 }
   };

   int opt;
   while ((opt = getopt_long(argc, argv, "f:aseh", longOpts, nullptr)) != -1) {
      switch (opt) {
         case 'f':
            fileToTest = optarg;
            break;
         case 'a':
            flagAll = true;
            break;
         case 's':
            flagSuccess = true;
            break;
         case 'e':
            flagError = true;
            break;
         case 'h':
            flagHelp = true;
            break;
         default:
            flagHelp = true;
            break;
      }
   }

   // Se pediu ajuda
   if (flagHelp) {
      printHelp(argv[0]);
      return 0;
   }

   // Se não passou nenhuma opção relevante, imprime help
   if (!flagAll && !flagSuccess && !flagError && fileToTest.empty()) {
      printHelp(argv[0]);
      return 0;
   }

   // Interpretar --success ou --error isolados como --all
   if ((flagSuccess || flagError) && !flagAll && fileToTest.empty()) {
      flagAll = true;
   }

   // abre log para parser (mantém cores ANSI)
   std::ofstream parserLog("log.txt", std::ios::out | std::ios::trunc);
   if (!parserLog) {
      Logger::error("Falha ao criar log.txt");
      return 1;
   }

   // monta lista de testes
   std::vector<TestCase> tests;
   if (!fileToTest.empty()) {
      // se especificou file, assume teste de sucesso (ou modifique conforme
      // necessidade)
      tests.push_back({ fileToTest, true });
   } else if (flagAll) {
      for (auto& t : ALL_TESTS) {
         if (flagSuccess && !t.shouldPass)
            continue;
         if (flagError && t.shouldPass)
            continue;
         tests.push_back(t);
      }
   }

   int total = 0;
   int passedCount = 0;
   int failedCount = 0;

   for (auto& tc : tests) {
      symbolTable.reset();
      ++total;
      Logger::info("Rodando teste: " + tc.path);
      // abre arquivo de entrada para lexer
      yyin = fopen(tc.path.c_str(), "r");
      if (!yyin) {
         Logger::error("Não foi possível abrir " + tc.path);
         ++failedCount;
         continue;
      }

      // redireciona cout/cerr somente para parser
      auto coutBuf = std::cout.rdbuf();
      auto cerrBuf = std::cerr.rdbuf();
      std::cout.rdbuf(parserLog.rdbuf());
      std::cerr.rdbuf(parserLog.rdbuf());

      program_ok = false;
      int result = yyparse();

      // restaura saída padrão
      std::cout.rdbuf(coutBuf);
      std::cerr.rdbuf(cerrBuf);
      fclose(yyin);

      bool ok = (program_ok == tc.shouldPass);
      if (ok) {
         ++passedCount;
         Logger::success("Teste " + tc.path + " => "
           + (program_ok ? "PASSOU" : "FALHA ESPERADA"));
      } else {
         ++failedCount;
         Logger::error("Teste " + tc.path + " => "
           + (program_ok ? "PASSOU (não esperado)" : "FALHOU"));
      }
   }

   // resumo final
   std::cout << std::endl;
   Logger::info("========== Resumo ==========");
   Logger::success("  Sucesso: " + std::to_string(passedCount));
   Logger::error("  Falha:   " + std::to_string(failedCount));
   Logger::info("  Total:   " + std::to_string(total));

   return (failedCount == 0 ? 0 : 1);
}
