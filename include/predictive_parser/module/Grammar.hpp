#ifndef GRAMMAR_HPP
#define GRAMMAR_HPP

#include <string>
#include <vector>
#include <map>
#include <set>

const static std::string ARROW = "::="; // Define o símbolo de produção
constexpr const char* EPSILON = "ε"; // Define o símbolo de epsilon
static const std::string GRAMMAR_FILE_PATH = "gramatica.txt"; // Caminho do arquivo de gramática

struct Production {
    std::vector<std::string> symbols;
    bool producesEpsilon;

    Production(const std::vector<std::string>& syms, bool epsilon = false)
        : symbols(syms), producesEpsilon(epsilon) {}
};

class Grammar {
    std::map<std::string, std::vector<Production>> productionsMap; // Mapa de produções
    std::set<std::string> nonTerminals;
    std::set<std::string> terminals;
    std::string startSymbol; // Símbolo inicial (não-terminal)

    void identifyTerminals();


public:
    Grammar();

    void addProduction(const std::string& nonTerminalName, const std::vector<std::string>& production);

    const std::map<std::string, std::vector<Production>>& getProductionsMap() const;
    void loadFromFile();

    const std::set<std::string>& getNonTerminals() const;

    const std::set<std::string>& getTerminals() const;

    bool nonTerminalProducesEpsilon(const std::string& nonTerminalName) const;

    bool isNonTerminal(const std::string& symbol) const;

    bool isTerminal(const std::string& symbol) const;

    std::string getStartSymbol() const;
    
    void printGrammar() const;
};

#endif // GRAMMAR_HPP
