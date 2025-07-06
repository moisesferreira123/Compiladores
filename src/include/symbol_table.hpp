#ifndef SYMBOL_TABLE_HPP
#define SYMBOL_TABLE_HPP

#include <iostream>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

class Symbol {
   private:
   std::string name;

   public:
   Symbol(std::string name) : name(name) { }
   std::string getName() const { return name; }
   virtual ~Symbol() { }
};

class VariableType {
   public:
   virtual ~VariableType() { }
};

class PrimitiveType : public VariableType {
   private:
   std::string type;

   public:
   PrimitiveType(std::string type) : type(type) { }
   std::string getType() const { return type; }
};

class StructuredType : public VariableType {
   private:
   std::shared_ptr<Symbol> type;

   public:
   StructuredType(std::shared_ptr<Symbol> type) : type(type) { }
   std::shared_ptr<Symbol> getType() const { return type; }
};

class ReferenceType : public VariableType {
   private:
   VariableType* type;

   public:
   ReferenceType(VariableType* type) : type(type) { }
   VariableType* getType() const { return type; }
};

class Program : public Symbol {
   public:
   Program(std::string name) : Symbol(name) { }
};

class Variable : public Symbol {
   private:
   VariableType* type;

   public:
   Variable(std::string name, VariableType* type) : Symbol(name), type(type) { }

   VariableType* getType() const { return type; }
   void setType(VariableType* const& type) { this->type = type; }
};

class Procedure : public Symbol {
   private:
   VariableType* type;
   std::vector<std::shared_ptr<Variable>> params;

   public:
   Procedure(std::string name) : Symbol(name) { }
   Procedure(std::string name, VariableType* type,
     std::vector<std::shared_ptr<Variable>> params)
       : Symbol(name), type(type), params(params) { }

   VariableType* getType() const { return type; }
   std::vector<std::shared_ptr<Variable>> getParams() const { return params; }

   void setType(VariableType* type) { this->type = type; }
   void setParams(std::vector<std::shared_ptr<Variable>> const& params) {
      this->params = params;
   }
};

class Struct : public Symbol {
   private:
   std::vector<std::shared_ptr<Variable>> fields;

   public:
   Struct(std::string name) : Symbol(name) { }
   Struct(std::string name, std::vector<std::shared_ptr<Variable>> fields)
       : Symbol(name), fields(fields) { }

   std::vector<std::shared_ptr<Variable>> getFields() const { return fields; }
   void setFields(std::vector<std::shared_ptr<Variable>> const& fields) {
      this->fields = fields;
   }
};

class Enum : public Symbol {
   private:
   std::vector<std::string> values;

   public:
   Enum(std::string name, std::vector<std::string> values = {})
       : Symbol(name), values(values) { }

   void setValues(std::vector<std::string> const& values) {
      this->values = values;
   }
   std::vector<std::string> getValues() const { return values; }
};

// Nó da Árvore de escopos
class Node {
   private:
   std::unordered_map<std::string, std::shared_ptr<Symbol>> table;
   Node* parent;

   public:
   Node(Node* parent) : parent(parent) { }
   ~Node() { }

   void insert(std::shared_ptr<Symbol> symbol) {
      table.insert({ symbol->getName(), symbol });
   }

   std::shared_ptr<Symbol> single_lookup(std::string const& name) {
      auto it = table.find(name);
      if (it != table.end()) {
         return it->second;
      }
      return nullptr;
   }

   std::shared_ptr<Symbol> lookup(std::string const& name) {
      std::shared_ptr<Symbol> symbol = single_lookup(name);
      if (symbol != nullptr) {
         return symbol;
      } else if (parent != nullptr) {
         return parent->lookup(name);
      }

      return nullptr;
   }

   Node* getParent() { return parent; }
};

class SymbolTable {
   private:
   Node* current;
   int scopes;

   public:
   SymbolTable() : current(new Node(nullptr)), scopes(1) { }

   ~SymbolTable() {
      while (current != nullptr) {
         Node* temp = current->getParent();
         delete current;
         current = temp;
      }
   }

   void insert(std::shared_ptr<Symbol> symbol) {
      if (current == nullptr) {
         return;
      }

      current->insert(symbol);
   }

   void enterScope() {
      current = new Node(current);
      scopes++;
   }

   void exitScope() {
      if (current == nullptr) {
         return;
      }

      Node* tmp = current->getParent();
      delete current;
      current = tmp;
   }

   std::shared_ptr<Symbol> single_lookup(std::string const& name) {
      if (current == nullptr) {
         return nullptr;
      }

      return current->single_lookup(name);
   }

   std::shared_ptr<Symbol> lookup(std::string const& name) {
      if (current == nullptr) {
         return nullptr;
      }

      return current->lookup(name);
   }

   void reset() {
      while (current != nullptr) {
         Node* temp = current->getParent();
         delete current;
         current = temp;
      }
      current = new Node(nullptr);
      scopes = 1;
   }
};

#endif /// SYMBOL_TABLE_HPP