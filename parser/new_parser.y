%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex();

%}

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

%left LOGICAL_OP
%nonassoc REL_OP
%left ARITH_OP
%right EXPONENT
%right UNARY
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start: compilation_units
  | free_form
  ;

compilation_units: compilation_unit
                | compilation_units compilation_unit
                ;

compilation_unit: program_unit
                | module_unit
                ;

free_form: preamble declarations executables
  ;

program_unit: PROGRAM IDENTIFIER program_body END PROGRAM IDENTIFIER
            | PROGRAM IDENTIFIER program_body END PROGRAM
            ;

module_unit: MODULE IDENTIFIER module_body END MODULE IDENTIFIER
           | MODULE IDENTIFIER module_body END MODULE         
           ;

program_body: preamble declarations executables contains_block
            ;

module_body: preamble declarations executables contains_block
           ;

contains_block: CONTAINS subprogram_list 
              | /* empty */
              ;

declarations: /* empty */
      | declaration declarations
      ;

preamble: /* empty */
  | preamble pp_item
  ;

pp_item: pp_define_undef
       | pp_if_block
       ;

declaration: type_spec declaration_attributes DECL_SEP declarator_list
           | IMPLICIT NONE
           | USE identifier
           | type_def
           ;

type_spec: INTEGER
         | REAL
         | LOGICAL
         | char_type_spec
         | TYPE LPAREN identifier RPAREN
         | CLASS identifier
         | COMPLEX
         ;

char_type_spec: CHARACTER char_len_opt
              ;

char_len_opt: /* empty */
            | LPAREN LENGTH_SPECIFIER ASSIGN char_len_value RPAREN
            ;

char_len_value: COLON
              | INT_CONST
              | identifier
              ;

attributes:
    attribute
  | attribute COMMA attributes
  ;

attribute: ALLOCATABLE 
           | POINTER     
           | TARGET      
           | INTENT LPAREN IN    RPAREN 
           | INTENT LPAREN OUT   RPAREN 
           | INTENT LPAREN INOUT RPAREN 
           ;

declaration_attributes: /* empty */
                      | COMMA attributes
                      ;

identifier_list:
    identifier
  | identifier COMMA identifier_list
    ;

declarator_list:
    declarator
  | declarator COMMA declarator_list
    ;

declarator: identifier array_spec_opt init_opt
          ;

array_spec_opt: /* empty */
              | array_spec
              ;

array_spec: LPAREN array_spec_list RPAREN
          ;

array_spec_list:
    array_spec_item
  | array_spec_list COMMA array_spec_item
    ;

array_spec_item:
    ASSUMED_RANK_SPECIFIER
  | COLON
  | expression
  | expression COLON
  | COLON expression
  | expression COLON expression
    ;

init_opt: /* empty */
        | ASSIGN expression
        ;

executables:
    /* empty */
  | executables executable
  ;

executable: assignment_stmt
          | if_stmt
          | print_stmt
          | allocate_stmt
          | deallocate_stmt
          | do_stmt
          | dowhile_stmt
          | select_rank_stmt
          | select_stmt
          | call_stmt
          | return_stmt
          | stop_stmt
          | pointer_stmt
          ;

assignment_stmt: variable_ref ASSIGN expression 
               ;

if_stmt: IF LPAREN expression RPAREN THEN executables ENDIF %prec LOWER_THAN_ELSE
  | IF LPAREN expression RPAREN THEN executables END IF %prec LOWER_THAN_ELSE
  | IF LPAREN expression RPAREN THEN executables ELSE executables ENDIF
  | IF LPAREN expression RPAREN THEN executables ELSE executables END IF
  ;

do_stmt: DO IDENTIFIER ASSIGN expression COMMA expression step_opt executables END DO
       ;

dowhile_stmt: DO WHILE LPAREN expression RPAREN executables END DO
            ;

select_stmt: SELECT CASE LPAREN expression RPAREN case_blocks END SELECT 
           ;
select_rank_stmt: SELECT RANK LPAREN identifier RPAREN rank_blocks END SELECT
                  ;

rank_blocks:
    rank_block
  | rank_blocks rank_block
;

rank_block: RANK LPAREN rank_selector RPAREN executables
    | RANK DEFAULT executables
    ;

