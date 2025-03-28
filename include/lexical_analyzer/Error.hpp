#ifndef ERROR_HPP
#define ERROR_HPP

#include <iostream>
#include <string>

class Error {
private:
    int line;
    std::string message;

public:
    Error(int line, std::string message) : line(line), message(message) {}

    void what() const {
        std::cout << "Syntax Error at line " << line << ": " << message << std::endl;
    }
};

#endif


