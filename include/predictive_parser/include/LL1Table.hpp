#ifndef LL1TABLE_HPP
#define LL1TABLE_HPP

#include "Grammar.hpp"
#include "FirstFollowCalculator.hpp"
#include <map>

class LL1Table {
public:
    LL1Table(const Grammar& grammar, const FirstFollowCalculator& calculator);
    
    void buildTable();
    const std::map<std::pair<std::string, std::string>, std::vector<std::string>>& getTable() const;

private:
    const Grammar& grammar;
    const FirstFollowCalculator& calculator;
    std::map<std::pair<std::string, std::string>, std::vector<std::string>> table;
};

#endif // LL1TABLE_HPP
