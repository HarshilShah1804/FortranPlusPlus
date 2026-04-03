%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "derivation_tree.h"

void yyerror(const char *s);
int yylex();

#define NODE(name, count, ...) dt_make_node((name), (count), __VA_ARGS__)
#define NODE0(name) dt_make_node((name), 0)
#define LEAF(name) dt_make_leaf((name))

%}

%union {
  struct DerivationNode *node;
}

%token PROGRAM MODULE END CONTAINS USE NONE IMPLICIT
%token INTEGER REAL LOGICAL CHARACTER TYPE CLASS END_TYPE COMPLEX
%token IF THEN ELSE DO ENDIF LEN INTRINSIC WHILE SELECT CASE DEFAULT RANK
%token STOP PRINT CALL SUBROUTINE FUNCTION RETURN RECURSIVE RESULT
%token ALLOCATE DEALLOCATE ALLOCATED POINTER TARGET ALLOCATABLE INTENT IN OUT INOUT
%token OPEN CLOSE INQUIRE WRITE READ ERROR
%token LPAREN RPAREN COMMA COLON ASSUMED_RANK_SPECIFIER CONCAT PTR_ASSIGN
%token PP_DEFINE PP_UNDEF PP_IFDEF PP_IFNDEF PP_IF PP_ELIF PP_ELSE PP_ENDIF
%token LENGTH_SPECIFIER

%token IDENTIFIER INT_CONST REAL_CONST STRING LOGICAL_CONST
%token ARITH_OP REL_OP LOGICAL_OP ASSIGN EXPONENT DECL_SEP DERIVED_TYPE_COMPONENT

%type <node> start compilation_units compilation_unit free_form program_unit module_unit
%type <node> program_body module_body contains_block declarations preamble pp_item
%type <node> declaration type_spec char_type_spec char_len_opt char_len_value
%type <node> attributes attribute declaration_attributes identifier_list declarator_list
%type <node> declarator array_spec_opt array_spec array_spec_list array_spec_item init_opt
%type <node> executables executable assignment_stmt if_stmt do_stmt dowhile_stmt select_stmt
%type <node> select_rank_stmt rank_blocks rank_block rank_selector case_blocks case_block
%type <node> call_stmt callable_name return_stmt stop_stmt pointer_stmt step_opt print_stmt
%type <node> print_args allocate_stmt deallocate_stmt expression factor primary complex_literal
%type <node> primary_suffix_opt variable_ref subprogram_list subprogram argument_list
%type <node> identifier_list_opt identifier type_def type_def_body type_def_declarations
%type <node> type_def_declaration pp_define_undef pp_if_block pp_else_opt

%left LOGICAL_OP
%nonassoc REL_OP
%left ARITH_OP
%right EXPONENT
%right UNARY
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start: compilation_units
    {
        $$ = NODE("start", 1, $1);
        dt_set_root($$);
    }
  | free_form
    {
        $$ = NODE("start", 1, $1);
        dt_set_root($$);
    }
  ;

compilation_units: compilation_unit
    {
        $$ = NODE("compilation_units", 1, $1);
    }
  | compilation_units compilation_unit
    {
        $$ = NODE("compilation_units", 2, $1, $2);
    }
  ;

compilation_unit: program_unit
    {
        $$ = NODE("compilation_unit", 1, $1);
    }
  | module_unit
    {
        $$ = NODE("compilation_unit", 1, $1);
    }
  ;

free_form: preamble declarations executables
    {
        $$ = NODE("free_form", 3, $1, $2, $3);
    }
  ;

program_unit: PROGRAM IDENTIFIER program_body END PROGRAM IDENTIFIER
    {
        $$ = NODE("program_unit", 6, LEAF("PROGRAM"), LEAF("IDENTIFIER"), $3, LEAF("END"), LEAF("PROGRAM"), LEAF("IDENTIFIER"));
    }
  | PROGRAM IDENTIFIER program_body END PROGRAM
    {
        $$ = NODE("program_unit", 5, LEAF("PROGRAM"), LEAF("IDENTIFIER"), $3, LEAF("END"), LEAF("PROGRAM"));
    }
  ;

