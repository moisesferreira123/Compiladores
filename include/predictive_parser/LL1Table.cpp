#include "module/LL1Table.hpp"
#include <iostream>

LL1Table::LL1Table(const Grammar& grammar, const FirstFollowCalculator& calculator)
    : grammar(grammar), calculator(calculator) {
    buildTable();
}   



// void LL1Table::buildTable() {
//     const auto& first = calculator.getFirst();    
//     const auto& follow = calculator.getFollow();  

//     // Percorre todas as produções da gramática
//     for (const auto& pair : grammar.getProductionsMap()) {
//         const auto& nonTerminal = pair.first;       // Não-terminal (lado esquerdo)
//         const auto& productionList = pair.second;   // Lista de produções

//         for (const auto& production : productionList) {
//             // Caso 1: Se o primeiro símbolo do não-terminal não gera epsilon diretamente
//             if (first.at(nonTerminal).find(EPSILON) == first.at(nonTerminal).end()) {
//                 // Adiciona a produção à tabela para os terminais do FIRST do não-terminal
//                 for (const auto& terminal : first.at(nonTerminal)) {
//                     // Aqui você está associando a produção correta ao par (não-terminal, terminal)
//                     table[{nonTerminal, terminal}] = &production;  
//                 }
//             } else {
//                 // Caso 2: Produção gera epsilon (ou pode gerar epsilon indiretamente)
//                 // Aqui você pode querer adicionar a produção epsilon aos terminais no FOLLOW
//                 for (const auto& terminal : follow.at(nonTerminal)) {
//                     // Adiciona a produção epsilon à tabela para os terminais no FOLLOW
//                     table[{nonTerminal, terminal}] = &production;  
//                 }
//                 // Se o símbolo "$" está no FOLLOW, também deve ser mapeado para a produção epsilon
//                 if (follow.at(nonTerminal).find("$") != follow.at(nonTerminal).end()) {
//                     table[{nonTerminal, "$"}] = &production;
//                 }
//             }
//         }
//     }
// }


// void LL1Table::buildTable() {
//     const auto& first = calculator.getFirst();
//     const auto& follow = calculator.getFollow();

//     for (const auto& pair : grammar.getProductionsMap()) {
//         const auto& nonTerminal = pair.first;
//         const auto& productionList = pair.second;

//         for (const auto& production : productionList) {
//             // Vamos usar o primeiro símbolo da produção
//             if (!production.symbols.empty()) {
//                 const std::string& firstSymbol = production.symbols[0];

//                 if (grammar.isTerminal(firstSymbol)) {
//                     // Se for terminal, insere direto
//                     table[{nonTerminal, firstSymbol}] = &production;
//                 } else {
//                     // Se for não-terminal, insere todos do FIRST dele
//                     for (const auto& terminal : first.at(firstSymbol)) {
//                         if (terminal != EPSILON) {
//                             table[{nonTerminal, terminal}] = &production;
//                         }
//                     }

//                     // Se o FIRST do símbolo contém ε
//                     if (first.at(firstSymbol).find(EPSILON) != first.at(firstSymbol).end()) {
//                         for (const auto& terminal : follow.at(nonTerminal)) {
//                             table[{nonTerminal, terminal}] = &production;
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }


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