rank_selector: INT_CONST
       | ARITH_OP
       ;

case_blocks:
    case_block
  | case_blocks case_block
;

case_block: CASE LPAREN expression RPAREN executables
          | CASE DEFAULT executables
          ;

call_stmt: CALL callable_name LPAREN argument_list RPAREN
         ;

callable_name: identifier
             | INTRINSIC
             ;

return_stmt: RETURN ;
stop_stmt: STOP 
         | STOP INT_CONST
         | STOP STRING
         ;

pointer_stmt: variable_ref PTR_ASSIGN variable_ref
            ;
step_opt: /* empty */
        | COMMA expression
        ;

print_stmt:
    PRINT ARITH_OP COMMA print_args
;

print_args:
    expression
  | print_args COMMA expression
;

allocate_stmt: ALLOCATE LPAREN argument_list RPAREN
            ;

deallocate_stmt: DEALLOCATE LPAREN argument_list RPAREN 
            ;

expression: expression ARITH_OP expression
          | expression EXPONENT expression
          | expression REL_OP expression
          | expression LOGICAL_OP expression
          | factor
          | ARITH_OP expression %prec UNARY
          | LOGICAL_OP expression %prec UNARY
          ;

factor:
  primary
  ;

primary:
  INT_CONST
  | REAL_CONST
  | LOGICAL_CONST
  | STRING
  | complex_literal
  | LPAREN expression RPAREN
  | variable_ref primary_suffix_opt
  ;

complex_literal: LPAREN expression COMMA expression RPAREN
  ;

primary_suffix_opt: /* empty */
                  | LPAREN argument_list RPAREN
                  ;

variable_ref: identifier
            | variable_ref DERIVED_TYPE_COMPONENT identifier
            ;

subprogram_list:
    /* empty */
  | subprogram_list subprogram
  ;

subprogram: SUBROUTINE identifier LPAREN identifier_list_opt RPAREN program_body END SUBROUTINE
          | SUBROUTINE identifier LPAREN identifier_list_opt RPAREN program_body END SUBROUTINE identifier
          | FUNCTION identifier LPAREN identifier_list_opt RPAREN program_body END FUNCTION
          | FUNCTION identifier LPAREN identifier_list_opt RPAREN program_body END FUNCTION identifier
          | RECURSIVE FUNCTION identifier LPAREN identifier_list_opt RPAREN RESULT LPAREN identifier RPAREN program_body END FUNCTION
          | RECURSIVE FUNCTION identifier LPAREN identifier_list_opt RPAREN RESULT LPAREN identifier RPAREN program_body END FUNCTION identifier
          ;

argument_list:
    /* empty */
  | expression
  | expression COMMA argument_list
  ;

identifier_list_opt: /* empty */
                   | identifier_list
                   ;

identifier: IDENTIFIER
          | RESULT
          ;

type_def: TYPE DECL_SEP identifier type_def_body END_TYPE identifier
  ;

type_def_body: /* empty */
       | type_def_declarations
       ;

type_def_declarations: type_def_declaration
         | type_def_declarations type_def_declaration
         ;

type_def_declaration: type_spec declaration_attributes DECL_SEP declarator_list
        ;

pp_define_undef: PP_DEFINE identifier
               | PP_DEFINE identifier INT_CONST
               | PP_UNDEF identifier
               ;

pp_if_block: PP_IFDEF identifier declarations pp_else_opt PP_ENDIF
           | PP_IFNDEF identifier declarations pp_else_opt PP_ENDIF
           | PP_IF identifier declarations pp_else_opt PP_ENDIF
           | PP_IF INT_CONST declarations pp_else_opt PP_ENDIF
           ;

pp_else_opt: /* empty */
           | PP_ELSE declarations
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
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            perror("Error opening file");
            return 1;
        }
        yyin = file;
    } else {
        printf("Usage: ./compiler <filename.f90>\n");
        return 1;
    }

    printf("Starting parse\n");
    if (yyparse() == 0) {
        printf("Parsing done!\n");

        printf("\nReverse Derivation Tree\n");

        printf("\nClojure Serialization Format\n");
        printf("\n\n");

    } else {
        printf("Parsing failed.\n");
    }

    if (yyin != stdin) {
        fclose(yyin);
    }
    return 0;
}