module_unit: MODULE IDENTIFIER module_body END MODULE IDENTIFIER
    {
        $$ = NODE("module_unit", 6, LEAF("MODULE"), LEAF("IDENTIFIER"), $3, LEAF("END"), LEAF("MODULE"), LEAF("IDENTIFIER"));
    }
  | MODULE IDENTIFIER module_body END MODULE
    {
        $$ = NODE("module_unit", 5, LEAF("MODULE"), LEAF("IDENTIFIER"), $3, LEAF("END"), LEAF("MODULE"));
    }
  ;

program_body: preamble declarations executables contains_block
    {
        $$ = NODE("program_body", 4, $1, $2, $3, $4);
    }
  ;

module_body: preamble declarations executables contains_block
    {
        $$ = NODE("module_body", 4, $1, $2, $3, $4);
    }
  ;

contains_block: CONTAINS subprogram_list
    {
        $$ = NODE("contains_block", 2, LEAF("CONTAINS"), $2);
    }
  | /* empty */
    {
        $$ = NODE0("contains_block");
    }
  ;

declarations: /* empty */
  {
    $$ = NODE0("declarations");
  }
  | declaration declarations
    {
        $$ = NODE("declarations", 2, $1, $2);
    }
  ;

preamble: /* empty */
  {
    $$ = NODE0("preamble");
  }
  | preamble pp_item
    {
        $$ = NODE("preamble", 2, $1, $2);
    }
  ;

pp_item: pp_define_undef
    {
        $$ = NODE("pp_item", 1, $1);
    }
  | pp_if_block
    {
        $$ = NODE("pp_item", 1, $1);
    }
  ;

declaration: type_spec declaration_attributes DECL_SEP declarator_list
    {
        $$ = NODE("declaration", 4, $1, $2, LEAF("DECL_SEP"), $4);
    }
  | IMPLICIT NONE
    {
        $$ = NODE("declaration", 2, LEAF("IMPLICIT"), LEAF("NONE"));
    }
  | USE identifier
    {
        $$ = NODE("declaration", 2, LEAF("USE"), $2);
    }
  | type_def
    {
        $$ = NODE("declaration", 1, $1);
    }
  ;

type_spec: INTEGER
    {
        $$ = NODE("type_spec", 1, LEAF("INTEGER"));
    }
  | REAL
    {
        $$ = NODE("type_spec", 1, LEAF("REAL"));
    }
  | LOGICAL
    {
        $$ = NODE("type_spec", 1, LEAF("LOGICAL"));
    }
  | char_type_spec
    {
        $$ = NODE("type_spec", 1, $1);
    }
  | TYPE LPAREN identifier RPAREN
    {
        $$ = NODE("type_spec", 4, LEAF("TYPE"), LEAF("LPAREN"), $3, LEAF("RPAREN"));
    }
  | CLASS identifier
    {
        $$ = NODE("type_spec", 2, LEAF("CLASS"), $2);
    }
  | COMPLEX
    {
        $$ = NODE("type_spec", 1, LEAF("COMPLEX"));
    }
  ;

char_type_spec: CHARACTER char_len_opt
    {
        $$ = NODE("char_type_spec", 2, LEAF("CHARACTER"), $2);
    }
  ;

char_len_opt: /* empty */
  {
    $$ = NODE0("char_len_opt");
  }
  | LPAREN LENGTH_SPECIFIER ASSIGN char_len_value RPAREN
    {
        $$ = NODE("char_len_opt", 5, LEAF("LPAREN"), LEAF("LENGTH_SPECIFIER"), LEAF("ASSIGN"), $4, LEAF("RPAREN"));
    }
  ;

char_len_value: COLON
    {
        $$ = NODE("char_len_value", 1, LEAF("COLON"));
    }
  | INT_CONST
    {
        $$ = NODE("char_len_value", 1, LEAF("INT_CONST"));
    }
  | identifier
    {
        $$ = NODE("char_len_value", 1, $1);
    }
  ;

attributes: attribute
    {
        $$ = NODE("attributes", 1, $1);
    }
  | attribute COMMA attributes
    {
        $$ = NODE("attributes", 3, $1, LEAF("COMMA"), $3);
    }
  ;

