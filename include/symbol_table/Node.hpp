#ifndef NODE_HPP_

#include "Symbol.hpp"
#include <string>
#include <unordered_map>

class Node {
   private:
   std::unordered_map<std::string, Symbol> symbols;
   Node* parent;

   public:
   Node(Node* parent = nullptr) : parent(parent) { }

   Symbol* insert(std::string const& name, Symbol symbol) {
      if (symbols.find(name) == symbols.end()) {
         symbols[name] = symbol;
      }

      return &symbols[name];
   }

   Symbol* lookup(std::string const& name) {
      if (symbols.find(name) != symbols.end()) {
         return &symbols[name];
      } else if (parent != nullptr) {
         return parent->lookup(name);
      }

      return nullptr;
   }

   void remove(std::string const& name) { symbols.erase(name); }

   Node* getParent() { return parent; }
   std::unordered_map<std::string, Symbol> getSymbols() { return symbols; }
};

#endif // !NODE_HPP_