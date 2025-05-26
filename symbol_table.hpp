#ifndef SYMBOL_TABLE_HPP
#define SYMBOL_TABLE_HPP

#include <iostream>
#include <string>
#include <unordered_map>

// Representa os tipos possíveis de tokens/símbolos
enum class SymbolType { VARIABLE, FUNCTION, CONSTANT, KEYWORD, OPERATOR, TYPE };

// Estrutura que armazena informações sobre um símbolo
struct Symbol {
   std::string name;
   SymbolType type;
   std::string dataType; // Exemplo: int, float, etc.
   int scopeLevel; // Nível de escopo
   int memoryAddress; // Endereço ou offset

   void print() const {
      std::cout << "Name: " << name << ", Type: " << static_cast<int>(type)
                << ", DataType: " << dataType << ", Scope: " << scopeLevel
                << ", Address: " << memoryAddress << std::endl;
   }
};

// Tabela de símbolos
class SymbolTable {
   private:
   std::unordered_map<std::string, Symbol> table;

   public:
   void insert(const Symbol& symbol) { table[symbol.name] = symbol; }

   Symbol* lookup(const std::string& name) {
      auto it = table.find(name);
      if (it != table.end()) {
         return &(it->second);
      }
      return nullptr;
   }

   void remove(const std::string& name) { table.erase(name); }

   void printAll() const {
      for (const auto& pair : table) {
         pair.second.print();
      }
   }
};

#endif