attribute: ALLOCATABLE
    {
        $$ = NODE("attribute", 1, LEAF("ALLOCATABLE"));
    }
  | POINTER
    {
        $$ = NODE("attribute", 1, LEAF("POINTER"));
    }
  | TARGET
    {
        $$ = NODE("attribute", 1, LEAF("TARGET"));
    }
  | INTENT LPAREN IN RPAREN
    {
        $$ = NODE("attribute", 4, LEAF("INTENT"), LEAF("LPAREN"), LEAF("IN"), LEAF("RPAREN"));
    }
  | INTENT LPAREN OUT RPAREN
    {
        $$ = NODE("attribute", 4, LEAF("INTENT"), LEAF("LPAREN"), LEAF("OUT"), LEAF("RPAREN"));
    }
  | INTENT LPAREN INOUT RPAREN
    {
        $$ = NODE("attribute", 4, LEAF("INTENT"), LEAF("LPAREN"), LEAF("INOUT"), LEAF("RPAREN"));
    }
  ;

declaration_attributes: /* empty */
  {
    $$ = NODE0("declaration_attributes");
  }
  | COMMA attributes
    {
        $$ = NODE("declaration_attributes", 2, LEAF("COMMA"), $2);
    }
  ;

identifier_list: identifier
    {
        $$ = NODE("identifier_list", 1, $1);
    }
  | identifier COMMA identifier_list
    {
        $$ = NODE("identifier_list", 3, $1, LEAF("COMMA"), $3);
    }
  ;

declarator_list: declarator
    {
        $$ = NODE("declarator_list", 1, $1);
    }
  | declarator COMMA declarator_list
    {
        $$ = NODE("declarator_list", 3, $1, LEAF("COMMA"), $3);
    }
  ;

declarator: identifier array_spec_opt init_opt
    {
        $$ = NODE("declarator", 3, $1, $2, $3);
    }
  ;

array_spec_opt: /* empty */
  {
    $$ = NODE0("array_spec_opt");
  }
  | array_spec
    {
        $$ = NODE("array_spec_opt", 1, $1);
    }
  ;

array_spec: LPAREN array_spec_list RPAREN
    {
        $$ = NODE("array_spec", 3, LEAF("LPAREN"), $2, LEAF("RPAREN"));
    }
  ;

array_spec_list: array_spec_item
    {
        $$ = NODE("array_spec_list", 1, $1);
    }
  | array_spec_list COMMA array_spec_item
    {
        $$ = NODE("array_spec_list", 3, $1, LEAF("COMMA"), $3);
    }
  ;

array_spec_item: ASSUMED_RANK_SPECIFIER
    {
        $$ = NODE("array_spec_item", 1, LEAF("ASSUMED_RANK_SPECIFIER"));
    }
  | COLON
    {
        $$ = NODE("array_spec_item", 1, LEAF("COLON"));
    }
  | expression
    {
        $$ = NODE("array_spec_item", 1, $1);
    }
  | expression COLON
    {
        $$ = NODE("array_spec_item", 2, $1, LEAF("COLON"));
    }
  | COLON expression
    {
        $$ = NODE("array_spec_item", 2, LEAF("COLON"), $2);
    }
  | expression COLON expression
    {
        $$ = NODE("array_spec_item", 3, $1, LEAF("COLON"), $3);
    }
  ;

init_opt: /* empty */
  {
    $$ = NODE0("init_opt");
  }
  | ASSIGN expression
    {
        $$ = NODE("init_opt", 2, LEAF("ASSIGN"), $2);
    }
  ;

executables: /* empty */
  {
    $$ = NODE0("executables");
  }
  | executables executable
    {
        $$ = NODE("executables", 2, $1, $2);
    }
  ;

executable: assignment_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  | if_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  | print_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  | allocate_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  | deallocate_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  | do_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  | dowhile_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  | select_rank_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  | select_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  | call_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  | return_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  | stop_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  | pointer_stmt
    {
        $$ = NODE("executable", 1, $1);
    }
  ;

assignment_stmt: variable_ref ASSIGN expression
    {
        $$ = NODE("assignment_stmt", 3, $1, LEAF("ASSIGN"), $3);
    }
  ;

