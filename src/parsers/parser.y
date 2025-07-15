%{
   #include "symbol_table.hpp"
   #include "tac/codegen.hpp"
   #include "tac/tac.hpp"

   extern CodeEmitter emitter;
%}

%code requires {
   #include "utils.hpp"
}

%union {
   int int_value;
   float float_value;
   char* name_value;
   char* string_value;
   bool ok;
   Type* type;
   TacOperand* tac_operand; // Antigo ExpResult
   std::vector<TacOperand*>* tac_operand_list;
   Paramfield* paramfield;
   std::vector<Paramfield*>* paramfield_list;
   std::vector<Type*>* types_list;
   std::vector<std::string>* names_list;
}

/// TOKENS
%token <int_value> INT_LITERAL
%token <float_value> FLOAT_LITERAL
%token <string_value> STRING_LITERAL
%token <name_value> NAME
%token TOKEN_BOOL TOKEN_PROGRAM TOKEN_PROCEDURE
%token TOKEN_BEGIN TOKEN_END TOKEN_VAR TOKEN_IN TOKEN_STRUCT  TOKEN_NULL
%token TOKEN_NEW TOKEN_REF TOKEN_DEREF TOKEN_TRUE TOKEN_FALSE TOKEN_IF TOKEN_THEN
%token TOKEN_ELSE TOKEN_FI TOKEN_WHILE TOKEN_DO TOKEN_OD TOKEN_RETURN TOKEN_ENUM
%token TOKEN_ATTRIBUTION TOKEN_COLON TOKEN_OPEN_PARENTHESIS TOKEN_OF
%token TOKEN_CLOSE_PARENTHESIS TOKEN_SEMICOLON TOKEN_COMMA TOKEN_OPEN_BRACES
%token TOKEN_CLOSE_BRACES TOKEN_CIPHER TOKEN_ERROR
%token TOKEN_INT TOKEN_FLOAT TOKEN_STRING

/// PRECEDÊNCIA
%left TOKEN_OR
%left TOKEN_AND
%right TOKEN_NOT
%nonassoc TOKEN_LESS TOKEN_LESS_EQUAL TOKEN_GREATER TOKEN_GREATER_EQUAL TOKEN_DIFF TOKEN_EQUAL
%left TOKEN_ADD TOKEN_SUB
%left TOKEN_MULT TOKEN_DIV
%right TOKEN_POT
%left TOKEN_DOT
%right UMINUS

/// Associação dos tipos
%type <ok> program decl_block decl_block2 decl  
%type <ok> var_decl procedure_decl record_decl enum_decl
%type <ok> scope_declarations assign_stmt
%type <type> type stmt stmt_list stmt_list2
%type <type> return_type return_stmt  
%type <type> if_stmt if_stmt2 while_stmt 
%type <paramfield> paramfield_decl
%type <paramfield_list> procedure_params procedure_params2 
%type <paramfield_list> record_fields record_fields2
%type <names_list> enum_field
%type <tac_operand_list> call_args call_args2

%type <tac_operand>  exp literal var ref_var deref_var var_decl2
%type <tac_operand> call_stmt return_stmt2

/// Regra inicial
%start program

