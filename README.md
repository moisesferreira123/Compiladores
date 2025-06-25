# Compilador para a Linguagem Comp25.4

Este repositório contém a implementação de um compilador para a variante Comp25.4 da linguagem Comp25.x, desenvolvida como parte da disciplina DIM00164 - Compiladores na Universidade Federal do Rio Grande do Norte (UFRN).

## Sumário

1.  [Visão Geral da Comp25.4](#visão-geral-da-comp254)
2.  [Estrutura do Projeto](#estrutura-do-projeto)
3.  [Como Construir e Executar](#como-construir-e-executar)
4.  [Aspectos de Implementação](#aspectos-de-implementação)
5.  [Especificação da Linguagem (Comp25.4)](#especificação-da-linguagem-comp254)
6.  [Testes Realizados](#testes-realizados)

## Visão Geral da Comp25.4

A Comp25.4 é uma extensão da linguagem base Comp25.x, focando na adição de **tipos enumerados (enums)**. Esta funcionalidade permite aos programadores definir conjuntos de valores nomeados, aumentando a legibilidade e a segurança de tipos no código.

**Principais características da Comp25.4:**

* **Declaração de Enums**: Suporte para a declaração de tipos enumerados usando a sintaxe `enum NOME = { NOME {"," NOME} }`.
* **Comparação de Elementos Enumerados**: Elementos de tipos enumerados podem ser comparados, com a ordem definida pela sequência de sua declaração.
* **Declaração e Atribuição de Variáveis Enumeradas**: É possível declarar variáveis com tipos enumerados e atribuir valores a elas.

## Estrutura do Projeto

O projeto está organizado da seguinte forma:

```

Compiladores
├── CMakeLists.txt
├── README.md
├── docs
│   └── input
│       ├── ... (exemplos de código da linguagem)
│       └── day\_of\_week.txt (exemplo específico de enum)
└── src
├── exp.l     (Analisador Léxico - Flex)
├── exp.y     (Analisador Sintático e Semântico - Bison)
├── include
│   ├── symbol\_table.cpp
│   ├── symbol\_table.hpp
│   └── type\_utils.hpp
└── main.cpp

````

* `src/exp.l`: Define o analisador léxico usando Flex, responsável pela quebra do código fonte em tokens.
* `src/exp.y`: Contém a gramática da linguagem e as regras semânticas implementadas com Bison, realizando a análise sintática e a verificação de tipos.
* `src/include/symbol_table.hpp`, `symbol_table.cpp`: Implementa a tabela de símbolos para gerenciar escopos e declarações de variáveis, procedimentos, structs e, especificamente para esta variante, enums.
* `src/include/type_utils.hpp`: Contém utilitários para manipulação e verificação de tipos.
* `src/main.cpp`: Ponto de entrada do compilador, onde a análise é iniciada.
* `docs/input/`: Contém exemplos de código na linguagem Comp25.4. Os arquivos diretamente nesta pasta (`docs/input/`) são casos de teste válidos.
* `docs/input/extend/`: Esta subpasta contém casos de teste com erros intencionais, utilizados para verificar a capacidade do compilador em detectar e reportar falhas.

## Como Construir e Executar

Este projeto utiliza CMake para gerenciar o processo de construção.

### Pré-requisitos

Certifique-se de ter as seguintes ferramentas instaladas:

* **CMake** (versão 3.10 ou superior)
* **Flex**
* **Bison**
* **Um compilador C++** (como g++ ou clang++)

### Construção

Para construir o compilador, siga os passos no diretório principal do projeto (`Compiladores`):

1.  Crie o diretório de build e configure o projeto:
    ```bash
    cmake -B build
    ```

2.  Compile o projeto:
    ```bash
    cmake --build build
    ```

Após a compilação, o executável `exp` será gerado no diretório `build`.

### Execução

Para testar o compilador, você pode passar um arquivo de código fonte da linguagem Comp25.4 como entrada padrão. Por exemplo, usando o arquivo `day_of_week.txt`:

```bash
./build/exp < docs/input/day_of_week.txt
````

O compilador irá processar o arquivo e imprimir mensagens relacionadas à análise léxica, sintática e semântica, incluindo quaisquer erros encontrados.

## Aspectos de Implementação

O compilador segue as fases clássicas de compilação, com destaque para as implementações do analisador léxico, sintático e semântico.

  * **Analisador Léxico**: Implementado com Flex, é responsável por agrupar caracteres do código-fonte em lexemas e produzir uma sequência de tokens para o analisador sintático. A comunicação entre o analisador léxico (`yylex()`) e o analisador sintático é automática, passando tokens e seus atributos semânticos via `yylval`.
  * **Tabela de Símbolos**: Projetada como uma lista encadeada de mapas (hash tables), onde cada nó representa um escopo do programa. Isso permite a inserção e busca recursiva de símbolos, garantindo que as expressões acessem apenas símbolos em escopos que os contêm. Os tipos de símbolos armazenados incluem programas, variáveis, procedimentos, structs e enums, cada um com atributos específicos.
  * **Analisador Sintático**: Construído utilizando Bison/Yacc, ele verifica a sequência de tokens de acordo com as regras sintáticas da gramática LALR(1) da linguagem. As regras de precedência e associatividade dos operadores foram cuidadosamente especificadas no Bison para resolver ambiguidades sintáticas.
  * **Análise Semântica**: Focada exclusivamente na verificação de tipos, a análise semântica utiliza os conceitos de Traduções Dirigidas por Sintaxe (SDD) e Esquemas de Tradução Dirigidos por Sintaxe (SDT). Grafos de dependência foram utilizados para validar o fluxo de informações e a ordem de avaliação dos atributos na árvore sintática.

## Especificação da Linguagem (Comp25.4)

A variante Comp25.4 estende a linguagem base Comp25.x com a adição de **tipos enumerados**.

### Sintaxe de Declaração de Enum

A declaração de um tipo enumerado segue a seguinte regra na gramática:

```
DECL → ... | enum NAME "=" "{" NAME {"," NAME} "}"
```

Exemplo:

```comp25.4
program day_of_week
begin
   enum dayOfWeek = {
      MONDAY,
      TUESDAY,
      WEDNESDAY,
      THURSDAY,
      FRIDAY,
      SATURDAY,
      SUNDAY
   };
   // ...
end
```

### Semântica

  * **Comparação**: Elementos de tipos enumerados podem ser comparados usando operadores relacionais (`=`, `<>`, `>`, `<`, `>=`, `<=`). A ordem é definida pela sequência em que os valores são declarados dentro do `enum`.
  * **Atribuição**: Variáveis declaradas com um tipo enumerado podem receber qualquer um dos valores definidos no enum.
  * **Escopo**: Os tipos enumerados e seus valores seguem as regras de escopo normais da linguagem.

## Testes Realizados

Testes abrangentes foram realizados abrangendo todas as etapas da compilação: análise léxica, sintática, construção da tabela de símbolos e verificação de tipos. Foram utilizados programas-base localizados em `/docs/input` (casos de sucesso) e versões modificadas para testes de erro disponíveis em `/docs/input/extend`.

### Testes de Sucesso

Os programas `swap.txt`, `person.txt` e `day_of_week.txt` foram analisados com sucesso, validando recursos como declaração e chamada de procedimentos, tipagem e referências corretas, e o uso de registros e enumerações.

### Testes de Erro

As versões modificadas dos programas foram utilizadas para testar a robustez do sistema quanto à detecção de erros. Abaixo, destacamos os principais casos verificados:

  * **Erro Léxico**: Uso de um identificador inválido, como `x_`.
  * **Erro de Escopo**: Símbolo local a um procedimento sendo usado em outro escopo sem declaração.
  * **Erro de Tipo em Passagem de Parâmetro**: Variável do tipo `int` passada para um parâmetro `ref(int)`.
  * **Erro de Tipo em Campo de Struct**: Atribuição de uma `string` para um campo `int` de um `struct`.
  * **Erro Sintático**: Definição de `struct` com sintaxe não suportada pela linguagem.
  * **Erro de Campo Inexistente**: Tentativa de acessar um campo não declarado em um `struct` ou enumeração.
  * **Erro de Símbolo Não Declarado**: Uso de um identificador não definido em um procedimento.
  * **Erro de Tipo de Retorno**: Definição de retorno de procedimento como `string` com expressão de retorno `int`.
