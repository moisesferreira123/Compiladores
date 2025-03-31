#ifndef SYMBOL_TABLE_TEMPORARY_HPP_
#define SYMBOL_TABLE_TEMPORARY_HPP_

#include <iostream>
#include <unordered_map>
#include <string>

class SymbolTableTemporary{
  private:
    std::unordered_map<std::string,std::string> symbolTable;
  public:
    std::string insert(std::string name){
      symbolTable.insert({name, name});
      return symbolTable[name];
    }

    // Para teste
    void printTable(){
      for(auto symbol:symbolTable){
        std::cout << symbol.first << " : " << symbol.second << "\n";
      }
    }
};

#endif