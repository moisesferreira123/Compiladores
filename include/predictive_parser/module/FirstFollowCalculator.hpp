#ifndef FIRSTFOLLOWCALCULATOR_HPP
#define FIRSTFOLLOWCALCULATOR_HPP

#include "Grammar.hpp"
#include <unordered_map>
#include <set>
#include <string>
#include <fstream>
#include "HashUtil.hpp"
 


const std::string FILE_PATH_FF = "output/first_follow_table.csv"; // novo caminho único



class FirstFollowCalculator {
    const Grammar& grammar;
    std::unordered_map<std::string, std::set<std::string>> first;
    std::unordered_map<std::string, std::set<std::string>> follow;
    
    
public:
    const std::unordered_map<std::string, std::set<std::string>>& getFirst() const;
    const std::unordered_map<std::string, std::set<std::string>>& getFollow() const;
    
    FirstFollowCalculator(const Grammar& grammar);
    std::set<std::string> computeFirstSequence(const std::vector<std::string>& symbols) const;
    
    void computeFirst();
    void computeFollow();
    void printFirst() const;
    void printFollow() const;
    void exportFirstAndFollowToCSV() const;
    bool firstContainsEpsilon(const std::set<std::string>& firstSet) const;


};

#endif // FIRSTFOLLOWCALCULATOR_HPP
