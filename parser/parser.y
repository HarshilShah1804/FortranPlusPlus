%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../ast/ast_builders.h"
#include "../ast/ast_utils.h"
#include "../ast/ast_print.h"

void yyerror(const char *s);
int yylex();


static ASTNode *ast_make_keyword_identifier(const char *name)
{
  return make_identifier((char *)name);
}

static ASTNode *ast_append_derived(ASTNode *base, const char *field)
{
  if (!base || base->type != NODE_VAR || !base->data.var.id || !field) {
    return make_var(make_identifier((char *)field));
  }

  ASTNode *id = base->data.var.id;
  if (id->type != NODE_IDENTIFIER || !id->data.identifier.name) {
    return make_var(make_identifier((char *)field));
  }

  size_t base_len = strlen(id->data.identifier.name);
  size_t field_len = strlen(field);
  size_t total = base_len + 1 + field_len;
  char *combined = (char *)malloc(total + 1);
  if (!combined) {
    return make_var(make_identifier((char *)field));
  }

  memcpy(combined, id->data.identifier.name, base_len);
  combined[base_len] = '%';
  memcpy(combined + base_len + 1, field, field_len);
  combined[total] = '\0';

  ASTNode *result = make_var(make_identifier(combined));
  free(combined);
  return result;
}

%}

%union {
  ASTNode *ast;
  char *text;
}


%define parse.error verbose

%token PROGRAM MODULE END CONTAINS USE NONE IMPLICIT
%token INTEGER REAL LOGICAL CHARACTER TYPE CLASS END_TYPE COMPLEX
%token IF THEN ELSE DO ENDIF LEN INTRINSIC WHILE SELECT CASE DEFAULT RANK
%token STOP PRINT CALL SUBROUTINE FUNCTION RETURN RECURSIVE RESULT
%token ALLOCATE DEALLOCATE ALLOCATED POINTER TARGET ALLOCATABLE INTENT IN OUT INOUT
%token OPEN CLOSE INQUIRE WRITE READ ERROR
%token LPAREN RPAREN COMMA COLON ASSUMED_RANK_SPECIFIER CONCAT PTR_ASSIGN
%token PP_DEFINE PP_UNDEF PP_IFDEF PP_IFNDEF PP_IF PP_ELIF PP_ELSE PP_ENDIF
%token LENGTH_SPECIFIER

%token <text> IDENTIFIER INT_CONST REAL_CONST STRING LOGICAL_CONST
%token <text> ARITH_OP REL_OP LOGICAL_OP
%token ASSIGN EXPONENT DECL_SEP DERIVED_TYPE_COMPONENT

%type <ast> start compilation_units compilation_unit free_form program_unit module_unit
%type <ast> program_body module_body contains_block declarations declarations_with_modules preamble pp_item
%type <ast> declaration type_spec char_type_spec char_len_opt char_len_value
%type <ast> attributes attribute declaration_attributes identifier_list declarator_list
%type <ast> declarator array_spec_opt array_spec array_spec_list array_spec_item init_opt
%type <ast> executables executable assignment_stmt if_stmt do_stmt dowhile_stmt select_stmt
%type <ast> select_rank_stmt rank_blocks rank_block rank_selector case_blocks case_block
%type <ast> call_stmt callable_name return_stmt stop_stmt pointer_stmt step_opt print_stmt
%type <ast> print_args allocate_stmt deallocate_stmt expression factor primary complex_literal
%type <ast> primary_suffix_opt variable_ref subprogram_list subprogram argument_list
%type <ast> identifier_list_opt identifier type_def type_def_body type_def_declarations
%type <ast> type_def_declaration pp_define_undef pp_if_block pp_else_opt

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
        $$ = $1;
        ast_set_root($$);
    }
  | free_form
    {
        $$ = $1;
        ast_set_root($$);
    }
  ;

compilation_units: compilation_unit
    {
    ASTNode *block = make_block();
    block_add(block, $1);
    $$ = block;
    }
  | compilation_units compilation_unit
    {
    ASTNode *block = $1;
    if (!block) {
      block = make_block();
    }
    block_add(block, $2);
    $$ = block;
    }
  ;

compilation_unit: program_unit
    {
        $$ = $1;
    }
  | module_unit
    {
        $$ = $1;
    }
  ;