if_stmt: IF LPAREN expression RPAREN THEN executables ENDIF %prec LOWER_THAN_ELSE
    {
        $$ = NODE("if_stmt", 7, LEAF("IF"), LEAF("LPAREN"), $3, LEAF("RPAREN"), LEAF("THEN"), $6, LEAF("ENDIF"));
    }
  | IF LPAREN expression RPAREN THEN executables END IF %prec LOWER_THAN_ELSE
    {
        $$ = NODE("if_stmt", 8, LEAF("IF"), LEAF("LPAREN"), $3, LEAF("RPAREN"), LEAF("THEN"), $6, LEAF("END"), LEAF("IF"));
    }
  | IF LPAREN expression RPAREN THEN executables ELSE executables ENDIF
    {
        $$ = NODE("if_stmt", 9, LEAF("IF"), LEAF("LPAREN"), $3, LEAF("RPAREN"), LEAF("THEN"), $6, LEAF("ELSE"), $8, LEAF("ENDIF"));
    }
  | IF LPAREN expression RPAREN THEN executables ELSE executables END IF
    {
        $$ = NODE("if_stmt", 10, LEAF("IF"), LEAF("LPAREN"), $3, LEAF("RPAREN"), LEAF("THEN"), $6, LEAF("ELSE"), $8, LEAF("END"), LEAF("IF"));
    }
  ;

do_stmt: DO IDENTIFIER ASSIGN expression COMMA expression step_opt executables END DO
    {
        $$ = NODE("do_stmt", 10, LEAF("DO"), LEAF("IDENTIFIER"), LEAF("ASSIGN"), $4, LEAF("COMMA"), $6, $7, $8, LEAF("END"), LEAF("DO"));
    }
  ;

dowhile_stmt: DO WHILE LPAREN expression RPAREN executables END DO
    {
        $$ = NODE("dowhile_stmt", 8, LEAF("DO"), LEAF("WHILE"), LEAF("LPAREN"), $4, LEAF("RPAREN"), $6, LEAF("END"), LEAF("DO"));
    }
  ;

select_stmt: SELECT CASE LPAREN expression RPAREN case_blocks END SELECT
    {
        $$ = NODE("select_stmt", 8, LEAF("SELECT"), LEAF("CASE"), LEAF("LPAREN"), $4, LEAF("RPAREN"), $6, LEAF("END"), LEAF("SELECT"));
    }
  ;

select_rank_stmt: SELECT RANK LPAREN identifier RPAREN rank_blocks END SELECT
    {
        $$ = NODE("select_rank_stmt", 8, LEAF("SELECT"), LEAF("RANK"), LEAF("LPAREN"), $4, LEAF("RPAREN"), $6, LEAF("END"), LEAF("SELECT"));
    }
  ;

rank_blocks: rank_block
    {
        $$ = NODE("rank_blocks", 1, $1);
    }
  | rank_blocks rank_block
    {
        $$ = NODE("rank_blocks", 2, $1, $2);
    }
  ;

rank_block: RANK LPAREN rank_selector RPAREN executables
    {
        $$ = NODE("rank_block", 5, LEAF("RANK"), LEAF("LPAREN"), $3, LEAF("RPAREN"), $5);
    }
  | RANK DEFAULT executables
    {
        $$ = NODE("rank_block", 3, LEAF("RANK"), LEAF("DEFAULT"), $3);
    }
  ;

rank_selector: INT_CONST
    {
        $$ = NODE("rank_selector", 1, LEAF("INT_CONST"));
    }
  | ARITH_OP
    {
        $$ = NODE("rank_selector", 1, LEAF("ARITH_OP"));
    }
  ;

case_blocks: case_block
    {
        $$ = NODE("case_blocks", 1, $1);
    }
  | case_blocks case_block
    {
        $$ = NODE("case_blocks", 2, $1, $2);
    }
  ;

case_block: CASE LPAREN expression RPAREN executables
    {
        $$ = NODE("case_block", 5, LEAF("CASE"), LEAF("LPAREN"), $3, LEAF("RPAREN"), $5);
    }
  | CASE DEFAULT executables
    {
        $$ = NODE("case_block", 3, LEAF("CASE"), LEAF("DEFAULT"), $3);
    }
  ;

