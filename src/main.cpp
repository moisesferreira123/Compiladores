#include "symbol_table/SymbolTable.hpp"
#include <iostream>
#include <ostream>

std::ostream &operator<<(std::ostream &os, Symbol const &symbol) {
  return os << "(" << symbol.type << ", " << symbol.address << ")";
}

/*  IMAGINE O CÓDIGO E VEJA A TABELA DE SÍMBOLOS A SER CONSTRUÍDA
int i;
int j;

int func(int i, int j) {
  if (i ==  0) {
    float k = j;

    if (k ==  0) {
      return 0;
    }
  }

  return 1;
}

void main() {
  int k = func(i, j);
}
*/

int main(int, char **) {
  SymbolTable table;

  /// OBS: A declaração acontece quando se coloca o tipo seguido do nome da
  /// variável: int i

  /// As duas primeiras linhas declaram elementos globais (primeiro escopo)
  table.insert("i", Symbol("int", 0));
  table.insert("j", Symbol("int", 0));

  /// A linha seguinte declara um novo escopo, nesse novo escopo são declaras
  /// duas novas variáveis
  table.insert("func", Symbol("function", 0));
  table.newActive(); /// Entrada no escopo da função func
  table.insert("i", Symbol("int", 0));
  table.insert("j", Symbol("int", 0));

  /// A linha seguinte declara um novo escopo, nesse novo escopo é declarada uma
  /// nova variável Repare que a variável j foi declarada no escopo anterior
  table.newActive();
  table.insert("k", Symbol("float", 0));

  /// A linha seguinte declara um novo escopo, nesse novo escopo não foi
  /// declarado nenhuma variável
  table.newActive();

  /// As três linhas seguintes fecham os escopos anteriores (if, if, func)
  table.activeRewind();
  table.activeRewind();
  table.activeRewind();

  /// No momento estamos no escopo global com os símbolos i e j
  /// Entramos no escopo da função main
  table.insert("main", Symbol("function", 0));
  table.newActive(); /// Entrada no escopo da função main

  /// Declaramos uma nova variável nesse novo escopo
  table.insert("k", Symbol("int", 0));

  /// Antes de sairmos do escopo da função main, veja que podemos procurar por
  /// todos os símbolos declarados da função main e do escopo global
  std::cout << "i -> " << *table.lookup("i") << std::endl;
  std::cout << "j -> " << *table.lookup("i") << std::endl;
  std::cout << "k -> " << *table.lookup("i") << std::endl;

  /// Podemos agora sair do escopo da função main
  table.activeRewind();
  
  return 0;
}