free_form: preamble declarations executables
    {
    $$ = $3;
    }
  ;

program_unit: PROGRAM IDENTIFIER program_body END PROGRAM IDENTIFIER
    {
        ASTNode *program = new_node(NODE_PROGRAM);
        add_child(program, $3);
        $$ = program;
    }
  | PROGRAM IDENTIFIER program_body END PROGRAM
    {
        ASTNode *program = new_node(NODE_PROGRAM);
        add_child(program, $3);
        $$ = program;
    }
  ;

module_unit: MODULE IDENTIFIER module_body END MODULE IDENTIFIER
    {
        ASTNode *module = new_node(NODE_MODULE);
        add_child(module, $3);
        $$ = module;
    }
  ;

program_body: preamble declarations_with_modules executables contains_block
    {
        ASTNode *body = make_block();
        block_add(body, $2);
        block_add(body, $3);
        $$ = body;
    }
  ;

module_body: preamble declarations executables contains_block
    {
    $$ = $3;
    }
  ;

contains_block: CONTAINS subprogram_list
    {
    }
  | /* empty */
    {
    }
  ;

declarations: /* empty */
  {
    $$ = make_block();
  }
  | declaration declarations
    {
        ASTNode *block = $2;
        if (!block) {
            block = make_block();
        }
        block_add(block, $1);
        $$ = block;
    }
  ;

declarations_with_modules: /* empty */
  {
    $$ = make_block();
  }
  | declarations_with_modules declaration
    {
        ASTNode *block = $1;
        if (!block) {
            block = make_block();
        }
        block_add(block, $2);
        $$ = block;
    }
  | declarations_with_modules module_unit
    {
        ASTNode *block = $1;
        if (!block) {
            block = make_block();
        }
        block_add(block, $2);
        $$ = block;
    }
  ;

preamble: /* empty */
  {
  }
  | preamble pp_item
    {
    }
  ;

pp_item: pp_define_undef
    {
    }
  | pp_if_block
    {
    }
  ;

declaration: type_spec declaration_attributes DECL_SEP declarator_list
    {
        $$ = NULL;
    }
  | IMPLICIT NONE
    {
        $$ = NULL;
    }
  | USE identifier
    {
        $$ = NULL;
    }
  | type_def
    {
        $$ = NULL;
    }
  ;

type_spec: INTEGER
    {
    }
  | REAL
    {
    }
  | LOGICAL
    {
    }
  | char_type_spec
    {
    }
  | TYPE LPAREN identifier RPAREN
    {
    }
  | CLASS identifier
    {
    }
  | COMPLEX
    {
    }
  ;

char_type_spec: CHARACTER char_len_opt
    {
    }
  ;

char_len_opt: /* empty */
  {
  }
  | LPAREN LENGTH_SPECIFIER ASSIGN char_len_value RPAREN
    {
    }
  ;

char_len_value: COLON
    {
    }
  | INT_CONST
    {
    }
  | identifier
    {
    }
  ;

attributes: attribute
    {
    }
  | attribute COMMA attributes
    {
    }
  ;

attribute: ALLOCATABLE
    {
    }
  | POINTER
    {
    }
  | TARGET
    {
    }
  | INTENT LPAREN IN RPAREN
    {
    }
  | INTENT LPAREN OUT RPAREN
    {
    }
  | INTENT LPAREN INOUT RPAREN
    {
    }
  ;

declaration_attributes: /* empty */
  {
  }
  | COMMA attributes
    {
    }
  ;

identifier_list: identifier
    {
    }
  | identifier COMMA identifier_list
    {
    }
  ;

declarator_list: declarator
    {
    }
  | declarator COMMA declarator_list
    {
    }
  ;

declarator: identifier array_spec_opt init_opt
    {
    }
  ;

array_spec_opt: /* empty */
  {
  }
  | array_spec
    {
    }
  ;

array_spec: LPAREN array_spec_list RPAREN
    {
    }
  ;

array_spec_list: array_spec_item
    {
    }
  | array_spec_list COMMA array_spec_item
    {
    }
  ;

array_spec_item: ASSUMED_RANK_SPECIFIER
    {
    }
  | COLON
    {
    }
  | expression
    {
    }
  | expression COLON
    {
    }
  | COLON expression
    {
    }
  | expression COLON expression
    {
    }
  ;

