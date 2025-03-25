#ifndef SYMBOL_HPP_
#define SYMBOL_HPP_

#include <cstdint>
#include <string>

struct Symbol {
  std::string type;
  std::uintptr_t address;

  Symbol() {}
  Symbol(std::string const &type, std::uintptr_t address)
      : type(type), address(address) {}
};

#endif // !SYMBOL_HPP_