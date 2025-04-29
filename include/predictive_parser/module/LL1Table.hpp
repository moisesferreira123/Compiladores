#ifndef LL1TABLE_HPP
#define LL1TABLE_HPP

#include "Grammar.hpp"
#include "FirstFollowCalculator.hpp"
#include "../../mapper/Mapper.hpp"
#include <unordered_map>
#include <fstream>
#include <iomanip>
const std::string TABLE_FILE_PATH = "output/table.csv";
const std::string PARSING_TABLE_FILE_PATH = "output/parsing_table.csv"; // Caminho do arquivo de tabela de parsing

struct pair_hash {
    template <class T1, class T2>
    std::size_t operator() (const std::pair<T1, T2>& p) const {
        auto h1 = std::hash<T1>{}(p.first);  // Gera o hash para o primeiro elemento do pair
        auto h2 = std::hash<T2>{}(p.second); // Gera o hash para o segundo elemento do pair
        return h1 ^ (h2 << 1); // Combina os dois hashes (fazendo um shift no segundo para evitar colisões)
    }
};


class LL1Table {
public:
    LL1Table();
    
    void buildTable();
    void printTable() const;
    void exportTableToCSV() const;
    const std::unordered_map<std::pair<int, int>, std::vector<int>, pair_hash> getTable() const;
    void exportParsingTableToCSV() const;
    void exportFirstAndFollowToCSV() const;



private:
    Grammar grammar;
    FirstFollowCalculator calculator;
    std::unordered_map<std::pair<std::string, std::string>, const Production*> table; // Tabela LL(1)
    std::unordered_map<std::pair<int, int>, std::vector<int>, pair_hash> parsingTable; // Tabela de parsing
    std::string formatProduction(const Production& production) const;

    bool existsToken(std::unordered_map<std::string, int>::iterator terminalIt, std::string symbol);

};

#endif // LL1TABLE_HPP
