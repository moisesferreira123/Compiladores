#include "module/FirstFollowCalculator.hpp"
#include "module/Grammar.hpp"
#include <iostream>


FirstFollowCalculator::FirstFollowCalculator(const Grammar& grammar) : grammar(grammar) {
    computeFirst();
    computeFollow();
}

void FirstFollowCalculator::computeFirst() {
    bool changed;
    
    do {
        changed = false;
        
        for (const auto& pair : grammar.getProductionsMap()) {
            const auto& nonTerminal = pair.first;  // O não-terminal atual (lado esquerdo da produção)
            const auto& productionList = pair.second;  // Lista de produções deste não-terminal

            for (const auto& production : productionList) {
                size_t beforeSize = first[nonTerminal].size();
                bool allNullable = true;
                
                // Se produção é diretamente ε
                if (production.producesEpsilon) {
                    first[nonTerminal].insert(EPSILON);
                    if (first[nonTerminal].size() > beforeSize) {
                        changed = true;
                    }
                    continue;
                }
                
                for (const auto& symbol : production.symbols) {
                    // CASO 1: Símbolo terminal
                    if (grammar.isTerminal(symbol)) {
                        first[nonTerminal].insert(symbol);
                        allNullable = false;
                        break;
                    }
                    
                    // CASO 2: Símbolo não-terminal
                    
                    // Se FIRST ainda não foi calculado, continua para próxima iteração
                    if (first.find(symbol) == first.end()) {
                        allNullable = false;
                        break;
                    }
                    
                    // Adiciona FIRST(symbol) - {ε}
                    bool hasEpsilon = false;
                    for (const auto& s : first[symbol]) {
                        if (s != EPSILON) {
                            first[nonTerminal].insert(s);
                        } else {
                            hasEpsilon = true;
                        }
                    }
                    
                    // Se não contém ε, não precisa verificar próximos símbolos
                    if (!hasEpsilon) {
                        allNullable = false;
                        break;
                    }
                }
                
                // Só adiciona ε se todos os símbolos na produção forem anuláveis
                if (allNullable) {
                    first[nonTerminal].insert(EPSILON);
                }
                
                if (first[nonTerminal].size() > beforeSize) {
                    changed = true;
                }
            }
        }
    } while (changed);
}


void FirstFollowCalculator::computeFollow() {
    // Inicializa FOLLOW com o símbolo inicial
    follow[grammar.getStartSymbol()].insert("$");

    bool changed;
    do {
        changed = false;

        for (const auto& pair : grammar.getProductionsMap()) {
            const auto& nonTerminal = pair.first;       // A → ...
            const auto& productionList = pair.second;   // Todas as produções A → α

            for (const auto& production : productionList) {
                const auto& symbols = production.symbols;  // α: lista de símbolos à direita

                for (size_t i = 0; i < symbols.size(); ++i) {
                    const auto& B = symbols[i];  // símbolo atual

                    if (!grammar.isNonTerminal(B)) continue;  // Só calcula FOLLOW para não-terminais

                    // Parte beta (os símbolos após B)
                    if (i + 1 < symbols.size()) {
                        // Existem símbolos depois de B
                        std::vector<std::string> beta(symbols.begin() + i + 1, symbols.end());

                        // Calcula FIRST(beta)
                        std::set<std::string> firstBeta = computeFirstSequence(beta);

                        for (const auto& symbol : firstBeta) {
                            if (symbol != EPSILON) { // Adiciona FIRST(beta) - {ε} no FOLLOW(B)
                                if (follow[B].insert(symbol).second) {
                                    changed = true;
                                }
                            }
                        }

                        // Se FIRST(beta) contém ε, adiciona FOLLOW(A) no FOLLOW(B)
                        if (firstBeta.count(EPSILON)) {
                            for (const auto& sym : follow[nonTerminal]) {
                                if (follow[B].insert(sym).second) {
                                    changed = true;
                                }
                            }
                        }
                    } 
                    else {
                        // B é o último símbolo da produção
                        // Adiciona FOLLOW(A) no FOLLOW(B)
                        for (const auto& sym : follow[nonTerminal]) {
                            if (follow[B].insert(sym).second) {
                                changed = true;
                            }
                        }
                    }

                }
            }
        }
    } while (changed);
}

std::set<std::string> FirstFollowCalculator::computeFirstSequence(const std::vector<std::string>& symbols) const {
    std::set<std::string> result;

    bool allNullable = true;  // Se todos os símbolos até agora geram ε

    for (const auto& symbol : symbols) {
        if (grammar.isTerminal(symbol)) {
            result.insert(symbol);
            allNullable = false;
            break;  // Terminal bloqueia a cadeia
        } else {
            const auto& firstSet = first.at(symbol);
            bool hasEpsilon = false;

            for (const auto& s : firstSet) {
                if (s == EPSILON) {
                    hasEpsilon = true;
                } else {
                    result.insert(s);
                }
            }

            if (!hasEpsilon) {
                allNullable = false;
                break;
            }
        }
    }

    if (allNullable) {
        result.insert(EPSILON);
    }

    return result;
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



void FirstFollowCalculator::exportFirstAndFollowToCSV() const {
    const std::string FILE_PATH_FF = "output/first_follow_table.csv"; // defina se ainda não tiver

    // Abre o arquivo CSV para escrita
    std::ofstream file(FILE_PATH_FF);

    if (!file.is_open()) {
        throw std::runtime_error("Não foi possível abrir o arquivo " + FILE_PATH_FF + " para escrita");
        return;
    }

    // Escreve o cabeçalho
    file << "NonTerminal,FIRST,FOLLOW" << std::endl;

    for (const auto& nonTerminal : grammar.getNonTerminals()) {
        file << nonTerminal << ",";

        // FIRST
        std::string firstSymbols;
        auto itFirst = first.find(nonTerminal);
        if (itFirst != first.end()) {
            for (const auto& symbol : itFirst->second) {
                firstSymbols += symbol + " ";
            }
            if (!firstSymbols.empty())
                firstSymbols.pop_back(); // Remove o último espaço
        } else {
            firstSymbols = "(vazio)";
        }
        file << "\"" << firstSymbols << "\"" << ","; // Coloca entre aspas para evitar problemas no CSV

        // FOLLOW
        std::string followSymbols;
        auto itFollow = follow.find(nonTerminal);
        if (itFollow != follow.end()) {
            for (const auto& symbol : itFollow->second) {
                followSymbols += symbol + " ";
            }
            if (!followSymbols.empty())
                followSymbols.pop_back(); // Remove o último espaço
        } else {
            followSymbols = "(vazio)";
        }
        file << "\"" << followSymbols << "\"" << std::endl; // Coloca entre aspas também

    }

    file.close();
}



bool FirstFollowCalculator::firstContainsEpsilon(const std::set<std::string>& firstSet) const {
    return firstSet.find(EPSILON) == firstSet.end();
}


const std::unordered_map<std::string, std::set<std::string>>& FirstFollowCalculator::getFirst() const {
    return first;
}

const std::unordered_map<std::string, std::set<std::string>>& FirstFollowCalculator::getFollow() const{
    return follow;
}

