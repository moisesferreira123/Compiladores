cmake_minimum_required(VERSION 3.25.0)
project(flex_bison VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED on)

find_package(FLEX REQUIRED)
find_package(BISON REQUIRED)

add_subdirectory(compiler)