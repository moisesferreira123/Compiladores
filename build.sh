#!/bin/bash

# Nome do executável
TARGET=compiler

# Cria a pasta build se não existir
mkdir -p build

# Gera o scanner.cpp do scanner.lpp (com opção --c++ para flex em C++)
flex -o build/scanner.cpp --c++ compiler/scanner.lpp
if [ $? -ne 0 ]; then
  echo "Erro no flex"
  exit 1
fi

# Gera o parser.cpp e parser.hpp do parser.ypp
bison -d -Wcounterexamples -o build/parser.cpp compiler/parser.ypp
if [ $? -ne 0 ]; then
  echo "Erro no bison"
  exit 1
fi

# Compila tudo junto
g++ -std=c++17 -Ibuild -Icompiler -o build/$TARGET \
    compiler/main.cpp \
    build/scanner.cpp build/parser.cpp \
    -Wall -Wextra -g

if [ $? -eq 0 ]; then
  echo "Build concluído com sucesso! Executável em build/$TARGET"
else
  echo "Erro na compilação"
  exit 1
fi
