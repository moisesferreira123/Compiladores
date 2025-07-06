#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <chrono>
#include <ctime>
#include <iostream>
#include <string>

class Logger {
   public:
   static const std::string RESET;
   static const std::string SUCCESS_COLOR;
   static const std::string ERROR_COLOR;
   static const std::string WARNING_COLOR;
   static const std::string INFO_COLOR;
   static const std::string DEBUG_COLOR;

   static std::string getCurrentTimestamp() {
      auto now = std::chrono::system_clock::now();
      auto time_t_now = std::chrono::system_clock::to_time_t(now);
      std::string time_str = std::ctime(&time_t_now);
      time_str.pop_back(); // remove '\n'
      return time_str;
   }

   static void log(std::string level, std::string color, std::string message,
     bool showTimestamp = true) {
      if (!showTimestamp) {
         std::cout << color << "[" << level << "] " << message << RESET
                   << std::endl;
         return;
      }

      std::string timestamp = getCurrentTimestamp();
      std::cout << color << "[" << timestamp << "] [" << level << "] "
                << message << RESET << std::endl;
   }

   // Com linha e coluna
   static void log(std::string level, std::string color, std::string message,
     int line, int column, bool showTimestamp = true) {
      std::string prefix = "linha " + std::to_string(line) + ", coluna "
        + std::to_string(column) + ": ";
      log(level, color, prefix + message, showTimestamp);
   }

   // Métodos padrão
   static void success(std::string message, bool showTimestamp = true) {
      log("SUCCESS", SUCCESS_COLOR, message, showTimestamp);
   }

   static void success(
     std::string message, int line, int column, bool showTimestamp = true) {
      log("SUCCESS", SUCCESS_COLOR, message, line, column, showTimestamp);
   }

   static void error(std::string message, bool showTimestamp = true) {
      log("ERROR", ERROR_COLOR, message, showTimestamp);
   }

   static void error(
     std::string message, int line, int column, bool showTimestamp = true) {
      log("ERROR", ERROR_COLOR, message, line, column, showTimestamp);
   }

   static void warning(std::string message, bool showTimestamp = true) {
      log("WARNING", WARNING_COLOR, message, showTimestamp);
   }

   static void warning(
     std::string message, int line, int column, bool showTimestamp = true) {
      log("WARNING", WARNING_COLOR, message, line, column, showTimestamp);
   }

   static void info(std::string message, bool showTimestamp = true) {
      log("INFO", INFO_COLOR, message, showTimestamp);
   }

   static void info(
     std::string message, int line, int column, bool showTimestamp = true) {
      log("INFO", INFO_COLOR, message, line, column, showTimestamp);
   }

   static void debug(std::string message, bool showTimestamp = true) {
      log("DEBUG", DEBUG_COLOR, message, showTimestamp);
   }

   static void debug(
     std::string message, int line, int column, bool showTimestamp = true) {
      log("DEBUG", DEBUG_COLOR, message, line, column, showTimestamp);
   }
};

#endif // LOGGER_HPP
