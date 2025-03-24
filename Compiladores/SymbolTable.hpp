#ifndef SYMBOL_TABLE_HPP_
#define SYMBOL_TABLE_HPP_

#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

struct Symbol {
  std::string type;
  std::uintptr_t address;

  Symbol() {}
  Symbol(std::string const &type, std::uintptr_t address)
      : type(type), address(address) {}
};

class Node {
private:
  std::unordered_map<std::string, Symbol> symbols;
  std::unordered_map<std::string, Node *> children;
  Node *parent;

public:
  Node(Node *parent = nullptr) : parent(parent) {}
  ~Node() {
    for (auto child : children) {
      delete child.second;
    }
  }

  Symbol *insert(std::string const &name, Symbol symbol) {
    if (symbols.find(name) == symbols.end()) {
      symbols[name] = symbol;
    }

    return &symbols[name];
  }

  Symbol *lookup(std::string const &name) {
    if (symbols.find(name) != symbols.end()) {
      return &symbols[name];
    } else if (parent != nullptr) {
      return parent->lookup(name);
    }

    return nullptr;
  }

  void remove(std::string const &name) { symbols.erase(name); }

  Node *allocate(std::string const &name) {
    if (children.find(name) == children.end()) {
      children[name] = new Node(this);
    }

    return children[name];
  }

  void free(std::string const &name) {
    if (children.find(name) != children.end()) {
      Node *node = children[name];
      children.erase(name);

      delete node;
    }
  }

  Node *getParent() { return parent; }
  std::unordered_map<std::string, Node *> getChildren() { return children; }
  std::unordered_map<std::string, Symbol> getSymbols() { return symbols; }
};

class SymbolTable {
private:
  Node *active = nullptr;

public:
  SymbolTable(Node *root = nullptr) {
    if (root == nullptr) {
      root = new Node();
    }

    this->active = root;
  }

  ~SymbolTable() {
    Node *root = active;

    while (root->getParent() != nullptr) {
      root = root->getParent();
    }

    delete root;
  }
  Symbol *insert(std::string const &name, Symbol symbol) {
    return active->insert(name, symbol);
  }

  Symbol *lookup(std::string const &name) { return active->lookup(name); }
  void remove(std::string const &name) { active->remove(name); }

  Node *allocate(std::string const &name) { return active->allocate(name); }
  void free(std::string const &name) { active->free(name); }

  Node *setActive(std::string const &name) {
    active = allocate(name);

    return active;
  }
  Node *setActiveParent() {
    if (active->getParent() == nullptr) {
      return nullptr;
    }

    active = active->getParent();
    return active;
  }
};

#endif // !SYMBOL_TABLE_HPP_