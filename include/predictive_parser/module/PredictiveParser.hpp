#ifndef PREDICTIVE_PARSER_HPP
#define PREDICTIVE_PARSER_HPP

#include "LL1Table.hpp"
#include "HashUtil.hpp"
#include <stack>
#include <string>
#include <vector>


class PredictiveParser {
public:
PredictiveParser(const Grammar& grammar, const LL1Table& table);

    bool predictiveParser(const std::vector<std::string>& tokens);

private:
    const Grammar& grammar;
    const LL1Table& table;
};

#endif // PREDICTIVE_PARSER_HPP