call_stmt: CALL callable_name LPAREN argument_list RPAREN
    {
        $$ = NODE("call_stmt", 5, LEAF("CALL"), $2, LEAF("LPAREN"), $4, LEAF("RPAREN"));
    }
  ;

callable_name: identifier
    {
        $$ = NODE("callable_name", 1, $1);
    }
  | INTRINSIC
    {
        $$ = NODE("callable_name", 1, LEAF("INTRINSIC"));
    }
  ;

return_stmt: RETURN
    {
        $$ = NODE("return_stmt", 1, LEAF("RETURN"));
    }
  ;

stop_stmt: STOP
    {
        $$ = NODE("stop_stmt", 1, LEAF("STOP"));
    }
  | STOP INT_CONST
    {
        $$ = NODE("stop_stmt", 2, LEAF("STOP"), LEAF("INT_CONST"));
    }
  | STOP STRING
    {
        $$ = NODE("stop_stmt", 2, LEAF("STOP"), LEAF("STRING"));
    }
  ;

pointer_stmt: variable_ref PTR_ASSIGN variable_ref
    {
        $$ = NODE("pointer_stmt", 3, $1, LEAF("PTR_ASSIGN"), $3);
    }
  ;

step_opt: /* empty */
  {
    $$ = NODE0("step_opt");
  }
  | COMMA expression
    {
        $$ = NODE("step_opt", 2, LEAF("COMMA"), $2);
    }
  ;

print_stmt: PRINT ARITH_OP COMMA print_args
    {
        $$ = NODE("print_stmt", 4, LEAF("PRINT"), LEAF("ARITH_OP"), LEAF("COMMA"), $4);
    }
  ;

print_args: expression
    {
        $$ = NODE("print_args", 1, $1);
    }
  | print_args COMMA expression
    {
        $$ = NODE("print_args", 3, $1, LEAF("COMMA"), $3);
    }
  ;

allocate_stmt: ALLOCATE LPAREN argument_list RPAREN
    {
        $$ = NODE("allocate_stmt", 4, LEAF("ALLOCATE"), LEAF("LPAREN"), $3, LEAF("RPAREN"));
    }
  ;

deallocate_stmt: DEALLOCATE LPAREN argument_list RPAREN
    {
        $$ = NODE("deallocate_stmt", 4, LEAF("DEALLOCATE"), LEAF("LPAREN"), $3, LEAF("RPAREN"));
    }
  ;

expression: expression ARITH_OP expression
    {
        $$ = NODE("expression", 3, $1, LEAF("ARITH_OP"), $3);
    }
  | expression EXPONENT expression
    {
        $$ = NODE("expression", 3, $1, LEAF("EXPONENT"), $3);
    }
  | expression REL_OP expression
    {
        $$ = NODE("expression", 3, $1, LEAF("REL_OP"), $3);
    }
  | expression LOGICAL_OP expression
    {
        $$ = NODE("expression", 3, $1, LEAF("LOGICAL_OP"), $3);
    }
  | factor
    {
        $$ = NODE("expression", 1, $1);
    }
  | ARITH_OP expression %prec UNARY
    {
        $$ = NODE("expression", 2, LEAF("ARITH_OP"), $2);
    }
  | LOGICAL_OP expression %prec UNARY
    {
        $$ = NODE("expression", 2, LEAF("LOGICAL_OP"), $2);
    }
  ;

factor: primary
    {
        $$ = NODE("factor", 1, $1);
    }
  ;

primary: INT_CONST
    {
        $$ = NODE("primary", 1, LEAF("INT_CONST"));
    }
  | REAL_CONST
    {
        $$ = NODE("primary", 1, LEAF("REAL_CONST"));
    }
  | LOGICAL_CONST
    {
        $$ = NODE("primary", 1, LEAF("LOGICAL_CONST"));
    }
  | STRING
    {
        $$ = NODE("primary", 1, LEAF("STRING"));
    }
  | complex_literal
    {
        $$ = NODE("primary", 1, $1);
    }
  | LPAREN expression RPAREN
    {
        $$ = NODE("primary", 3, LEAF("LPAREN"), $2, LEAF("RPAREN"));
    }
  | variable_ref primary_suffix_opt
    {
        $$ = NODE("primary", 2, $1, $2);
    }
  ;

