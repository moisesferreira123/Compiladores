#ifndef PREDICTIVE_PARSER_HPP
#define PREDICTIVE_PARSER_HPP

#include "HashUtil.hpp"
#include "LL1Table.hpp"
#include <stack>
#include <string>
#include <vector>

class PredictiveParser {
   public:
   PredictiveParser();
   bool predictiveParser();

   private:
   LL1Table table; 
};

#endif // PREDICTIVE_PARSER_HPP
