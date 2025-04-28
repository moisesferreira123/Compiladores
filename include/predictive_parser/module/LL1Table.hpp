#ifndef LL1TABLE_HPP
#define LL1TABLE_HPP

#include "Grammar.hpp"
#include "FirstFollowCalculator.hpp"
#include <unordered_map>
#include <fstream>
#include <iomanip>

const std::string TABLE_FILE_PATH = "output/table.csv";


class LL1Table {
public:
    LL1Table(const Grammar& grammar, const FirstFollowCalculator& calculator);
    
    void buildTable();
    const std::unordered_map<std::pair<int, int>, std::vector<int>>& getTable() const;
    void printTable() const;
    void exportTableToCSV() const;


private:
    const Grammar& grammar;
    const FirstFollowCalculator& calculator;
    std::unordered_map<std::pair<std::string, std::string>, const Production*> table; // Tabela LL(1)
    std::string formatProduction(const Production& production) const;



};

#endif // LL1TABLE_HPP