complex_literal: LPAREN expression COMMA expression RPAREN
    {
        $$ = NODE("complex_literal", 5, LEAF("LPAREN"), $2, LEAF("COMMA"), $4, LEAF("RPAREN"));
    }
  ;

primary_suffix_opt: /* empty */
  {
    $$ = NODE0("primary_suffix_opt");
  }
  | LPAREN argument_list RPAREN
    {
        $$ = NODE("primary_suffix_opt", 3, LEAF("LPAREN"), $2, LEAF("RPAREN"));
    }
  ;

variable_ref: identifier
    {
        $$ = NODE("variable_ref", 1, $1);
    }
  | variable_ref DERIVED_TYPE_COMPONENT identifier
    {
        $$ = NODE("variable_ref", 3, $1, LEAF("DERIVED_TYPE_COMPONENT"), $3);
    }
  ;

subprogram_list: /* empty */
  {
    $$ = NODE0("subprogram_list");
  }
  | subprogram_list subprogram
    {
        $$ = NODE("subprogram_list", 2, $1, $2);
    }
  ;

subprogram: SUBROUTINE identifier LPAREN identifier_list_opt RPAREN program_body END SUBROUTINE
    {
        $$ = NODE("subprogram", 8, LEAF("SUBROUTINE"), $2, LEAF("LPAREN"), $4, LEAF("RPAREN"), $6, LEAF("END"), LEAF("SUBROUTINE"));
    }
  | SUBROUTINE identifier LPAREN identifier_list_opt RPAREN program_body END SUBROUTINE identifier
    {
        $$ = NODE("subprogram", 9, LEAF("SUBROUTINE"), $2, LEAF("LPAREN"), $4, LEAF("RPAREN"), $6, LEAF("END"), LEAF("SUBROUTINE"), $9);
    }
  | FUNCTION identifier LPAREN identifier_list_opt RPAREN program_body END FUNCTION
    {
        $$ = NODE("subprogram", 8, LEAF("FUNCTION"), $2, LEAF("LPAREN"), $4, LEAF("RPAREN"), $6, LEAF("END"), LEAF("FUNCTION"));
    }
  | FUNCTION identifier LPAREN identifier_list_opt RPAREN program_body END FUNCTION identifier
    {
        $$ = NODE("subprogram", 9, LEAF("FUNCTION"), $2, LEAF("LPAREN"), $4, LEAF("RPAREN"), $6, LEAF("END"), LEAF("FUNCTION"), $9);
    }
  | RECURSIVE FUNCTION identifier LPAREN identifier_list_opt RPAREN RESULT LPAREN identifier RPAREN program_body END FUNCTION
    {
        $$ = NODE("subprogram", 13, LEAF("RECURSIVE"), LEAF("FUNCTION"), $3, LEAF("LPAREN"), $5, LEAF("RPAREN"), LEAF("RESULT"), LEAF("LPAREN"), $9, LEAF("RPAREN"), $11, LEAF("END"), LEAF("FUNCTION"));
    }
  | RECURSIVE FUNCTION identifier LPAREN identifier_list_opt RPAREN RESULT LPAREN identifier RPAREN program_body END FUNCTION identifier
    {
        $$ = NODE("subprogram", 14, LEAF("RECURSIVE"), LEAF("FUNCTION"), $3, LEAF("LPAREN"), $5, LEAF("RPAREN"), LEAF("RESULT"), LEAF("LPAREN"), $9, LEAF("RPAREN"), $11, LEAF("END"), LEAF("FUNCTION"), $14);
    }
  ;

argument_list: /* empty */
  {
    $$ = NODE0("argument_list");
  }
  | expression
    {
        $$ = NODE("argument_list", 1, $1);
    }
  | expression COMMA argument_list
    {
        $$ = NODE("argument_list", 3, $1, LEAF("COMMA"), $3);
    }
  ;

