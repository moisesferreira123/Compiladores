cmake_minimum_required(VERSION 3.10)
project(AnalisadorLexico)

# Definir o diretório de saída
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/build)

file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/include/lexical_analyzer)

# Encontrar o Flex
find_package(FLEX REQUIRED)

# Definir os arquivos de entrada e saída
set(LEX_FILE ${CMAKE_SOURCE_DIR}/include/lexical_analyzer/analisadorLexico.lex)
set(GENERATED_LEX_FILE ${CMAKE_BINARY_DIR}/include/lexical_analyzer/lex.yy.cc)

# Gerar o analisador léxico com Flex
add_custom_command(
    OUTPUT ${GENERATED_LEX_FILE}
    COMMAND flex --c++ -o ${GENERATED_LEX_FILE} ${LEX_FILE}
    MAIN_DEPENDENCY ${LEX_FILE}
    COMMENT "Gerando o analisador léxico com Flex..."
)

# Criar o executável
add_executable(teste ${GENERATED_LEX_FILE})

target_link_libraries(teste fl)

target_include_directories(teste PRIVATE include/lexical_analyzer)

# Adicionar um alvo personalizado para execução
add_custom_target(run
    COMMAND ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/teste < ${CMAKE_SOURCE_DIR}/include/lexical_analyzer/teste.txt
    DEPENDS teste
    COMMENT "Executando o analisador léxico..."
)
