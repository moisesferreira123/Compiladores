cmake_minimum_required(VERSION 3.10)
project(ParserProject)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Inclui os headers
include_directories(include)

# Arquivos fontes
set(RECURSIVE_SOURCES
    include/recursive_parser/Parser.cpp
    include/lexical_analyzer/lex.yy.cc
    recursive_parser.cpp
)

set(PREDICTIVE_SOURCES
    include/predictive_parser/Grammar.cpp
    include/predictive_parser/FirstFollowCalculator.cpp
    include/mapper/Mapper.cpp
    include/predictive_parser/LL1Table.cpp
    include/predictive_parser/PredictiveParser.cpp
    include/lexical_analyzer/lex.yy.cc
    predictive_parser.cpp
)

# Cria o executável
add_executable(recursive_parser ${RECURSIVE_SOURCES})
add_executable(predictive_parser ${PREDICTIVE_SOURCES})


# Linkar com o Flex
find_package(FLEX REQUIRED)