init_opt: /* empty */
  {
  }
  | ASSIGN expression
    {
    }
  ;

executables: /* empty */
  {
    $$ = make_block();
  }
  | executables executable
    {
        ASTNode *block = $1;
        if (!block) {
            block = make_block();
        }
        block_add(block, $2);
        $$ = block;
    }
  ;


executable: assignment_stmt
    {
        $$ = $1;
    }
  | if_stmt
    {
        $$ = $1;
    }
  | print_stmt
    {
        $$ = $1;
    }
  | allocate_stmt
    {
        $$ = $1;
    }
  | deallocate_stmt
    {
        $$ = $1;
    }
  | do_stmt
    {
        $$ = $1;
    }
  | dowhile_stmt
    {
        $$ = $1;
    }
  | select_rank_stmt
    {
        $$ = $1;
    }
  | select_stmt
    {
        $$ = $1;
    }
  | call_stmt
    {
        $$ = $1;
    }
  | return_stmt
    {
        $$ = $1;
    }
  | stop_stmt
    {
        $$ = $1;
    }
  | pointer_stmt
    {
        $$ = $1;
    }
  ;


assignment_stmt: variable_ref ASSIGN expression
    {
    $$ = make_assign($1, $3);
    }
  ;

if_stmt: IF LPAREN expression RPAREN THEN executables ENDIF %prec LOWER_THAN_ELSE
    {
        $$ = make_if($3, $6, NULL);
    }
  | IF LPAREN expression RPAREN THEN executables END IF %prec LOWER_THAN_ELSE
    {
        $$ = make_if($3, $6, NULL);
    }
  | IF LPAREN expression RPAREN THEN executables ELSE executables ENDIF
    {
        $$ = make_if($3, $6, $8);
    }
  | IF LPAREN expression RPAREN THEN executables ELSE executables END IF
    {
        $$ = make_if($3, $6, $8);
    }
  ;

do_stmt: DO IDENTIFIER ASSIGN expression COMMA expression step_opt executables END DO
    {
    char *loop_id = $2;
    ASTNode *loop = new_node(NODE_DO);
    add_child(loop, make_var(make_identifier(loop_id)));
    add_child(loop, $4);
    add_child(loop, $6);
    add_child(loop, $7);
    add_child(loop, $8);
    free(loop_id);
    $$ = loop;
    }
  ;

dowhile_stmt: DO WHILE LPAREN expression RPAREN executables END DO
    {
    ASTNode *loop = new_node(NODE_DO);
    add_child(loop, $4);
    add_child(loop, $6);
    $$ = loop;
    }
  ;

select_stmt: SELECT CASE LPAREN expression RPAREN case_blocks END SELECT
    {
    }
  ;

select_rank_stmt: SELECT RANK LPAREN identifier RPAREN rank_blocks END SELECT
    {
    }
  ;

rank_blocks: rank_block
    {
    }
  | rank_blocks rank_block
    {
    }
  ;

rank_block: RANK LPAREN rank_selector RPAREN executables
    {
    }
  | RANK DEFAULT executables
    {
    }
  ;

rank_selector: INT_CONST
    {
    }
  | ARITH_OP
    {
    }
  ;

case_blocks: case_block
    {
    }
  | case_blocks case_block
    {
    }
  ;

case_block: CASE LPAREN expression RPAREN executables
    {
    }
  | CASE DEFAULT executables
    {
    }
  ;

call_stmt: CALL callable_name LPAREN argument_list RPAREN
    {
    $$ = make_call($2, $4);
    }
  ;

callable_name: identifier
    {
        $$ = $1;
    }
  | INTRINSIC
    {
        $$ = ast_make_keyword_identifier("intrinsic");
    }
  ;

return_stmt: RETURN
    {
    $$ = new_node(NODE_RETURN);
    }
  ;

stop_stmt: STOP
    {
        $$ = new_node(NODE_STOP);
    }
  | STOP INT_CONST
    {
        $$ = new_node(NODE_STOP);
    }
  | STOP STRING
    {
        $$ = new_node(NODE_STOP);
    }
  ;

