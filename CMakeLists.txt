cmake_minimum_required(VERSION 3.10)
project(exp_compiler)

set(CMAKE_CXX_STANDARD 17)

# Diretórios
set(SRC_DIR ${CMAKE_SOURCE_DIR})
set(BUILD_DIR ${CMAKE_BINARY_DIR})
set(INTERMEDIATE_DIR ${BUILD_DIR}/intermediate)

# Fontes
set(SYMBOL_TABLE ${SRC_DIR}/symbol_table.cpp)
set(MAIN ${SRC_DIR}/main.cpp)
set(LEX ${SRC_DIR}/exp.l)
set(YACC ${SRC_DIR}/exp.y)
set(HEADERS ${SRC_DIR}/symbol_table.hpp)

# Arquivos gerados
set(LEX_C ${INTERMEDIATE_DIR}/lex.yy.c)
set(YACC_C ${INTERMEDIATE_DIR}/exp.tab.c)
set(YACC_H ${INTERMEDIATE_DIR}/exp.tab.h)

# Comandos para gerar os arquivos com bison e flex
find_program(BISON_EXECUTABLE bison)
find_program(FLEX_EXECUTABLE flex)

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
    DEPENDS ${LEX}
    COMMENT "Running Flex"
)

# Adicionar biblioteca para symbol_table
add_library(symbol_table OBJECT ${SYMBOL_TABLE})
target_include_directories(symbol_table PUBLIC ${SRC_DIR})

# Adicionar biblioteca para main
add_library(main_obj OBJECT ${MAIN})
target_include_directories(main_obj PUBLIC ${SRC_DIR})

# Compilar arquivos gerados
add_library(lex_obj OBJECT ${LEX_C})
add_library(yacc_obj OBJECT ${YACC_C})

# Compilar executável
add_executable(exp
    $<TARGET_OBJECTS:symbol_table>
    $<TARGET_OBJECTS:main_obj>
    $<TARGET_OBJECTS:lex_obj>
    $<TARGET_OBJECTS:yacc_obj>
)

target_include_directories(exp PRIVATE ${SRC_DIR} ${INTERMEDIATE_DIR})
target_link_libraries(exp fl)

# Colocar executável na pasta build
set_target_properties(exp PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BUILD_DIR})
