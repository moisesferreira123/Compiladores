# Compilador Comp25.4 ⚙️

![C++](https://img.shields.io/badge/C%2B%2B-17-blue) ![Flex](https://img.shields.io/badge/Flex-2.6.4-orange) ![Bison](https://img.shields.io/badge/Bison-3.8.2-brightgreen)

Implementação de um compilador para a linguagem **Comp25.4**, incluindo análise léxica (Flex), análise sintática e semântica (Bison), geração de código intermediário (TAC) e suíte de testes automatizados.

## Table of Contents

* [Introduction](#introduction)
* [Features](#features)
* [Getting Started](#getting-started)

  * [Prerequisites](#prerequisites)
  * [Clone the Repository](#clone-the-repository)
  * [Compilation with CMake](#compilation-with-cmake)
* [Usage](#usage)

  * [Compiler (`compiler`)](#compiler-compiler)
  * [Test Runner (`run_tests`)](#test-runner-run_tests)
  * [Output Directory Structure](#output-directory-structure)
* [Project Structure](#project-structure)
* [Contributing](#contributing)
* [License](#license)
* [Contact](#contact)

## Introduction 🚀

Este projeto contém um compilador completo para a variante **Comp25.4** da linguagem Comp25.x, desenvolvido no âmbito da disciplina DIM0164 – Compiladores (UFRN). O compilador cobre desde a análise léxica até a geração de código intermediário em C (TAC), e inclui uma ferramenta de testes automatizados.

## Features 🌟

* **Análise Léxica** com Flex
* **Análise Sintática e Semântica** com Bison
* **Tabela de Símbolos** para variáveis, procedimentos, structs e enums
* **Geração de Código Intermediário** (Three‑Address Code em `tac.c`)
* **Suíte de Testes Automatizados** (`run_tests`)
* **Logs Detalhados** de compilação e execução de testes

## Getting Started 🛠️

### Prerequisites

* CMake ≥ 3.11
* Flex
* Bison
* Compilador C++17 (g++ ou clang++)

### Clone the Repository

```bash
git clone https://github.com/moisesferreira123/Compiladores.git
cd Compiladores
```

### Compilation with CMake

```bash
# Cria e configura o build
cmake -B build

# Compila os executáveis: `compiler` e `run_tests`
cmake --build build
```

## Usage 🎮

Após a compilação, dois executáveis estarão disponíveis em `build/`:

### Compiler (`compiler`)

Analisa e compila um arquivo-fonte Comp25.4:

```bash
# Sintaxe: ./build/compiler <source_file>
./build/compiler <caminho/para/fonte.c25>
```

### Test Runner (`run_tests`)

Executa a suíte de testes automatizados:

```bash
# Invoca todos os casos de teste em /tests/files
./build/run_tests --all
```

### Output Directory Structure

Ao executar **qualquer** dos binários (`compiler` ou `run_tests`), será criada a pasta `output/` com a seguinte organização:

```
output/
├── tac.c              # Código intermediário gerado (Three‑Address Code)
├── logs.txt           # Log completo da execução (compilação ou testes)
└── build/
    └── tac            # Programa compilado a partir de tac.c
```

## Project Structure 📁

```
.
├── libs/
│   └── iosystem.h             # Biblioteca de I/O da linguagem
├── src/
│   ├── main.cpp               # Ponto de partida: parsing e invocação do compilador
│   ├── parsers/
│   │   ├── lexer.lex          # Flex: analisador léxico
│   │   └── parser.y           # Bison: analisador sintático e semântico
│   └── include/
│       ├── logger.hpp/.cpp    # Registro de eventos e mensagens de erro
│       ├── utils.hpp/.cpp     # Funções auxiliares do parser
│       ├── symbol_table.hpp/.cpp  
│       └── tac/
│           ├── tac.hpp        # Definição de instruções TAC
│           └── codegen.hpp/.cpp  # Geração de código TAC
├── tests/
│   ├── run_tests.cpp          # Ferramenta de testes automatizados
│   └── files/                 # Arquivos-fonte para testes
└── CMakeLists.txt  
```

## Contributing 🤝

Contribuições são bem‑vindas!

1. Abra uma *issue* para discutir a mudança.
2. Envie um *pull request* com sua implementação.

## License 📄

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

## Contact 📧

Feito com ❤️ por Gabriel Victor, Lucas Apolonio, Moisés Ferreira e Pedro Lucas

* Email: [pedrolucas.jsrn@gmail.com](mailto:pedrolucas.jsrn@gmail.com)