pointer_stmt: variable_ref PTR_ASSIGN variable_ref
    {
    $$ = make_assign($1, $3);
    }
  ;

step_opt: /* empty */
  {
    $$ = NULL;
  }
  | COMMA expression
    {
        $$ = $2;
    }
  ;

print_stmt: PRINT ARITH_OP COMMA print_args
    {
    $$ = make_call(ast_make_keyword_identifier("print"), $4);
    }
  ;

print_args: expression
    {
    ASTNode *list = make_arg_list();
    arg_list_add(list, $1);
    $$ = list;
    }
  | print_args COMMA expression
    {
    ASTNode *list = $1;
    if (!list) {
      list = make_arg_list();
    }
    arg_list_add(list, $3);
    $$ = list;
    }
  ;

allocate_stmt: ALLOCATE LPAREN argument_list RPAREN
    {
    $$ = make_call(ast_make_keyword_identifier("allocate"), $3);
    }
  ;

deallocate_stmt: DEALLOCATE LPAREN argument_list RPAREN
    {
    $$ = make_call(ast_make_keyword_identifier("deallocate"), $3);
    }
  ;

expression: expression ARITH_OP expression
    {
        char *op = $2;
        $$ = make_binary(op, $1, $3);
        free(op);
    }
  | expression EXPONENT expression
    {
        $$ = make_binary("**", $1, $3);
    }
  | expression REL_OP expression
    {
        char *op = $2;
        $$ = make_binary(op, $1, $3);
        free(op);
    }
  | expression LOGICAL_OP expression
    {
        char *op = $2;
        $$ = make_binary(op, $1, $3);
        free(op);
    }
  | factor
    {
        $$ = $1;
    }
  | ARITH_OP expression %prec UNARY
    {
        char *op = $1;
        $$ = make_unary(op, $2);
        free(op);
    }
  | LOGICAL_OP expression %prec UNARY
    {
        char *op = $1;
        $$ = make_unary(op, $2);
        free(op);
    }
  ;

factor: primary
    {
    $$ = $1;
    }
  ;

primary: INT_CONST
    {
        char *val = $1;
        $$ = make_int(val);
        free(val);
    }
  | REAL_CONST
    {
        char *val = $1;
        $$ = make_real(val);
        free(val);
    }
  | LOGICAL_CONST
    {
        char *val = $1;
        $$ = make_logical(val);
        free(val);
    }
  | STRING
    {
        char *val = $1;
        $$ = make_string(val);
        free(val);
    }
  | complex_literal
    {
        $$ = $1;
    }
  | LPAREN expression RPAREN
    {
        $$ = $2;
    }
  | variable_ref primary_suffix_opt
    {
        if ($2) {
            $$ = make_call_or_index($1, $2);
        } else {
            $$ = $1;
        }
    }
  ;

complex_literal: LPAREN expression COMMA expression RPAREN
    {
    ASTNode *args = make_arg_list();
    arg_list_add(args, $2);
    arg_list_add(args, $4);
    $$ = make_call_or_index(ast_make_keyword_identifier("complex"), args);
    }
  ;

primary_suffix_opt: /* empty */
  {
    $$ = NULL;
  }
  | LPAREN argument_list RPAREN
    {
        $$ = $2;
    }
  ;

variable_ref: identifier
    {
        $$ = make_var($1);
    }
  | variable_ref DERIVED_TYPE_COMPONENT IDENTIFIER
    {
        char *field = $3;
        $$ = ast_append_derived($1, field);
        free(field);
    }
  ;

subprogram_list: /* empty */
  {
  }
  | subprogram_list subprogram
    {
    }
  ;

subprogram: SUBROUTINE identifier LPAREN identifier_list_opt RPAREN program_body END SUBROUTINE
    {
    }
  | SUBROUTINE identifier LPAREN identifier_list_opt RPAREN program_body END SUBROUTINE identifier
    {
    }
  | FUNCTION identifier LPAREN identifier_list_opt RPAREN program_body END FUNCTION
    {
    }
  | FUNCTION identifier LPAREN identifier_list_opt RPAREN program_body END FUNCTION identifier
    {
    }
  | RECURSIVE FUNCTION identifier LPAREN identifier_list_opt RPAREN RESULT LPAREN identifier RPAREN program_body END FUNCTION
    {
    }
  | RECURSIVE FUNCTION identifier LPAREN identifier_list_opt RPAREN RESULT LPAREN identifier RPAREN program_body END FUNCTION identifier
    {
    }
  ;