%%
   program:
      TOKEN_PROGRAM NAME {
         symbolTable.insert(std::make_shared<Program>(std::string($2)));
         delete $2;
      } TOKEN_BEGIN decl_block TOKEN_END {
         $$ = $5;
         program_ok = $$;
         processProgram($$);
      }
      ;

   decl_block:
      decl decl_block2 {
         $$ = $1 && $2;
      }
      | {
         $$ = true;
      }
      ;
   
   decl_block2:
      TOKEN_SEMICOLON decl decl_block2 {
         $$ = $2 && $3;
      }
      | {
         $$ = true;
      }
      ;
   
   decl: 
      var_decl {
         $$ = $1;
      }
      | procedure_decl {
         $$ = $1;
      }
      | record_decl {
         $$ = $1;
      }
      | enum_decl {
         $$ = $1;
      }
      ;
   
   var_decl:
      TOKEN_VAR NAME TOKEN_COLON type var_decl2 {
         $$ = processVarDecl($4, $5->type, $2);

         if ($$) {
            std::string varName = getUniqueName($2);
            std::string tacType = getTacType($4);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_VAR_DECL, varName));

            Type* varDecl2Type = $5->type;
            if (!isNullKind(varDecl2Type->kind)) {
               emitter.emit(OpCode::TAC_ASSIGN, varName, $5->loc);
            }
         }

         delete $2;
         delete $4;
         delete $5;
      }
      | TOKEN_VAR NAME TOKEN_ATTRIBUTION exp {
         $$ = processVarDecl($4->type, $2);

         if ($$) {
            Type* expType = $4->type;
            std::string varName = getUniqueName($2);
            std::string tacType = getTacType(expType);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_VAR_DECL, varName));
            emitter.emit(OpCode::TAC_ASSIGN, varName, $4->loc);
         }

         delete $2;
         delete $4;
      }
      ;
   
   var_decl2: 
      TOKEN_ATTRIBUTION exp {
         $$ = $2;
      }
      | {
         $$ = new TacOperand{createTypeNull(), ""};
      }

   procedure_decl:
      TOKEN_PROCEDURE NAME {
         emitter.emitProcedureBegin($2);
         symbolTable.enterScope();
      } TOKEN_OPEN_PARENTHESIS procedure_params TOKEN_CLOSE_PARENTHESIS return_type {
         if (!isErrorType($7) && !isVoidKind($7->kind)) {
            emitter.emit(OpCode::TAC_PROCEDURE_RETURN, getTacType($7), std::to_string(symbolTable.getScopes()));
         }
      } TOKEN_BEGIN scope_declarations stmt_list TOKEN_END {
         $$ = processProcedureDecl($2, $5, $7, $10, $11);
         emitter.emitProcedureEnd();

         delete $2;
         for (auto p : *$5) {
            delete p;
         }
         delete $5;
         delete $7;
         delete $11;
      }

   procedure_params:
      paramfield_decl procedure_params2 {
         $2->insert($2->begin(), $1);
         $$ = $2;
         emitter.emitProcedureParams($$);
      }
      | {
         $$ = new std::vector<Paramfield*>();
      }
      ;

   procedure_params2: 
      TOKEN_COMMA paramfield_decl procedure_params2 {
         $3->insert($3->begin(), $2);
         $$ = $3;
      }
      | {
         $$ = new std::vector<Paramfield*>();
      }
      ;


   paramfield_decl:
      NAME TOKEN_COLON type {
         $$ = new Paramfield { std::string($1), $3 };
         processParamfieldDecl($$);
         delete $1;
      }
      ;

   return_type:
      TOKEN_COLON type {
         $$ = $2;
      }
      | {
         $$ = createTypeVoid();
      }
      ;

   record_decl:
      TOKEN_STRUCT NAME {
         symbolTable.enterScope();
      } TOKEN_OPEN_BRACES record_fields TOKEN_CLOSE_BRACES {
         $$ = processRecordDecl($2, $5);

         if ($$) {
            emitter.emit(OpCode::TAC_STRUCT_DECL, "");

            std::shared_ptr<Symbol>symbol = symbolTable.lookup($2);

            if (std::shared_ptr<Struct> structSymbol = std::dynamic_pointer_cast<Struct>(symbol)) {
               std::vector<std::shared_ptr<Variable>> const& fields = structSymbol->getFields();
               for (auto const& var : fields) {
                  std::string varName = var->getName() + "_" + std::to_string(var->getScopeId());
                  Type* varType = createType(var->getType());
                  std::string tacType = getTacType(varType);
                  emitter.emit(TAC_Instruction(tacType, OpCode::TAC_VAR_DECL, varName));
                  delete varType;
               }
            }

            std::string structName = getUniqueName($2);
            emitter.emit(OpCode::TAC_STRUCT_DECL_CLOSE, structName);
         }

         
         delete $2;
         for (auto p : *$5) {
            delete p;
         }
         delete $5;
      }
      ;

   
   record_fields:
      paramfield_decl record_fields2 {
         $2->insert($2->begin(), $1);
         $$ = $2;
      }
      | {
         $$ = new std::vector<Paramfield*>();
      }
      ;

   record_fields2:
      TOKEN_SEMICOLON paramfield_decl record_fields2 {
         $3->insert($3->begin(), $2);
         $$ = $3;
      }
      | {
         $$ = new std::vector<Paramfield*>();
      }
      ;

   enum_decl:
      TOKEN_ENUM NAME TOKEN_EQUAL TOKEN_OPEN_BRACES NAME enum_field TOKEN_CLOSE_BRACES {
         $6->insert($6->begin(), std::string($5));

         $$ = processEnumDecl($2, $6);

         delete $2;
         delete $5;
         delete $6;
      }
      ;
   
   enum_field:
      TOKEN_COMMA NAME enum_field {
         $3->insert($3->begin(), std::string($2));
         $$ = $3;
         delete $2;
      }
      | {
         $$ = new std::vector<std::string>();
      }

   scope_declarations:
      decl_block TOKEN_IN {
         $$ = $1;
      }
      | {
         $$ = true;
      }
      ;

   stmt_list:
      stmt stmt_list2 {
         $$ = processStmtList($1, $2);
         delete $1;
         delete $2;
      }
      | {
         $$ = createTypeVoid();
      }
      ;
   
   stmt_list2:
      TOKEN_SEMICOLON stmt stmt_list2 {
         $$ = processStmtList($2, $3);
         delete $2;
         delete $3;
      }
      | {
         $$ = createTypeVoid();
      }
      ;
   
   stmt:
      assign_stmt {
         $$ = processAssignStmtToStmt($1);
      }
      | if_stmt {
         $$ = $1;
      }
      | while_stmt {
         $$ = $1;
      }
      | call_stmt {
         $$ = processCallStmtToStmt($1->type);
         delete $1;
      }
      | return_stmt {
         $$ = $1;
      }
      ;

   assign_stmt:
      var TOKEN_ATTRIBUTION exp {
         bool ok = processAssignStmt($1->type, $3->type);
         
         if(ok){
            emitter.emit(OpCode::TAC_ASSIGN, $1->loc, $3->loc);
            delete $1;
            delete $3;
         }

         $$ = ok;
      }
      | deref_var TOKEN_ATTRIBUTION exp {
         bool ok = processAssignStmt($1->type, $3->type);

         if(ok){
            emitter.emit(OpCode::TAC_DEREF_ASSIGN, $1->loc, $3->loc);
         }

         $$ = ok;
         delete $1;
         delete $3;
      }
      ;
   
   if_stmt:
      TOKEN_IF exp {
         std::string false_label = new_label();
         emitter.emit(OpCode::TAC_IF_FALSE_GOTO, false_label, $2->loc);
         label_stack.push_back(false_label);

      }TOKEN_THEN stmt_list if_stmt2 TOKEN_FI {
         $$ = processIfStmt($2->type, $5, $6);
         delete $2;
         delete $5;
         if ($6 != nullptr && $6 != createTypeVoid()) {
            delete $6;
         }
      }
      ;
   
   if_stmt2:
      TOKEN_ELSE {
         std::string end_label = new_label();
         emitter.emit(OpCode::TAC_GOTO, end_label);

         std::string false_label = label_stack.back();
         label_stack.pop_back();

         emitter.emit(OpCode::TAC_LABEL, false_label);
         label_stack.push_back(end_label);

      } stmt_list {
         std::string end_label = label_stack.back(); label_stack.pop_back();
         emitter.emit(OpCode::TAC_LABEL, end_label);
         $$ = $3;
      } 
      | {
         std::string end_label = label_stack.back(); label_stack.pop_back();
         emitter.emit(OpCode::TAC_LABEL, end_label);
         $$ = createTypeVoid();
      }
      ;

   while_stmt:
      TOKEN_WHILE {
         std::string begin_label = new_label();
         emitter.emit(OpCode::TAC_LABEL, begin_label);
         label_stack.push_back(begin_label);

      } exp {
         Type* exp_type = $3->type;
         if (!isErrorType(exp_type)) {
            std::string end_label = new_label();
            emitter.emit(OpCode::TAC_IF_FALSE_GOTO, end_label, $3->loc);
            label_stack.push_back(end_label);  
         }

      } TOKEN_DO stmt_list {
         std::string label_end = label_stack.back(); label_stack.pop_back();
         std::string label_begin = label_stack.back(); label_stack.pop_back();

         emitter.emit(OpCode::TAC_GOTO, label_begin);
         emitter.emit(OpCode::TAC_LABEL, label_end);

      } TOKEN_OD{
         $$ = processWhileStmt($3->type, $6);
         delete $3;
         delete $6;

      } 
      ;

   call_stmt:
      NAME TOKEN_OPEN_PARENTHESIS call_args TOKEN_CLOSE_PARENTHESIS {
         $$ = processCallStmt($1, $3);
         $$->loc = new_temp();
         emitter.emitCallStmt($1, $3, $$->loc);

         delete $1;
         for (auto arg : *$3) {
            delete arg;
         }
         delete $3;
      }
      ;
   
   call_args: 
      exp call_args2 {
         $$ = processCallArgs($1, $2);
      }
      | {
         $$ = new std::vector<TacOperand*>();
      }
      ;
   
   call_args2:
      TOKEN_COMMA exp call_args2 {
         $$ = processCallArgs($2, $3);
      }
      | {
         $$ = new std::vector<TacOperand*>();
      }
      ;

   return_stmt:
      TOKEN_RETURN return_stmt2 {
         Type* type = $2->type;
         if (!isErrorType(type) && !isVoidKind(type->kind)) {
            emitter.emit(OpCode::TAC_RETURN_VALUE, $2->loc, std::to_string(symbolTable.getScopes()));
         } else if (isVoidKind(type->kind)) {
            emitter.emit(OpCode::TAC_RETURN_VOID, "");
         }

         $$ = type;
      }
      ;

   return_stmt2:
      exp {
         $$ = $1;
      }
      | {
         $$ = new TacOperand{createTypeVoid(), ""};
      }
      ;
   
   var:
      NAME {
         Type* type = processVar($1);
         $$ = new TacOperand{type, getUniqueName($1)};
         delete $1;
      }
      | exp TOKEN_DOT NAME {
         Type* field_type = processVar($1->type, $3);
         std::string name = "";

         if (!isErrorType(field_type)) {
            Type* type = $1->type;
            if ($1->type->kind == TYPE_STRUCT) {
               std::shared_ptr<Struct> record = std::dynamic_pointer_cast<Struct>(type->structured);
               std::string field_name = "";
               
               for (std::shared_ptr<Variable> field : record->getFields()) {
                  if (field->getName() == $3) {
                     field_name = field->getName() + "_" + std::to_string(field->getScopeId());
                     break;
                  }
               }
               name = $1->loc + "." + field_name;
            } else if (type->kind == TYPE_ENUM) {
               std::shared_ptr<Enum> enumerate = std::dynamic_pointer_cast<Enum>(type->structured);
               std::vector<std::string> enumValues = enumerate->getValues();
               
               for (int i = 0; i < enumValues.size(); i++) {
                  if (enumValues[i] == $3) {
                     name = std::to_string(i);
                     break;
                  }
               }
            }
         }
         
         $$ = new TacOperand{field_type, name};
         delete $1;
         delete $3;
      }
      ;
   
   ref_var: 
      TOKEN_REF TOKEN_OPEN_PARENTHESIS var TOKEN_CLOSE_PARENTHESIS {
         Type* pointer_type = createType($3->type);

         std::string loc = "&" + $3->loc;

         $$ = new TacOperand{pointer_type, loc};
         delete $3;
      }
      ;


   deref_var:
      TOKEN_DEREF TOKEN_OPEN_PARENTHESIS var TOKEN_CLOSE_PARENTHESIS {
         Type* type = processDerefVar($3->type);
         std::string loc = "*" + $3->loc;

         $$ = new TacOperand{type, loc};
         delete $3;
      }
      | TOKEN_DEREF TOKEN_OPEN_PARENTHESIS deref_var TOKEN_CLOSE_PARENTHESIS {
         std::string loc = "*" + $3->loc;

         Type* type = processDerefVar($3->type);

         $$ = new TacOperand{type, loc};
         delete $3;
      }
      ;

   exp:
      exp TOKEN_AND exp {
         Type* type = processExp($1->type, "&&", $3->type);
         std::string temp = new_temp();
         
         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_AND, temp, $1->loc, $3->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | exp TOKEN_OR exp {
         Type* type = processExp($1->type, "||", $3->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_OR, temp, $1->loc, $3->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | TOKEN_NOT exp {
         Type* type = processExp("not", $2->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_NOT, temp, $2->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $2;
      }
      | exp TOKEN_EQUAL exp {
         Type* type = processExp($1->type, "rel", $3->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_EQ, temp, $1->loc, $3->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | exp TOKEN_DIFF exp {
         Type* type = processExp($1->type, "rel", $3->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_NEQ, temp, $1->loc, $3->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | exp TOKEN_LESS exp {
         Type* type = processExp($1->type, "rel", $3->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_LT, temp, $1->loc, $3->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | exp TOKEN_LESS_EQUAL exp {
         Type* type = processExp($1->type, "rel", $3->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_LE, temp, $1->loc, $3->loc));
         }
         
         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | exp TOKEN_GREATER exp {
         Type* type = processExp($1->type, "rel", $3->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_GT, temp, $1->loc, $3->loc));
         }
         
         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | exp TOKEN_GREATER_EQUAL exp {
         Type* type = processExp($1->type, "rel", $3->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_GE, temp, $1->loc, $3->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | exp TOKEN_ADD exp {
         Type* type = processExp($1->type, "+", $3->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_ADD, temp, $1->loc, $3->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | exp TOKEN_SUB exp {
         Type* type = processExp($1->type, "-", $3->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_SUB, temp, $1->loc, $3->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | exp TOKEN_MULT exp {
         Type* type = processExp($1->type, "*", $3->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_MULT, temp, $1->loc, $3->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | exp TOKEN_DIV exp {
         Type* type = processExp($1->type, "/", $3->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_DIV, temp, $1->loc, $3->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | exp TOKEN_POT exp {
         Type* type = processExp($1->type, "^", $3->type);
         std::string temp = new_temp();

         if (!isErrorType(type)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_POT, temp, $1->loc, $3->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $1;
         delete $3;
      }
      | literal {
         $$ = $1;
      }
      | call_stmt {
         Type* type = $1->type;
         std::string temp = new_temp();

         if (!isErrorType(type) && !isVoidKind(type->kind)) {
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_VAR_DECL, temp));
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_ASSIGN, temp, $1->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $1;
      }
      | var {
         $$ = $1;
      }
      | ref_var {
         $$ = $1;
      }
      | deref_var {
         $$ = $1;
      }
      | TOKEN_OPEN_PARENTHESIS exp TOKEN_CLOSE_PARENTHESIS {
         $$ = $2;
      }
      | TOKEN_SUB exp %prec UMINUS {
         Type* type = processExp("-", $2->type);
         std::string temp = new_temp();

         if(!isErrorType(type)){
            std::string tacType = getTacType(type);
            emitter.emit(TAC_Instruction(tacType, OpCode::TAC_UNARY_MINUS, temp, $2->loc));
         }

         $$ = new TacOperand{type, temp};
         delete $2;
      }
      | TOKEN_NEW NAME {
         Type* type = processExp($2);
         std::string temp = new_temp();

         if(!isErrorType(type)){
            std::string uniqueName = getUniqueName($2);
            emitter.emit(TAC_Instruction(uniqueName, OpCode::TAC_NEW, temp, uniqueName));
         }

         $$ = new TacOperand{type, temp};
         delete $2;
      }
      ;

   literal:
      INT_LITERAL {
         $$ = new TacOperand{createType(TYPE_INT), std::to_string($1)};
      }
      | FLOAT_LITERAL {
         $$ = new TacOperand{createType(TYPE_FLOAT), std::to_string($1)};
      }
      | STRING_LITERAL {
         $$ = new TacOperand{createType(TYPE_STRING), $1};
      }
      | TOKEN_TRUE {
         $$ = new TacOperand{createType(TYPE_BOOL), "true"};
      } 
      | TOKEN_FALSE {
         $$ = new TacOperand{createType(TYPE_BOOL), "false"};
      }
      | TOKEN_NULL {
         $$ = new TacOperand{createTypeNull(), "null"};
      }
      ;

   type:
      TOKEN_INT {
         $$ = createType(TYPE_INT);
      }
      | TOKEN_FLOAT {
         $$ = createType(TYPE_FLOAT);
      }
      | TOKEN_STRING {
         $$ = createType(TYPE_STRING);
      }
      | TOKEN_BOOL {
         $$ = createType(TYPE_BOOL);
      }
      | NAME {
         $$ = processTypeName($1);
         delete $1;
      }
      | TOKEN_REF TOKEN_OPEN_PARENTHESIS type TOKEN_CLOSE_PARENTHESIS {
         $$ = createType($3);
      }
      ;
%%