#include "SymbolTable.hpp"
#include <iostream>

/*  IMAGINE O CÓDIGO E VEJA A TABELA DE SÍMBOLOS A SER CONSTRUÍDA
int i;
int j;

func(int i, int j) {
  if (i ==  0) {
    float k = j;

    if (k ==  0) {
      return 0;
    }
  }
}
*/

int main(int, char **) {
  SymbolTable table;

  /// OBS: A declaração acontece quando se coloca o tipo seguido do nome da
  /// variável: int i

  /// As duas primeiras linhas declaram elementos globais (primeiro scopo)
  table.insert("i", Symbol("int", 0));
  table.insert("i", Symbol("int", 0));

  /// A linha seguinte declara um novo escopo, nesse novo escopo são declaras
  /// duas novas variáveis
  table.setActive("func");
  table.insert("i", Symbol("int", 0));
  table.insert("j", Symbol("int", 0));

  /// A linha seguinte declara um novo escopo, nesse novo escopo é declarada uma
  /// nova variável Repare que a variável j foi declarada no escopo anterior
  table.setActive("if");
  table.insert("k", Symbol("float", 0));

  /// A linha seguinte declara um novo escopo, nesse novo escopo não foi
  /// declarado nenhuma variável
  table.setActive("if");

  /// As demais linhas fecham os escopos anteriores (voltam aos pais)
  table.setActiveParent();
  table.setActiveParent();
  table.setActiveParent();
  
  return 0;
}