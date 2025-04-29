#include "module/Grammar.hpp"
#include <fstream>
#include <sstream>
#include <iostream>

Grammar::Grammar() {
    loadFromFile(); // Carrega a gramática do arquivo
}

void Grammar::addProduction(const std::string& nonTerminalName, const std::vector<std::string>& production) {
    bool isEpsilon = (production.empty() || (production.size() == 1 && production[0] == "''"));
    Production prod(production, isEpsilon);

    productionsMap[nonTerminalName].push_back(prod);
    nonTerminals.insert(nonTerminalName);
}


const std::unordered_map<std::string, std::vector<Production>>& Grammar::getProductionsMap() const {
    return productionsMap;
}

const std::set<std::string>& Grammar::getNonTerminals() const {
    return nonTerminals;
}

const std::set<std::string>& Grammar::getTerminals() const {
    return terminals;
}


// 🚀 Aqui a função que você queria:
bool Grammar::nonTerminalProducesEpsilon(const std::string& nonTerminalName) const {
    auto it = productionsMap.find(nonTerminalName);
    if (it == productionsMap.end()) {
        return false; // não existe esse não-terminal
    }

    for (const auto& production : it->second) {
        if (production.producesEpsilon) {
            return true;
        }
    }
    return false;
}


void Grammar::loadFromFile() {
    std::ifstream file(GRAMMAR_FILE_PATH);
    if (!file) {
        std::cerr << "Erro ao abrir o arquivo: " << GRAMMAR_FILE_PATH << std::endl;
        return;
    }

    bool firstProduction = true; // <<<<<< FLAG

    std::string line;
    while (std::getline(file, line)) {
        // Antes de tudo: limpar espaços e tabs da linha
        line.erase(0, line.find_first_not_of(" \t\r\n")); // Remove espaços/tabs/quebras no início
        line.erase(line.find_last_not_of(" \t\r\n") + 1); // Remove espaços/tabs/quebras no final
        if (line.empty()) continue;  // Ignora linhas vazias

        // Encontra a posição do símbolo '::='
        std::size_t pos = line.find(ARROW);
        if (pos == std::string::npos) {
            std::cerr << "Erro na linha: " << line << " (faltando '::=')" << std::endl;
            continue;
        }

        // Separa a parte do lado esquerdo (não-terminal) e o lado direito (produções)
        std::string left = line.substr(0, pos);
        std::string right = line.substr(pos + ARROW.length());

        // Remover espaços extras
        // left.erase(0, left.find_first_not_of(" \t"));
        left.erase(left.find_last_not_of(" \t") + 1);
        right.erase(0, right.find_first_not_of(" \t"));
        // right.erase(right.find_last_not_of(" \t") + 1);

        // Verifica se a produção é 'ε'
        std::vector<std::string> symbols;
        bool isEpsilon = false;


        // Divide a produção (lado direito) em símbolos, separados por espaços
        std::istringstream iss(right);
        std::string symbol;
        while (iss >> symbol) {
            if (right == "''") {
                isEpsilon = true;
            }
            else{
                symbols.push_back(symbol);
            }
        }
        

        // Adiciona a produção ao unordered_mapa de produções
        addProduction(left, symbols);

        //Atualiza os conjuntos de não-terminais e terminais
        nonTerminals.insert(left);

        if (firstProduction) {
            startSymbol = left; // <<<<<< PEGA O PRIMEIRO NÃO TERMINAL LIDO
            firstProduction = false;
        }
    }

    identifyTerminals(); // Identifica terminais após carregar a gramática
    file.close();
}

void Grammar::identifyTerminals() {
    for (const auto& pair : productionsMap) {
        const auto& productionList = pair.second;

        for (const auto& production : productionList) {
            for (const auto& sym : production.symbols) {
                if (isTerminal(sym) && sym != "''") {
                    terminals.insert(sym);
                }
            }
        }
    }
}

bool Grammar::isNonTerminal(const std::string& symbol) const {
    return nonTerminals.find(symbol) != nonTerminals.end();
}

bool Grammar::isTerminal(const std::string& symbol) const{
    return nonTerminals.find(symbol) == nonTerminals.end();
}





void Grammar::printGrammar() const {
    for (const auto& pair : productionsMap) {
        const auto& nonTerminal = pair.first;
        const auto& productionList = pair.second;

        std::cout << nonTerminal << " ::= ";
        
        bool first = true;
        for (const auto& prod : productionList) {
            if (!first) {
                std::cout << " | ";
            }
            first = false;
            
            if (prod.producesEpsilon) {
                std::cout << "ε"; // Representa a produção vazia
            } else {
                for (const auto& symbol : prod.symbols) {
                    std::cout << symbol << " ";
                }
            }
        }
        std::cout << std::endl;
    }

}

std::string Grammar::getStartSymbol() const {
    if (startSymbol.empty()) {
        throw std::runtime_error("Simbolo inicial não definido.");
    }
    return startSymbol;
}
