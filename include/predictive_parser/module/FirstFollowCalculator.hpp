#ifndef FIRSTFOLLOWCALCULATOR_HPP
#define FIRSTFOLLOWCALCULATOR_HPP

#include "Grammar.hpp"
#include <map>
#include <set>
#include <string>
#include <fstream>


static const std::string FIRST_FILE_PATH = "output/first-table.csv"; 
static const std::string FOLLOW_FILE_PATH = "output/follow-table.csv"; 


class FirstFollowCalculator {
    const Grammar& grammar;
    std::map<std::string, std::set<std::string>> first;
    std::map<std::string, std::set<std::string>> follow;
    
    
    public:
    const std::map<std::string, std::set<std::string>>& getFirst() const;
    const std::map<std::string, std::set<std::string>>& getFollow() const;
    
    FirstFollowCalculator(const Grammar& grammar);
    std::set<std::string> computeFirstSequence(const std::vector<std::string>& symbols) const;
    
    void computeFirst();
    void computeFollow();
    void printFirst() const;
    void printFollow() const;
    void exportFirstToCSV() const;
    void exportFollowToCSV() const;

    bool firstContainsEpsilon(const std::set<std::string>& firstSet) const;


};

#endif // FIRSTFOLLOWCALCULATOR_HPP
