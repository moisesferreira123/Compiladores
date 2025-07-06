cmake_minimum_required(VERSION 3.10)
project(comp25.4)

set(CMAKE_CXX_STANDARD 17)

# Diretórios
set(SRC_DIR ${CMAKE_SOURCE_DIR}/src)
set(BUILD_DIR ${CMAKE_BINARY_DIR})
set(HEADERS_DIR ${SRC_DIR}/include)
set(PARSERS_DIR ${SRC_DIR}/parsers)
set(INTERMEDIATE_DIR ${BUILD_DIR}/intermediate)

# Fontes
set(SYMBOL_TABLE ${HEADERS_DIR}/symbol_table.cpp)
set(LOGGER ${HEADERS_DIR}/logger.cpp)
set(UTILS ${HEADERS_DIR}/utils.cpp)
set(MAIN ${SRC_DIR}/main.cpp)
set(TESTS tests/run_tests.cpp)
set(LEX ${PARSERS_DIR}/lexer.lex)
set(YACC ${PARSERS_DIR}/parser.y)
set(HEADERS ${HEADERS_DIR}/symbol_table.hpp
   ${HEADERS_DIR}/utils.hpp
   ${HEADERS_DIR}/logger.hpp)

# Arquivos gerados
set(LEX_C ${INTERMEDIATE_DIR}/lex.yy.c)
set(YACC_C ${INTERMEDIATE_DIR}/exp.tab.c)
set(YACC_H ${INTERMEDIATE_DIR}/exp.tab.h)

# Comandos para gerar os arquivos com bison e flex
find_program(BISON_EXECUTABLE bison REQUIRED)
find_program(FLEX_EXECUTABLE flex REQUIRED)

add_custom_command(
    OUTPUT ${YACC_C} ${YACC_H}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${INTERMEDIATE_DIR}
    COMMAND ${BISON_EXECUTABLE} -d -o ${YACC_C} ${YACC}
    DEPENDS ${YACC}
    COMMENT "Running Bison"
)

add_custom_command(
    OUTPUT ${LEX_C}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${INTERMEDIATE_DIR}
    COMMAND ${FLEX_EXECUTABLE} -o ${LEX_C} ${LEX}
    DEPENDS ${LEX} ${YACC_H}
    COMMENT "Running Flex"
)


# Forçar CMake a compilar os arquivos gerados como C++
set_source_files_properties(${LEX_C} PROPERTIES LANGUAGE CXX)
set_source_files_properties(${YACC_C} PROPERTIES LANGUAGE CXX)

# Adicionar biblioteca para symbol_table
add_library(symbol_table OBJECT ${SYMBOL_TABLE})
target_include_directories(symbol_table PUBLIC ${SRC_DIR})

# Adicionar biblioteca para logger
add_library(logger OBJECT ${LOGGER})
target_include_directories(logger PUBLIC ${SRC_DIR})

# Adicionar biblioteca para utils
add_library(utils OBJECT ${UTILS})
target_include_directories(utils PUBLIC ${SRC_DIR})

# Adicionar biblioteca para main
add_library(main_obj OBJECT ${MAIN})
target_include_directories(main_obj PUBLIC ${HEADERS_DIR})

add_library(test_obj OBJECT ${TESTS})
target_include_directories(test_obj PUBLIC ${HEADERS_DIR})

# Compilar arquivos gerados
add_library(yacc_obj OBJECT ${YACC_C})
add_library(lex_obj OBJECT ${LEX_C})

# Corrigir includes
target_include_directories(lex_obj PRIVATE ${HEADERS_DIR} ${INTERMEDIATE_DIR})
target_include_directories(yacc_obj PRIVATE ${HEADERS_DIR} ${INTERMEDIATE_DIR})

# Compilar executável principal
add_executable(compiler
    $<TARGET_OBJECTS:symbol_table>
    $<TARGET_OBJECTS:logger>
    $<TARGET_OBJECTS:utils>
    $<TARGET_OBJECTS:main_obj>
    $<TARGET_OBJECTS:lex_obj>
    $<TARGET_OBJECTS:yacc_obj>
)

target_include_directories(compiler PRIVATE ${SRC_DIR} ${INTERMEDIATE_DIR})
target_link_libraries(compiler fl)

# Executável run_tests
add_executable(run_tests
    $<TARGET_OBJECTS:test_obj>
    $<TARGET_OBJECTS:symbol_table>
    $<TARGET_OBJECTS:logger>
    $<TARGET_OBJECTS:utils>
    $<TARGET_OBJECTS:lex_obj>
    $<TARGET_OBJECTS:yacc_obj>
)

target_include_directories(run_tests PRIVATE ${SRC_DIR} ${INTERMEDIATE_DIR} tests)
target_link_libraries(run_tests fl)

# Colocar executáveis na pasta build
set_target_properties(compiler PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BUILD_DIR})
set_target_properties(run_tests PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BUILD_DIR})
