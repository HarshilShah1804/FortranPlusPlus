%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(const char *s);
int yylex();
%}

%token PROGRAM MODULE END CONTAINS USE NONE IMPLICIT
%token INTEGER REAL LOGICAL CHARACTER TYPE CLASS END_TYPE COMPLEX
%token IF THEN ELSE DO ENDIF LEN LOGICAL_CONST INTRINSIC WHILE SELECT CASE DEFAULT RANK 
%token STOP PRINT CALL SUBROUTINE FUNCTION RETURN RECURSIVE RESULT
%token ALLOCATE DEALLOCATE ALLOCATED POINTER TARGET ALLOCATABLE INTENT IN OUT INOUT
%token OPEN CLOSE INQUIRE WRITE READ ERROR
%token REL_OP ASSIGN ARITH_OP LPAREN RPAREN COMMA DECL_SEP COLON ASSUMED_RANK_SPECIFIER EXPONENT CONCAT DERIVED_TYPE_COMPONENT
%token PP_DEFINE PP_UNDEF PP_IFDEF PP_IFNDEF PP_IF PP_ELIF PP_ELSE PP_ENDIF LOGICAL_OP
%token IDENTIFIER INT_CONST REAL_CONST STRING LENGTH_SPECIFIER

%%

start: program_unit | module_unit
     ;
    
program_unit: PROGRAM IDENTIFIER program_body END PROGRAM IDENTIFIER
            | PROGRAM IDENTIFIER program_body END PROGRAM
            ;

module_unit: MODULE IDENTIFIER module_body END MODULE IDENTIFIER
           | MODULE IDENTIFIER module_body END MODULE
           ;

program_body: declarations executables
            | declarations executables contains_block
            ;

module_body: declarations
           | declarations contains_block
           ;

contains_block: CONTAINS subprogram_list ;

declarations: /* empty */
            | declarations type_spec attributes DECL_SEP identifier_list
            | declarations IMPLICIT NONE
            | declarations USE IDENTIFIER
            ;

type_spec: INTEGER
         | REAL
         | LOGICAL
         | CHARACTER
         | TYPE LPAREN IDENTIFIER RPAREN 
         | CLASS IDENTIFIER
         | COMPLEX
         ;

attributes: /* empty */
          | attributes ALLOCATABLE
          | attributes POINTER
          | attributes TARGET
          | attributes INTENT LPAREN IN RPAREN
          | attributes INTENT LPAREN OUT RPAREN
          | attributes INTENT LPAREN INOUT RPAREN
          ;

identifier_list: /* empty */
               | IDENTIFIER
               | identifier_list COMMA IDENTIFIER
               ;

executables: executable
           | executables executable
           ;

executable:
      assignment_stmt
    | if_stmt
    | print_stmt
    | do_stmt
    | dowhile_stmt
    | select_stmt
    | call_stmt
    | return_stmt
    | stop_stmt
    ;

assignment_stmt: variable_ref ASSIGN expression ;

if_stmt: IF LPAREN expression RPAREN THEN executables else_block ENDIF ;

do_stmt:
    DO IDENTIFIER ASSIGN expression COMMA expression executables END DO
    ;

dowhile_stmt:
    DO WHILE LPAREN expression RPAREN executables END DO
    ;

select_stmt:
    SELECT CASE LPAREN expression RPAREN case_blocks END SELECT
    ;

case_blocks:
      case_block
    | case_blocks case_block
    ;

case_block:
      CASE LPAREN expression RPAREN executables
    | CASE DEFAULT executables
    ;

call_stmt:
    CALL IDENTIFIER LPAREN argument_list RPAREN
    ;

return_stmt:
    RETURN
    ;

stop_stmt:
    STOP
    ;
    
else_block: /* empty */
          | ELSE executables
          ;

print_stmt: PRINT COMMA argument_list ;

expression: expression ARITH_OP expression
          | expression EXPONENT expression
          | expression REL_OP expression
          | expression LOGICAL_OP expression
          | factor
          ;

factor: array_access
      | function_call
      | variable_ref
      | INT_CONST
      | REAL_CONST
      | LOGICAL_CONST
      | STRING
      | LPAREN expression RPAREN
      ;

array_access: variable_ref LPAREN argument_list RPAREN ;

function_call: variable_ref LPAREN argument_list RPAREN ;

variable_ref: IDENTIFIER
            | variable_ref DERIVED_TYPE_COMPONENT IDENTIFIER
            ;

subprogram_list: subprogram
               | subprogram_list subprogram
               ;

subprogram: SUBROUTINE IDENTIFIER LPAREN identifier_list RPAREN program_body END SUBROUTINE
          | SUBROUTINE IDENTIFIER LPAREN identifier_list RPAREN program_body END SUBROUTINE IDENTIFIER
          | FUNCTION IDENTIFIER LPAREN identifier_list RPAREN program_body END FUNCTION
          | FUNCTION IDENTIFIER LPAREN identifier_list RPAREN program_body END FUNCTION IDENTIFIER
          | RECURSIVE FUNCTION IDENTIFIER LPAREN identifier_list RPAREN RESULT LPAREN IDENTIFIER RPAREN program_body END FUNCTION
          | RECURSIVE FUNCTION IDENTIFIER LPAREN identifier_list RPAREN RESULT LPAREN IDENTIFIER RPAREN program_body END FUNCTION IDENTIFIER
          ;

argument_list: expression
             | argument_list COMMA expression
             ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
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

    printf("Starting parse...\n");
    if (yyparse() == 0) {
        printf("Parsing completed successfully!\n");
    } else {
        printf("Parsing failed.\n");
    }

    if (yyin != stdin) {
        fclose(yyin);
    }
    return 0;
}