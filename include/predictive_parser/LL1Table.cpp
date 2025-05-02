#include "module/LL1Table.hpp"
#include <iostream>


LL1Table::LL1Table() : grammar(), calculator(grammar) {
    buildTable();
    // Inicializa grammar normalmente
    // Inicializa calculator com referência a grammar
}

const std::unordered_map<std::pair<int, int>, std::vector<int>, pair_hash> LL1Table::getTable() const {
    return parsingTable;
}

bool LL1Table::existsToken(std::unordered_map<std::string, int>::iterator terminalIt, std::string symbol){
    if (terminalIt == terminalToToken.end()) {
        std::cerr << "Erro: simbolo não encontrado no terminalToToken: " << symbol << std::endl;
        return false;
    }
    return true;
}

void LL1Table::buildTable() {
    const auto& follow = calculator.getFollow();

    for (const auto& pair : grammar.getProductionsMap()) {
        const auto& nonTerminal = pair.first;
        const auto& productionList = pair.second;

        // Verifica se o não-terminal está no terminalToToken
        auto lhsIt = terminalToToken.find(nonTerminal);
        int lhsInt = lhsIt->second;

        for (const auto& production : productionList) {
            std::vector<std::string> symbols = production.symbols;

            // Calcula o FIRST da sequência da produção
            auto firstSet = calculator.computeFirstSequence(symbols);

            // Para cada terminal no FIRST (exceto EPSILON)
            for (const auto& terminal : firstSet) {
                if (terminal == EPSILON) continue;

                auto terminalIt = terminalToToken.find(terminal);
                if(!existsToken(terminalIt, terminal)) continue; // Chama a função teste com o iterator

                // Cria o vetor RHS
                std::vector<int> rhs;
                for (const auto& sym : symbols) {
                    auto symIt = terminalToToken.find(sym);

                    if(!existsToken(symIt, terminal)) continue;
                    rhs.insert(rhs.begin(), symIt->second); // Adiciona o símbolo no inicio do vetor

                }

                table[{nonTerminal, terminal}] = &production;
                parsingTable[{lhsInt, terminalIt->second}] = rhs;
            }

            bool derivesEpsilon = (firstSet.find(EPSILON) != firstSet.end());

            // Se a produção gera EPSILON
            if (derivesEpsilon) {
                auto followIt = follow.find(nonTerminal);

                for (const auto& terminal : followIt->second) {
                    auto terminalIt = terminalToToken.find(terminal);
                    table[{nonTerminal, terminal}] = &production;

                    // Agora adiciona RHS contendo só o EPSILON
                    parsingTable[{lhsInt, terminalIt->second}] = { terminalToToken.at(EPSILON) };
                }
            }
        }
    }
}

void LL1Table::exportTableToCSV() const {
    std::ofstream csvFile(TABLE_FILE_PATH);
    
    if (!csvFile.is_open()) {
        throw std::runtime_error("Não foi possível abrir o arquivo " + TABLE_FILE_PATH + " para escrita");
    }

    // Obtém todos os terminais únicos para criar os cabeçalhos das colunas
    std::set<std::string> allTerminals;
    for (const auto& entry : table) {
        allTerminals.insert(entry.first.second);
    }

    // Escreve o cabeçalho do CSV
    csvFile << "Não-Terminal";
    for (const auto& terminal : allTerminals) {
        csvFile << "," << terminal;
    }
    csvFile << "\n";

    // Escreve os dados para cada não-terminal
    for (const auto& pair : grammar.getProductionsMap()) {
        const auto& nonTerminal = pair.first;       // Não-terminal (lado esquerdo)
        const auto& productionList = pair.second;   // Lista de produções
        csvFile << nonTerminal;  // Escreve o não-terminal na primeira coluna
        
        for (const auto& terminal : allTerminals) {
            auto it = table.find({nonTerminal, terminal});
            if (it != table.end()) {
                // Formata a produção para exibição
                csvFile << "," << formatProduction(*it->second);
            } else {
                csvFile << ",";  // Célula vazia
            }
        }
        csvFile << "\n";
    }

    csvFile.close();
}

std::string LL1Table::formatProduction(const Production& production) const {
    if (production.producesEpsilon) {
        return "ε";
    }
    
    std::string formatted;
    for (const auto& symbol : production.symbols) {
        formatted += symbol + " ";
    }
    
    // Remove o espaço extra no final
    if (!formatted.empty()) {
        formatted.pop_back();
    }
    
    return formatted;
}


void LL1Table::exportParsingTableToCSV() const {
    std::ofstream csvFile(PARSING_TABLE_FILE_PATH);
    
    if (!csvFile.is_open()) {
        throw std::runtime_error("Não foi possível abrir o arquivo " + PARSING_TABLE_FILE_PATH + " para escrita");
    }

    // Obtém todos os não-terminais e terminais únicos
    std::set<int> allNonTerminals;
    std::set<int> allTerminals;
    
    for (const auto& entry : parsingTable) {
        allNonTerminals.insert(entry.first.first);
        allTerminals.insert(entry.first.second);
    }

    // Escreve o cabeçalho do CSV
    csvFile << "NT/T";
    for (const auto& terminal : allTerminals) {
        csvFile << "," << terminal;
    }
    csvFile << "\n";

    // Escreve os dados para cada não-terminal
    for (const auto& nonTerminal : allNonTerminals) {
        csvFile << nonTerminal;
        
        for (const auto& terminal : allTerminals) {
            auto it = parsingTable.find({nonTerminal, terminal});
            if (it != parsingTable.end()) {
                csvFile << ",\"";
                const auto& production = it->second;
                if (production.empty()) {
                    csvFile << "ε";
                } else {
                    for (size_t i = 0; i < production.size(); ++i) {
                        if (i > 0) csvFile << " ";
                        csvFile << production[i];
                    }
                }
                csvFile << "\"";
            } else {
                csvFile << ",";  // Célula vazia
            }
        }
        csvFile << "\n";
    }

    csvFile.close();
}

void LL1Table::exportFirstAndFollowToCSV() const {
    calculator.exportFirstAndFollowToCSV(); // Exporta os conjuntos FIRST e FOLLOW para CSV
}