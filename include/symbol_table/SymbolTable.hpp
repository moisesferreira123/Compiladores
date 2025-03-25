#ifndef SYMBOL_TABLE_HPP_
#define SYMBOL_TABLE_HPP_

#include "Node.hpp"
#include <stdexcept>
#include <string>

class SymbolTable {
private:
  Node *active = nullptr;

  void returnToParent() {
    auto old_active = active;
    active = active->getParent();
    delete old_active;
  }

public:
  SymbolTable(Node *root = nullptr) {
    if (root == nullptr) {
      root = new Node();
    }

    this->active = root;
  }

  ~SymbolTable() {
    while (active != nullptr) {
      returnToParent();
    }
  }

  Symbol *insert(std::string const &name, Symbol symbol) {
    return active->insert(name, symbol);
  }
  Symbol *lookup(std::string const &name) { return active->lookup(name); }
  void remove(std::string const &name) { active->remove(name); }

  Node *newActive() {
    active = new Node(active);

    return active;
  }
  Node *activeRewind() {
    if (active->getParent() == nullptr) {
      throw std::runtime_error("At root");
    }

    returnToParent();
    return active;
  }
};

#endif // !SYMBOL_TABLE_HPP_