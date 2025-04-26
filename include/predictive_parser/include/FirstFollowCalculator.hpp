#ifndef FIRSTFOLLOWCALCULATOR_HPP
#define FIRSTFOLLOWCALCULATOR_HPP

#include "Grammar.hpp"
#include <map>
#include <set>
#include <string>

class FirstFollowCalculator {
public:
    FirstFollowCalculator(const Grammar& grammar);
    
    void computeFirst();
    void computeFollow();
    
    const std::map<std::string, std::set<std::string>>& getFirst() const;
    const std::map<std::string, std::set<std::string>>& getFollow() const;

    void printFirst() const;
    void printFollow() const;



private:
    const Grammar& grammar;
    std::map<std::string, std::set<std::string>> first;
    std::map<std::string, std::set<std::string>> follow;
    
    void computeFirstForSymbol(const std::string& symbol);
    void computeFollowForSymbol(const std::string& symbol);
};

#endif // FIRSTFOLLOWCALCULATOR_HPP
