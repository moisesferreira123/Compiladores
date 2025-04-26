#include "include/FirstFollowCalculator.hpp"
#include "include/Grammar.hpp"
#include <iostream>


FirstFollowCalculator::FirstFollowCalculator(const Grammar& grammar) : grammar(grammar) {
    computeFirst();
    computeFollow();
}

void FirstFollowCalculator::computeFirst() {
    bool changed;
    do {
        changed = false;
        for (const auto& pair : grammar.getproductionsMap()) {
            const auto& nonTerminal = pair.first;
            const auto& productionList = pair.second;

            for (const auto& production : productionList) {
                size_t beforeSize = first[nonTerminal].size();
                
                bool allNullable = true;
                for (const auto& symbol : production.symbols) {
                    if (grammar.isTerminal(symbol)) {
                        first[nonTerminal].insert(symbol);
                        allNullable = false;
                        break;
                    } else {
                        // Adiciona FIRST(symbol) exceto ε
                        for (const auto& s : first[symbol]) {
                            if (s != "ε") {
                                first[nonTerminal].insert(s);
                            }
                        }
                        
                        // Se symbol não é anulável, para
                        if (first[symbol].find("ε") == first[symbol].end()) {
                            allNullable = false;
                            break;
                        }
                    }
                }
                
                // Se todos símbolos geram ε, então a produção gera ε
                if (allNullable) {
                    first[nonTerminal].insert("ε");
                }
                
                if (first[nonTerminal].size() > beforeSize) {
                    changed = true;
                }
            }
        }
    } while (changed); // Repete até que não haja mais mudanças
}


void FirstFollowCalculator::printFirst() const {
    for (const auto& nonTerminal : grammar.getNonTerminals()) {
        std::cout << "FIRST(" << nonTerminal << ") = { ";

        auto it = first.find(nonTerminal);
        if (it != first.end()) {
            for (const auto& symbol : it->second) {
                std::cout << symbol << " ";
            }
        } else {
            std::cout << " (vazio) ";
        }

        std::cout << "}" << std::endl;
    }
}

void FirstFollowCalculator::printFollow() const {
    for (const auto& nonTerminal : grammar.getNonTerminals()) {
        std::cout << "FOLLOW(" << nonTerminal << ") = { ";

        auto it = follow.find(nonTerminal);
        if (it != follow.end()) {
            for (const auto& symbol : it->second) {
                std::cout << symbol << " ";
            }
        } else {
            std::cout << " (vazio) ";
        }

        std::cout << "}" << std::endl;
    }
}

// ERRO: A função computeFollow não está implementada corretamente.
void FirstFollowCalculator::computeFollow() {

    // Inicializa FOLLOW com o símbolo inicial
    follow[grammar.getStartSymbol()].insert("$"); // Adiciona o símbolo de fim de entrada

    bool changed;
    do {
        changed = false;
        for (const auto& pair : grammar.getproductionsMap()) {
            const auto& nonTerminal = pair.first;
            const auto& productionList = pair.second;

                for (const auto& production : productionList) {

                    size_t beforeSize = follow[nonTerminal].size();
                    
                    // Percorre os símbolos da produção
                    for (size_t i = 0; i < production.symbols.size(); ++i) {
                        const auto& symbol = production.symbols[i];
                        
                        if (grammar.isNonTerminal(symbol)) {
                            // Se o próximo símbolo não existe ou é terminal, adiciona FOLLOW(nonTerminal)
                            if (i + 1 >= production.symbols.size()) {
                                follow[symbol].insert(follow[nonTerminal].begin(), follow[nonTerminal].end());
                            } else {
                                const auto& nextSymbol = production.symbols[i + 1];
                                
                                if (grammar.isTerminal(nextSymbol)) {
                                    follow[symbol].insert(nextSymbol);
                                } else {
                                    // Adiciona FIRST(nextSymbol) exceto ε
                                    for (const auto& s : first[nextSymbol]) {
                                        if (s != "ε") {
                                            follow[symbol].insert(s);
                                        }
                                    }
                                    
                                    // Se FIRST(nextSymbol) contém ε, adiciona FOLLOW(nonTerminal)
                                    if (first[nextSymbol].find("ε") != first[nextSymbol].end()) {
                                        follow[symbol].insert(follow[nonTerminal].begin(), follow[nonTerminal].end());
                                    }
                                }
                            }
                        }
                    }
                    
                    if (follow[nonTerminal].size() > beforeSize) {
                        changed = true;
                    }
                    
                }
                
            
        }
    } while (changed); // Repete até que não haja mais mudanças
}


