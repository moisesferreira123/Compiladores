cmake_minimum_required(VERSION 3.10)
project(ParserProject)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Inclui os headers
include_directories(include)

# Arquivos fonte
set(SOURCES
# include/parser/Parser.cpp
    include/predictive_parser/Grammar.cpp
    include/predictive_parser/FirstFollowCalculator.cpp
    include/mapper/Mapper.cpp
    include/predictive_parser/LL1Table.cpp
    include/predictive_parser/PredictiveParser.cpp
    include/lexical_analyzer/lex.yy.cc
    main.cpp
)

# Cria o executável
add_executable(parser_exec ${SOURCES})


# Linkar com o Flex
find_package(FLEX REQUIRED)
