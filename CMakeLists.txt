cmake_minimum_required(VERSION 3.16.0)
project(compilers VERSION 0.1.0 LANGUAGES C CXX)

include_directories(include)

add_executable(compilers src/main.cpp)

