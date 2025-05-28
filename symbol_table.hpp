#ifndef SYMBOL_TABLE_HPP
#define SYMBOL_TABLE_HPP

#include <iostream>
#include <string>
#include <unordered_map>

// Representa os tipos possíveis de tokens/símbolos
enum class SymbolType { VARIABLE, PROGRAM };

// Estrutura que armazena informações sobre um símbolo
struct Symbol {
   std::string name;
   SymbolType type;

   Symbol(std::string const& name, SymbolType type) : name(name), type(type) { }
};

// Nó da Árvore de escopos
class Node {
   private:
   std::unordered_map<std::string, Symbol> table;
   Node* father;

   public:
   Node(Node* father) : father(father) { }
   void insert(Symbol const& symbol) { table.insert({ symbol.name, symbol }); }
   Symbol* lookup(std::string const& name) {
      auto it = table.find(name);
      if (it != table.end()) {
         return &(it->second);
      }
      if (father != nullptr) {
         return father->lookup(name);
      }
      return nullptr;
   }
   Node* getFather() { return father; }
   void print() const {
      for (const auto& pair : table) {
         std::cout << "Symbol: " << pair.second.name
                   << ", Type: " << static_cast<int>(pair.second.type)
                   << std::endl;
      }
      if (father != nullptr) {
         father->print();
      }
   }
};

// Tabela de símbolos
class SymbolTable {
   private:
   Node* current;

   public:
   SymbolTable() : current(new Node(nullptr)) { }

   void insert(Symbol const& symbol) {
      current->insert(symbol);
      current->print();
      std::cout << "\n";
   }

   void enterScope() { current = new Node(current); }

   void exitScope() {
      Node* tmp = current->getFather();
      delete current;
      current = tmp;
   }

   Symbol* lookup(std::string const& name) {
      if (current == nullptr) {
         return nullptr;
      }
      return current->lookup(name);
   }
};

#endif