argument_list: /* empty */
  {
        $$ = make_arg_list();
  }
  | expression
    {
        ASTNode *list = make_arg_list();
        arg_list_add(list, $1);
        $$ = list;
    }
  | expression COMMA argument_list
    {
        $$ = arg_list_prepend($3, $1);
    }
  ;

identifier_list_opt: /* empty */
  {
  }
  | identifier_list
    {
    }
  ;

identifier: IDENTIFIER
    {
        char *name = $1;
        $$ = make_identifier(name);
        free(name);
    }
  | RESULT
    {
        $$ = make_identifier("result");
    }
  ;

type_def: TYPE DECL_SEP identifier type_def_body END_TYPE identifier
    {
    }
  ;

type_def_body: /* empty */
  {
  }
  | type_def_declarations
    {
    }
  ;

type_def_declarations: type_def_declaration
    {
    }
  | type_def_declarations type_def_declaration
    {
    }
  ;

type_def_declaration: type_spec declaration_attributes DECL_SEP declarator_list
    {
    }
  ;

pp_define_undef: PP_DEFINE identifier
    {
    }
  | PP_DEFINE identifier INT_CONST
    {
    }
  | PP_UNDEF identifier
    {
    }
  ;

pp_if_block: PP_IFDEF identifier declarations pp_else_opt PP_ENDIF
    {
    }
  | PP_IFNDEF identifier declarations pp_else_opt PP_ENDIF
    {
    }
  | PP_IF identifier declarations pp_else_opt PP_ENDIF
    {
    }
  | PP_IF INT_CONST declarations pp_else_opt PP_ENDIF
    {
    }
  ;

pp_else_opt: /* empty */
  {
  }
  | PP_ELSE declarations
    {
    }
  ;

%%

extern int yylineno;
extern char *yytext;
extern int token_column;
extern char current_line[];

void yyerror(const char *s) {
  const char *code_prefix = "-> Code: ";
  const char *near_text = (yytext && yytext[0] != '\0') ? yytext : "EOF";
  const char *specific_hint = NULL;

  fprintf(stderr, "PARSE ERROR\n");
  fprintf(stderr, "Message : %s\n", s);
  fprintf(stderr, "Line    : %d\n", yylineno);
  fprintf(stderr, "Column  : %d\n", token_column);
  fprintf(stderr, "Near    : '%s'\n", near_text);

  if (current_line[0] != '\0') {
    int caret_col = (int)strlen(code_prefix) + token_column - 1;
    if (caret_col < 0) {
      caret_col = 0;
    }
    fprintf(stderr, "%s%s\n", code_prefix, current_line);
    fprintf(stderr, "%*s^\n", caret_col, "");
  }

  if (strchr(current_line, '(') && !strchr(current_line, ')')) {
    specific_hint = "Missing closing ')'";
  } else if (strstr(s, "ENDIF") || strstr(s, "END IF")) {
    specific_hint = "Missing ENDIF for an IF block";
  } else if (strchr(current_line, '=') != NULL) {
    const char *eq = strrchr(current_line, '=');
    if (eq) {
      const char *p = eq + 1;
      while (*p == ' ' || *p == '\t' || *p == '\r') {
        p++;
      }
      if (*p == '\0') {
        specific_hint = "Assignment missing a right-hand side";
      }
    }
  } else if (!yytext || yytext[0] == '\0') {
    specific_hint = "Unexpected end of file; check for missing block endings";
  }

  if (specific_hint) {
    fprintf(stderr, "Hint    : %s\n", specific_hint);
  }
  fprintf(stderr, "Hint    : Check syntax near the token and ensure blocks and parentheses are closed.\n");
}

extern FILE *yyin;

int main(int argc, char **argv) {

    if (argc < 2) {
        printf("Usage: ./compiler <file> [--tree]\n");
        return 1;
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

        printf("\nAST Output:\n");
        ast_print(ast_get_root());
    } else {
        printf("Parsing failed.\n");
    }

    fclose(file);
    return 0;
}
