%{
   #include "symbol_table.hpp"
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
%type <type> type var_decl2 exp literal stmt stmt_list stmt_list2
%type <type> return_type return_stmt return_stmt2 var deref_var
%type <type> call_stmt if_stmt if_stmt2 while_stmt ref_var
%type <paramfield> paramfield_decl
%type <paramfield_list> procedure_params procedure_params2 
%type <paramfield_list> record_fields record_fields2
%type <names_list> enum_field
%type <types_list> call_args call_args2

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
         $$ = processVarDecl($4, $5, $2);
         delete $2;
         delete $4;
         delete $5;
      }
      | TOKEN_VAR NAME TOKEN_ATTRIBUTION exp {
         $$ = processVarDecl($4, $2);
         delete $2;
         delete $4;
      }
      ;
   
   var_decl2: 
      TOKEN_ATTRIBUTION exp {
         $$ = $2;
      }
      | {
         $$ = createTypeNull();
      }
   /// TODO: Verificar declarações (erros não estão passando corretamente)
   procedure_decl:
      TOKEN_PROCEDURE NAME {
         symbolTable.enterScope();
      } TOKEN_OPEN_PARENTHESIS procedure_params TOKEN_CLOSE_PARENTHESIS return_type TOKEN_BEGIN scope_declarations stmt_list TOKEN_END {
         $$ = processProcedureDecl($2, $5, $7, $9, $10);

         delete $2;
         for (auto p : *$5) {
            delete p;
         }
         delete $5;
         delete $7;
         delete $10;
      }

   procedure_params:
      paramfield_decl procedure_params2 {
         $2->insert($2->begin(), $1);
         $$ = $2;
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
         $6->push_back(std::string($5));

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
         $$ = processCallStmtToStmt($1);
         delete $1;
      }
      | return_stmt {
         $$ = $1;
      }
      ;

   assign_stmt:
      var TOKEN_ATTRIBUTION exp {
         $$ = processAssignStmt($1, $3);
         delete $1;
         delete $3;
      }
      | deref_var TOKEN_ATTRIBUTION exp {
         $$ = processAssignStmt($1, $3);
         delete $1;
         delete $3;
      }
      ;
   
   if_stmt:
      TOKEN_IF exp TOKEN_THEN stmt_list if_stmt2 TOKEN_FI {
         $$ = processIfStmt($2, $4, $5);
         delete $2;
         delete $4;
         delete $5;
      }
      ;
   
   if_stmt2:
      TOKEN_ELSE stmt_list {
         $$ = $2;
      }
      | {
         $$ = createTypeVoid();
      }
      ;

   while_stmt:
      TOKEN_WHILE exp TOKEN_DO stmt_list TOKEN_OD {
         $$ = processWhileStmt($2, $4);
         delete $2;
         delete $4;
      }
      ;

   call_stmt:
      NAME TOKEN_OPEN_PARENTHESIS call_args TOKEN_CLOSE_PARENTHESIS {
         $$ = processCallStmt($1, $3);

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
         $$ = new std::vector<Type*>();
      }
      ;
   
   call_args2:
      TOKEN_COMMA exp call_args2 {
         $$ = processCallArgs($2, $3);
      }
      | {
         $$ = new std::vector<Type*>();
      }
      ;

   return_stmt:
      TOKEN_RETURN return_stmt2 {
         $$ = $2;
      }
      ;

   return_stmt2:
      exp {
         $$ = $1;
      }
      | {
         $$ = createTypeVoid();
      }
      ;
   
   var:
      NAME {
         $$ = processVar($1);
         delete $1;
      }
      | exp TOKEN_DOT NAME {
         $$ = processVar($1, $3);
         delete $1;
         delete $3;
      }
      ;
   
   ref_var: 
      TOKEN_REF TOKEN_OPEN_PARENTHESIS var TOKEN_CLOSE_PARENTHESIS {
         $$ = createType($3);
      }
      ;


   deref_var:
      TOKEN_DEREF TOKEN_OPEN_PARENTHESIS var TOKEN_CLOSE_PARENTHESIS {
         $$ = processDerefVar($3);
         delete $3;
      }
      | TOKEN_DEREF TOKEN_OPEN_PARENTHESIS deref_var TOKEN_CLOSE_PARENTHESIS {
         $$ = processDerefVar($3);
         delete $3;
      }
      ;

   exp:
      exp TOKEN_AND exp {
         $$ = processExp($1, "&&", $3);
         delete $1;
         delete $3;
      }
      | exp TOKEN_OR exp {
         $$ = processExp($1, "||", $3);
         delete $1;
         delete $3;
      }
      | TOKEN_NOT exp {
         $$ = processExp("not", $2);
         delete $2;
      }
      | exp TOKEN_EQUAL exp {
         $$ = processExp($1, "rel", $3);
         delete $1;
         delete $3;
      }
      | exp TOKEN_DIFF exp {
         $$ = processExp($1, "rel", $3);
         delete $1;
         delete $3;
      }
      | exp TOKEN_LESS exp {
         $$ = processExp($1, "rel", $3);
         delete $1;
         delete $3;
      }
      | exp TOKEN_LESS_EQUAL exp {
         $$ = processExp($1, "rel", $3);
         delete $1;
         delete $3;
      }
      | exp TOKEN_GREATER exp {
         $$ = processExp($1, "rel", $3);
         delete $1;
         delete $3;
      }
      | exp TOKEN_GREATER_EQUAL exp {
         $$ = processExp($1, "rel", $3);
         delete $1;
         delete $3;
      }
      | exp TOKEN_ADD exp {
         $$ = processExp($1, "+", $3);
         delete $1;
         delete $3;
      }
      | exp TOKEN_SUB exp {
         $$ = processExp($1, "-", $3);
         delete $1;
         delete $3;
      }
      | exp TOKEN_MULT exp {
         $$ = processExp($1, "*", $3);
         delete $1;
         delete $3;
      }
      | exp TOKEN_DIV exp {
         $$ = processExp($1, "/", $3);
         delete $1;
         delete $3;
      }
      | exp TOKEN_POT exp {
         $$ = processExp($1, "^", $3);
         delete $1;
         delete $3;
      }
      | literal {
         $$ = $1;
      }
      | call_stmt {
         $$ = $1;
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
         $$ = processExp("-", $2);
         delete $2;
      }
      | TOKEN_NEW NAME {
         $$ = processExp($2);
         delete $2;
      }
      ;

   literal:
      INT_LITERAL {
         $$ = createType(TYPE_INT);
      }
      | FLOAT_LITERAL {
         $$ = createType(TYPE_FLOAT);
      }
      | STRING_LITERAL {
         $$ = createType(TYPE_STRING);
      }
      | TOKEN_TRUE {
         $$ = createType(TYPE_BOOL);
      } 
      | TOKEN_FALSE {
         $$ = createType(TYPE_BOOL);
      }
      | TOKEN_NULL {
         $$ = createTypeNull();
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