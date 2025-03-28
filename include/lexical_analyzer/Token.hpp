#ifndef TOKEN_HPP
#define TOKEN_HPP

#include <iostream>
#include <string>
#include <cctype>
#include <sstream>
#include "Error.hpp"

enum Tag{
    NUM = 256,
    ID,
    TRUE,
    FALSE,
    REL,
    OR,
    AND,
    NOT,
    EQ,
    NE,
    LE,
    GE,
    MINUS,
    IF,
    ELSE,
    WHILE,
    DO,
    BREAK,
    SEQ,
    EXPR,
    TEMP,
    TEMPORARY
};

struct Token{
    
    int tag;
    Token() : tag(0) {}
    Token(int t) : tag(t) {}

    virtual std::string toString() {
        std::stringstream ss; 
        ss << (char)tag; 
        return ss.str();
    }
};

struct Num : public Token{
    int value;
    Num() : Token(Tag::NUM), value(0) {}

    Num(int v) : Token(Tag::NUM), value(v) {}

    std::string toString() {
        std::stringstream ss; 
        ss << value; 
        return ss.str();
    }
};

struct  Id : public Token{
    std::string lexeme;
    Id() : Token(Tag::ID), lexeme("") {}

    Id(std::string s) : Token(Tag::ID), lexeme(s) {}

    std::string toString() {
        return lexeme;
    }
};

#endif