#ifndef SYMBOL_TABLE_HPP
#define SYMBOL_TABLE_HPP

#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>

// Estrutura que armazena informações sobre um símbolo
class Symbol {
   private:
   std::string name;

   public:
   Symbol(std::string name) : name(name) { }
   std::string getName() const { return name; }
};

class Variable : public Symbol {
   private:
   std::string kind;

   public:
   Variable(std::string name, std::string kind)
       : Symbol(name), kind(kind) { }

   std::string getKind() const { return kind; }
   void setKind(std::string kind) { this->kind = kind; }
};

class Program : public Symbol {
   public:
   Program(std::string name) : Symbol(name) { }
};

class Procedure : public Symbol {
   private:
   std::string type;
   std::vector<std::string> params;

   public:
   Procedure(std::string name) : Symbol(name) { }

   std::string getType() const { return type; }
   std::vector<std::string> getParams() const { return params; }

   void setType(std::string type) { this->type = type; }
   void setParams(std::vector<std::string> params) { this->params = params; }

   void addParam(std::string param) { params.push_back(param); }
};

class Struct : public Symbol {
   private:
   std::unordered_map<std::string, std::string> fields;

   public:
   Struct(std::string name) : Symbol(name) { }

   std::unordered_map<std::string, std::string> getFields() const {
      return fields;
   }
   void setFields(std::unordered_map<std::string, std::string> fields) {
      this->fields = fields;
   }
   void addField(std::string name, std::string type) { fields[name] = type; }
};

class Enum : public Symbol {
   private:
   std::vector<std::string> values;

   public:
   Enum(std::string name, std::vector<std::string> values)
       : Symbol(name), values(values) { }

   std::vector<std::string> getValues() const { return values; }
   void setValues(std::vector<std::string> values) { this->values = values; }

   void addValue(std::string value) { values.push_back(value); }
};

// Nó da Árvore de escopos
class Node {
   private:
   std::unordered_map<std::string, Symbol> table;
   Node* father;

   public:
   Node(Node* father) : father(father) { }
   void insert(Symbol const& symbol) {
      table.insert({ symbol.getName(), symbol });
   }
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
};

// Tabela de símbolos
class SymbolTable {
   private:
   Node* current;

   public:
   SymbolTable() : current(new Node(nullptr)) { }

   void insert(Symbol const& symbol) { current->insert(symbol); }

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

#endif /// SYMBOL_TABLE_HPP