identifier_list_opt: /* empty */
  {
    $$ = NODE0("identifier_list_opt");
  }
  | identifier_list
    {
        $$ = NODE("identifier_list_opt", 1, $1);
    }
  ;

identifier: IDENTIFIER
    {
        $$ = NODE("identifier", 1, LEAF("IDENTIFIER"));
    }
  | RESULT
    {
        $$ = NODE("identifier", 1, LEAF("RESULT"));
    }
  ;

type_def: TYPE DECL_SEP identifier type_def_body END_TYPE identifier
    {
        $$ = NODE("type_def", 6, LEAF("TYPE"), LEAF("DECL_SEP"), $3, $4, LEAF("END_TYPE"), $6);
    }
  ;

type_def_body: /* empty */
  {
    $$ = NODE0("type_def_body");
  }
  | type_def_declarations
    {
        $$ = NODE("type_def_body", 1, $1);
    }
  ;

type_def_declarations: type_def_declaration
    {
        $$ = NODE("type_def_declarations", 1, $1);
    }
  | type_def_declarations type_def_declaration
    {
        $$ = NODE("type_def_declarations", 2, $1, $2);
    }
  ;

type_def_declaration: type_spec declaration_attributes DECL_SEP declarator_list
    {
        $$ = NODE("type_def_declaration", 4, $1, $2, LEAF("DECL_SEP"), $4);
    }
  ;

pp_define_undef: PP_DEFINE identifier
    {
        $$ = NODE("pp_define_undef", 2, LEAF("PP_DEFINE"), $2);
    }
  | PP_DEFINE identifier INT_CONST
    {
        $$ = NODE("pp_define_undef", 3, LEAF("PP_DEFINE"), $2, LEAF("INT_CONST"));
    }
  | PP_UNDEF identifier
    {
        $$ = NODE("pp_define_undef", 2, LEAF("PP_UNDEF"), $2);
    }
  ;

pp_if_block: PP_IFDEF identifier declarations pp_else_opt PP_ENDIF
    {
        $$ = NODE("pp_if_block", 5, LEAF("PP_IFDEF"), $2, $3, $4, LEAF("PP_ENDIF"));
    }
  | PP_IFNDEF identifier declarations pp_else_opt PP_ENDIF
    {
        $$ = NODE("pp_if_block", 5, LEAF("PP_IFNDEF"), $2, $3, $4, LEAF("PP_ENDIF"));
    }
  | PP_IF identifier declarations pp_else_opt PP_ENDIF
    {
        $$ = NODE("pp_if_block", 5, LEAF("PP_IF"), $2, $3, $4, LEAF("PP_ENDIF"));
    }
  | PP_IF INT_CONST declarations pp_else_opt PP_ENDIF
    {
        $$ = NODE("pp_if_block", 5, LEAF("PP_IF"), LEAF("INT_CONST"), $3, $4, LEAF("PP_ENDIF"));
    }
  ;

pp_else_opt: /* empty */
  {
    $$ = NODE0("pp_else_opt");
  }
  | PP_ELSE declarations
    {
        $$ = NODE("pp_else_opt", 2, LEAF("PP_ELSE"), $2);
    }
  ;

%%

extern int yylineno;
extern char *yytext;

void yyerror(const char *s) {
    fprintf(stderr, "PARSE ERROR\n");
    fprintf(stderr, "Message : %s\n", s);
    fprintf(stderr, "Near    : '%s'\n", yytext);
    fprintf(stderr, "Line    : %d\n", yylineno);
}

extern FILE *yyin;

int main(int argc, char **argv) {
    DTPrintMode mode = DT_POSTORDER;

    if (argc < 2) {
        printf("Usage: ./compiler <file> [--tree]\n");
        return 1;
    }

    // check optional flags
    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "--tree") == 0) {
            mode = DT_TREE;
        }
    }

    FILE *file = fopen(argv[1], "r");
    if (!file) {
        perror("Error opening file");
        return 1;
    }

    yyin = file;

    printf("Starting parse\n");

    if (yyparse() == 0) {
        printf("Parsing done!\n");

        printf("\nDerivation Tree Output:\n");
        dt_print(dt_get_root(), mode);
    } else {
        printf("Parsing failed.\n");
    }

    fclose(file);
    return 0;
}