#include "symbol_table.hpp"

SymbolTable symbolTable;

/// Inserção das funções bases
void SymbolTable::insertBaseFunctions() {
   /// readint
   {
      std::shared_ptr<Procedure> readint
        = std::make_shared<Procedure>("readint");
      VariableType* procType = new PrimitiveType("int");
      readint->setType(procType);
      symbolTable.insert(readint);
   }

   /// readfloat
   {
      std::shared_ptr<Procedure> readfloat
        = std::make_shared<Procedure>("readfloat");
      VariableType* procType = new PrimitiveType("float");
      readfloat->setType(procType);
      symbolTable.insert(readfloat);
   }

   /// readchar
   {
      std::shared_ptr<Procedure> readchar
        = std::make_shared<Procedure>("readchar");
      VariableType* procType = new PrimitiveType("int");
      readchar->setType(procType);
      symbolTable.insert(readchar);
   }

   /// readstring
   {
      std::shared_ptr<Procedure> readstring
        = std::make_shared<Procedure>("readstring");
      VariableType* procType = new PrimitiveType("string");
      readstring->setType(procType);
      symbolTable.insert(readstring);
   }

   /// readline
   {
      std::shared_ptr<Procedure> readline
        = std::make_shared<Procedure>("readline");
      VariableType* procType = new PrimitiveType("string");
      readline->setType(procType);
      symbolTable.insert(readline);
   }

   /// printint
   {
      std::shared_ptr<Procedure> printint
        = std::make_shared<Procedure>("printint");
      VariableType* procType = new PrimitiveType("void");
      printint->setType(procType);

      /// params
      std::shared_ptr<Variable> i
        = std::make_shared<Variable>("i", new PrimitiveType("int"));

      printint->setParams({ i });
      symbolTable.insert(printint);
   }

   /// printfloat
   {
      std::shared_ptr<Procedure> printfloat
        = std::make_shared<Procedure>("printfloat");
      VariableType* procType = new PrimitiveType("void");
      printfloat->setType(procType);

      /// params
      std::shared_ptr<Variable> f
        = std::make_shared<Variable>("f", new PrimitiveType("float"));

      printfloat->setParams({ f });
      symbolTable.insert(printfloat);
   }

   /// printline
   {
      std::shared_ptr<Procedure> printstr
        = std::make_shared<Procedure>("printstr");
      VariableType* procType = new PrimitiveType("void");
      printstr->setType(procType);

      /// params
      std::shared_ptr<Variable> s
        = std::make_shared<Variable>("s", new PrimitiveType("string"));

      printstr->setParams({ s });
      symbolTable.insert(printstr);
   }

   /// printline
   {
      std::shared_ptr<Procedure> printline
        = std::make_shared<Procedure>("printline");
      VariableType* procType = new PrimitiveType("void");
      printline->setType(procType);

      /// params
      std::shared_ptr<Variable> s
        = std::make_shared<Variable>("s", new PrimitiveType("string"));

      printline->setParams({ s });
      symbolTable.insert(printline);
   }
}