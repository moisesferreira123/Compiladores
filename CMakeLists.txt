cmake_minimum_required(VERSION 3.10)
project(ParserProject)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Inclui os headers
include_directories(include)

# Arquivos fonte
set(SOURCES
    main.cpp
    include/parser/Parser.cpp
    include/lexical_analyzer/lex.yy.cc
)

# Cria o executável
add_executable(parser_exec ${SOURCES})


# Linkar com o Flex
find_package(FLEX REQUIRED)
