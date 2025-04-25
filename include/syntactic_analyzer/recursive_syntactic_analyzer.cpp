#include <iostream>
#include <cctype>
#include <cstdlib>
#include <string>

using namespace std;

//class recursiveSyntacticAnalyzer {
  char lookahead;
  string input;
  int indexInput = 0;

  void error() {
    cerr << "Erro de sintaxe!\n";
    exit(1); 
  }

  void match(char expected) {
    if(lookahead == expected) {
      indexInput++;
      if(indexInput < input.size()) lookahead = input[indexInput];
      while(lookahead == ' ') {
        indexInput++;
        if(indexInput < input.size()) lookahead = input[indexInput];
      }
    } else {
      error();
    }
  }

  void EXP();
  void EXP_();
  void TERM();
  void TERM_();
  void POW();
  void POW_();
  void FACT();

  void FACT() {
    if(lookahead == '(') {
      match('(');
      EXP();
      match(')');
    } else if(isalpha(lookahead)) {
      match('i');
      match('d');
    } else {
      error();
    }
  }

  void POW_() {
    if(lookahead == '^') {
      match('^');
      POW();
    }
  }

  void POW() {
    FACT();
    POW_();
  }

  void TERM_() {
    if(lookahead == '*') {
      match('*');
      POW();
      TERM_();
    } else if(lookahead == '/') {
      match('/');
      POW();
      TERM_();
    }
  }

  void TERM() {
    POW();
    TERM_();
  }

  void EXP_() {
    if(lookahead == '+') {
      match('+');
      TERM();
      EXP_();
    } else if(lookahead == '-') {
      match('-');
      TERM();
      EXP_();
    }
  }

  void EXP(){
    TERM();
    EXP_();
  }
//};

int main() {

  cin >> input;
  lookahead = input[indexInput];
  while(lookahead == ' ') {
    indexInput++;
    lookahead = input[indexInput];
  }

  EXP();

  if (indexInput == input.size()) {
      cout << "Expressão válida!" << endl;
  } else {
    cout << "aqui\n";
    error();
  }

  return 0;
}