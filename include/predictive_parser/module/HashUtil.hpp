#ifndef HASH_UTIL_HPP
#define HASH_UTIL_HPP

#include <string>
#include <utility>  // para std::pair
#include <functional> // para std::hash

namespace std {
    template<>
    struct hash<std::pair<std::string, std::string>> {
        std::size_t operator()(const std::pair<std::string, std::string>& p) const {
            std::hash<std::string> hasher;
            return hasher(p.first) ^ (hasher(p.second) << 1);
        }
    };
}

#endif // HASH_UTIL_HPP
