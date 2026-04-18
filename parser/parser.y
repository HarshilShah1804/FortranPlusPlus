%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "derivation_tree.h"
#include "../ir/tac.h"
#include "../semantic/sdt_semantic.h"

void yyerror(const char *s);
int yylex();

#define NODE(name, count, ...) dt_make_node((name), (count), __VA_ARGS__)
#define NODE0(name) dt_make_node((name), 0)
#define LEAF(name) dt_make_leaf((name))

static char *sdt_append_derived(const char *base, const char *field)
{
  if (!field) {
    return NULL;
  }
  if (!base || base[0] == '\0') {
    return strdup(field);
  }

  size_t base_len = strlen(base);
  size_t field_len = strlen(field);
  size_t total = base_len + 1 + field_len;
  char *combined = (char *)malloc(total + 1);
  if (!combined) {
    return strdup(field);
  }

  memcpy(combined, base, base_len);
  combined[base_len] = '%';
  memcpy(combined + base_len + 1, field, field_len);
  combined[total] = '\0';
  return combined;
}

typedef struct {
  char *else_label;
  char *end_label;
  int has_else;
} SdtIfCtx;

typedef struct {
  char *start_label;
  char *end_label;
} SdtLoopCtx;

typedef struct SdtArgNode {
  char *place;
  struct SdtArgNode *next;
} SdtArgNode;

typedef struct SdtArgList {
  SdtArgNode *head;
  int count;
} SdtArgList;

typedef struct {
  char *var_name;
  char *step_value;
  char *start_label;
  char *end_label;
} SdtForCtx;

#define SDT_STACK_MAX 128
static SdtIfCtx g_if_stack[SDT_STACK_MAX];
static int g_if_top = 0;
static SdtLoopCtx g_loop_stack[SDT_STACK_MAX];
static int g_loop_top = 0;
static SdtForCtx g_for_stack[SDT_STACK_MAX];
static int g_for_top = 0;
static int g_emit_stack[SDT_STACK_MAX];
static int g_emit_top = 0;
static const char *g_decl_name = NULL;
static TacValue *g_decl_init = NULL;
static int g_decl_has_array = 0;
static SdtType g_decl_type = SDT_TYPE_UNKNOWN;

static SdtArgNode *sdt_arg_node_new(const char *place)
{
  SdtArgNode *node = (SdtArgNode *)malloc(sizeof(SdtArgNode));
  if (!node) {
    return NULL;
  }
  node->place = place ? strdup(place) : strdup("");
  node->next = NULL;
  return node;
}

static SdtArgList *sdt_arg_list_empty(void)
{
  SdtArgList *list = (SdtArgList *)malloc(sizeof(SdtArgList));
  if (!list) {
    return NULL;
  }
  list->head = NULL;
  list->count = 0;
  return list;
}

static SdtArgList *sdt_arg_list_prepend(const char *place, SdtArgList *tail)
{
  SdtArgList *list = tail ? tail : sdt_arg_list_empty();
  if (!list) {
    return NULL;
  }

  SdtArgNode *node = sdt_arg_node_new(place);
  if (!node) {
    return list;
  }
  node->next = list->head;
  list->head = node;
  list->count++;
  return list;
}

static SdtArgList *sdt_arg_list_append(SdtArgList *list, const char *place)
{
  SdtArgList *out = list ? list : sdt_arg_list_empty();
  if (!out) {
    return NULL;
  }

  SdtArgNode *node = sdt_arg_node_new(place);
  if (!node) {
    return out;
  }

  if (!out->head) {
    out->head = node;
  } else {
    SdtArgNode *cur = out->head;
    while (cur->next) {
      cur = cur->next;
    }
    cur->next = node;
  }

  out->count++;
  return out;
}

static SdtForCtx sdt_for_push(const char *var_name, const char *step_value)
{
  SdtForCtx ctx;
  ctx.var_name = var_name ? strdup(var_name) : strdup("");
  ctx.step_value = step_value ? strdup(step_value) : strdup("1");
  ctx.start_label = tac_new_label();
  ctx.end_label = tac_new_label();

  if (g_for_top < SDT_STACK_MAX) {
    g_for_stack[g_for_top++] = ctx;
  }
  return ctx;
}

static SdtForCtx sdt_for_pop(void)
{
  if (g_for_top > 0) {
    return g_for_stack[--g_for_top];
  }
  SdtForCtx empty = { NULL, NULL, NULL, NULL };
  return empty;
}


static SdtIfCtx sdt_if_push(void)
{
  SdtIfCtx ctx;
  ctx.else_label = tac_new_label();
  ctx.end_label = tac_new_label();
  ctx.has_else = 0;
  if (g_if_top < SDT_STACK_MAX) {
    g_if_stack[g_if_top++] = ctx;
  }
  return ctx;
}

static void sdt_if_mark_else(void)
{
  if (g_if_top > 0) {
    g_if_stack[g_if_top - 1].has_else = 1;
  }
}

static SdtIfCtx sdt_if_peek(void)
{
  if (g_if_top > 0) {
    return g_if_stack[g_if_top - 1];
  }
  SdtIfCtx empty = { NULL, NULL, 0 };
  return empty;
}

static SdtIfCtx sdt_if_pop(void)
{
  if (g_if_top > 0) {
    return g_if_stack[--g_if_top];
  }
  SdtIfCtx empty = { NULL, NULL, 0 };
  return empty;
}

static SdtLoopCtx sdt_loop_push(void)
{
  SdtLoopCtx ctx;
  ctx.start_label = tac_new_label();
  ctx.end_label = tac_new_label();
  if (g_loop_top < SDT_STACK_MAX) {
    g_loop_stack[g_loop_top++] = ctx;
  }
  return ctx;
}

static SdtLoopCtx sdt_loop_peek(void)
{
  if (g_loop_top > 0) {
    return g_loop_stack[g_loop_top - 1];
  }
  SdtLoopCtx empty = { NULL, NULL };
  return empty;
}

static SdtLoopCtx sdt_loop_pop(void)
{
  if (g_loop_top > 0) {
    return g_loop_stack[--g_loop_top];
  }
  SdtLoopCtx empty = { NULL, NULL };
  return empty;
}

static void sdt_emit_push(int enabled)
{
  if (g_emit_top < SDT_STACK_MAX) {
    g_emit_stack[g_emit_top++] = tac_get_enabled();
  }
  tac_set_enabled(enabled);
}

static void sdt_emit_pop(void)
{
  if (g_emit_top > 0) {
    tac_set_enabled(g_emit_stack[--g_emit_top]);
  }
}

static char *sdt_format_complex(const char *real_part, const char *imag_part)
{
  const char *real_val = (real_part && real_part[0] != '\0') ? real_part : "0";
  const char *imag_val = (imag_part && imag_part[0] != '\0') ? imag_part : "0";
  size_t len = strlen(real_val) + strlen(imag_val) + strlen("complex(, )") + 1;
  char *out = (char *)malloc(len);
  if (!out) {
    return strdup("complex(0, 0)");
  }
  snprintf(out, len, "complex(%s, %s)", real_val, imag_val);
  return out;
}

static int sdt_is_array(const char *name)
{
  int is_array = 0;
  if (!name || name[0] == '\0') {
    return 0;
  }
  (void)sdt_semantic_lookup(name, NULL, &is_array);
  return is_array;
}

static int sdt_is_zero_literal(const TacValue *value)
{
  if (!value || !value->place) {
    return 0;
  }

  if (value->type != SDT_TYPE_INTEGER && value->type != SDT_TYPE_REAL) {
    return 0;
  }

  char *endptr = NULL;
  double num = strtod(value->place, &endptr);
  if (!endptr || *endptr != '\0') {
    return 0;
  }

  return num == 0.0;
}

static char *sdt_format_index(const char *base, const SdtArgList *args)
{
  const char *base_name = (base && base[0] != '\0') ? base : "";
  size_t len = strlen(base_name) + 2;

  if (args) {
    const SdtArgNode *cur = args->head;
    while (cur) {
      const char *val = (cur->place && cur->place[0] != '\0') ? cur->place : "";
      len += strlen(val);
      if (cur->next) {
        len += 2;
      }
      cur = cur->next;
    }
  }

  char *out = (char *)malloc(len + 1);
  if (!out) {
    return strdup(base_name);
  }

  size_t offset = 0;
  offset += (size_t)snprintf(out + offset, len + 1 - offset, "%s(", base_name);
  if (args) {
    const SdtArgNode *cur = args->head;
    while (cur) {
      const char *val = (cur->place && cur->place[0] != '\0') ? cur->place : "";
      offset += (size_t)snprintf(out + offset, len + 1 - offset, "%s", val);
      if (cur->next) {
        offset += (size_t)snprintf(out + offset, len + 1 - offset, ", ");
      }
      cur = cur->next;
    }
  }
  snprintf(out + offset, len + 1 - offset, ")");
  return out;
}

%}

%code requires {
#include "../ir/tac.h"
typedef struct SdtArgList SdtArgList;
}

%union {
  struct DerivationNode *node;
  char *text;
  TacValue *tac;
  SdtArgList *args;
}

%define parse.error verbose

%token PROGRAM MODULE END CONTAINS USE NONE IMPLICIT
%token INTEGER REAL LOGICAL CHARACTER TYPE CLASS END_TYPE COMPLEX
%token IF THEN ELSE DO ENDIF LEN WHILE SELECT CASE DEFAULT RANK
%token STOP PRINT CALL SUBROUTINE FUNCTION RETURN RECURSIVE RESULT
%token ALLOCATE DEALLOCATE ALLOCATED POINTER TARGET ALLOCATABLE INTENT IN OUT INOUT
%token OPEN CLOSE INQUIRE WRITE READ ERROR
%token LPAREN RPAREN COMMA COLON ASSUMED_RANK_SPECIFIER CONCAT PTR_ASSIGN
%token PP_DEFINE PP_UNDEF PP_IFDEF PP_IFNDEF PP_IF PP_ELIF PP_ELSE PP_ENDIF
%token LENGTH_SPECIFIER

%token <text> IDENTIFIER INT_CONST REAL_CONST STRING LOGICAL_CONST INTRINSIC
%token <text> ADD_OP MUL_OP REL_OP LOGICAL_OP EXPONENT
%token ASSIGN DECL_SEP DERIVED_TYPE_COMPONENT

%type <node> start compilation_units compilation_unit free_form program_unit module_unit
%type <node> program_body module_body contains_block declarations preamble pp_item
%type <node> declaration type_spec char_type_spec char_len_opt char_len_value
%type <node> attributes attribute declaration_attributes identifier_list declarator_list
%type <node> declarator array_spec_opt array_spec array_spec_list array_spec_item init_opt
%type <node> executables executable if_stmt do_stmt dowhile_stmt select_stmt
%type <node> if_else_opt
%type <node> select_rank_stmt rank_blocks rank_block rank_selector case_blocks case_block
%type <node> call_stmt return_stmt stop_stmt pointer_stmt print_stmt
%type <node> allocate_stmt deallocate_stmt
%type <node> subprogram_list subprogram
%type <node> identifier_list_opt type_def type_def_body type_def_declarations
%type <node> type_def_declaration pp_define_undef pp_if_block pp_else_opt
%type <tac> expression factor primary variable_ref assignment_stmt complex_literal
%type <tac> step_opt
%type <args> print_args argument_values primary_suffix_opt
%type <text> identifier callable_name

%left LOGICAL_OP
%nonassoc REL_OP
%left ADD_OP
%left MUL_OP
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

contains_block: CONTAINS
  {
    sdt_emit_push(0);
  }
  subprogram_list
  {
    sdt_emit_pop();
    $$ = NODE("contains_block", 2, LEAF("CONTAINS"), $3);
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
    sdt_semantic_set_implicit_none(1);
        $$ = NODE("declaration", 2, LEAF("IMPLICIT"), LEAF("NONE"));
    }
  | USE identifier
    {
        $$ = NODE("declaration", 2, LEAF("USE"), LEAF("IDENTIFIER"));
    }
  | type_def
    {
        $$ = NODE("declaration", 1, $1);
    }
  ;

type_spec: INTEGER
    {
        g_decl_type = SDT_TYPE_INTEGER;
        $$ = NODE("type_spec", 1, LEAF("INTEGER"));
    }
  | REAL
    {
        g_decl_type = SDT_TYPE_REAL;
        $$ = NODE("type_spec", 1, LEAF("REAL"));
    }
  | LOGICAL
    {
        g_decl_type = SDT_TYPE_LOGICAL;
        $$ = NODE("type_spec", 1, LEAF("LOGICAL"));
    }
  | char_type_spec
    {
        g_decl_type = SDT_TYPE_CHARACTER;
        $$ = NODE("type_spec", 1, $1);
    }
  | TYPE LPAREN identifier RPAREN
    {
        $$ = NODE("type_spec", 4, LEAF("TYPE"), LEAF("LPAREN"), LEAF("IDENTIFIER"), LEAF("RPAREN"));
    }
  | CLASS identifier
    {
        $$ = NODE("type_spec", 2, LEAF("CLASS"), LEAF("IDENTIFIER"));
    }
  | COMPLEX
    {
        g_decl_type = SDT_TYPE_COMPLEX;
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
        $$ = NODE("char_len_value", 1, LEAF("IDENTIFIER"));
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
    $$ = NODE("identifier_list", 1, LEAF("IDENTIFIER"));
    }
  | identifier COMMA identifier_list
    {
    $$ = NODE("identifier_list", 3, LEAF("IDENTIFIER"), LEAF("COMMA"), $3);
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

declarator: identifier array_spec_opt
    {
    g_decl_name = $1;
    if (g_decl_name && !sdt_semantic_declare(g_decl_name, g_decl_type, g_decl_has_array)) {
      sdt_semantic_error("Duplicate declaration of '%s'", g_decl_name);
    }
    }
    init_opt
    {
    if (g_decl_name && g_decl_init && g_decl_init->place) {
      SdtType lhs_type = SDT_TYPE_UNKNOWN;
      if (sdt_semantic_lookup(g_decl_name, &lhs_type, NULL) &&
          !sdt_semantic_assignment_compatible(lhs_type, g_decl_init->type)) {
        sdt_semantic_error("Type mismatch in declaration initialization of '%s': cannot assign %s to %s",
                           g_decl_name,
                           sdt_semantic_type_name(g_decl_init->type),
                           sdt_semantic_type_name(lhs_type));
      }
      tac_emit_assign(g_decl_name, g_decl_init->place);
    }
    g_decl_init = NULL;
    $$ = NODE("declarator", 3, LEAF("IDENTIFIER"), $2, $4);
    }
  ;

array_spec_opt: /* empty */
  {
    g_decl_has_array = 0;
    $$ = NODE0("array_spec_opt");
  }
  | array_spec
    {
        g_decl_has_array = 1;
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
        $$ = NODE("array_spec_item", 1, LEAF("expression"));
    }
  | expression COLON
    {
        $$ = NODE("array_spec_item", 2, LEAF("expression"), LEAF("COLON"));
    }
  | COLON expression
    {
        $$ = NODE("array_spec_item", 2, LEAF("COLON"), LEAF("expression"));
    }
  | expression COLON expression
    {
        $$ = NODE("array_spec_item", 3, LEAF("expression"), LEAF("COLON"), LEAF("expression"));
    }
  ;

init_opt: /* empty */
  {
    g_decl_init = NULL;
    $$ = NODE0("init_opt");
  }
  | ASSIGN expression
    {
        g_decl_init = $2;
        $$ = NODE("init_opt", 2, LEAF("ASSIGN"), LEAF("expression"));
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
    $$ = NODE0("executable");
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
    if ($1 && $1->type == SDT_TYPE_UNKNOWN && sdt_semantic_is_implicit_none()) {
      sdt_semantic_error("Use of undeclared identifier '%s' with IMPLICIT NONE in effect",
                         $1->place ? $1->place : "");
    }
    if ($1 && $3 && !sdt_semantic_assignment_compatible($1->type, $3->type)) {
      sdt_semantic_error("Type mismatch in assignment: cannot assign %s to %s",
                         sdt_semantic_type_name($3->type),
                         sdt_semantic_type_name($1->type));
    }
    if ($1 && $3) {
      tac_emit_assign($1->place, $3->place);
    }
    $$ = tac_make_typed_value(NULL, SDT_TYPE_UNKNOWN);
    }
  ;

if_stmt: IF LPAREN expression RPAREN THEN
  {
    SdtIfCtx ctx = sdt_if_push();
    if ($3 && $3->type != SDT_TYPE_LOGICAL && $3->type != SDT_TYPE_UNKNOWN) {
      sdt_semantic_error("IF condition must be LOGICAL, got %s", sdt_semantic_type_name($3->type));
    }
    if ($3) {
      tac_emit_if_false_goto($3->place, ctx.else_label);
    }
  }
  executables if_else_opt ENDIF
  {
    SdtIfCtx ctx = sdt_if_pop();
    if (ctx.has_else) {
      tac_emit_label(ctx.end_label);
    } else {
      tac_emit_label(ctx.else_label);
    }
    $$ = NODE("if_stmt", 8, LEAF("IF"), LEAF("LPAREN"), LEAF("expression"), LEAF("RPAREN"), LEAF("THEN"), $7, $8, LEAF("ENDIF"));
  }
  ;

if_else_opt: /* empty */
  {
    $$ = NODE0("if_else_opt");
  }
  | ELSE
  {
    SdtIfCtx ctx = sdt_if_peek();
    sdt_if_mark_else();
    tac_emit_goto(ctx.end_label);
    tac_emit_label(ctx.else_label);
  }
  executables
  {
    $$ = NODE("if_else_opt", 2, LEAF("ELSE"), $3);
  }
  ;

do_stmt: DO IDENTIFIER ASSIGN expression COMMA expression step_opt
  {
    SdtType loop_var_type = SDT_TYPE_UNKNOWN;
    if (!sdt_semantic_lookup($2, &loop_var_type, NULL) && sdt_semantic_is_implicit_none()) {
      sdt_semantic_error("Use of undeclared loop variable '%s' with IMPLICIT NONE in effect", $2 ? $2 : "");
    }
    if (loop_var_type != SDT_TYPE_UNKNOWN && loop_var_type != SDT_TYPE_INTEGER) {
      sdt_semantic_error("DO loop variable '%s' must be INTEGER, got %s", $2 ? $2 : "", sdt_semantic_type_name(loop_var_type));
    }
    if ($4 && $4->type != SDT_TYPE_UNKNOWN && $4->type != SDT_TYPE_INTEGER) {
      sdt_semantic_error("DO start bound must be INTEGER, got %s", sdt_semantic_type_name($4->type));
    }
    if ($6 && $6->type != SDT_TYPE_UNKNOWN && $6->type != SDT_TYPE_INTEGER) {
      sdt_semantic_error("DO end bound must be INTEGER, got %s", sdt_semantic_type_name($6->type));
    }
    if ($7 && $7->type != SDT_TYPE_UNKNOWN && $7->type != SDT_TYPE_INTEGER) {
      sdt_semantic_error("DO step must be INTEGER, got %s", sdt_semantic_type_name($7->type));
    }
    if (sdt_is_zero_literal($7)) {
      sdt_semantic_error("DO step value cannot be zero");
    }
    SdtForCtx ctx = sdt_for_push($2, $7 ? $7->place : NULL);
    if ($4) {
      tac_emit_assign($2, $4->place);
    }
    tac_emit_label(ctx.start_label);
    {
      char *cmp = tac_new_temp();
      tac_emit_binary(cmp, $2, "<=", $6 ? $6->place : "0");
      tac_emit_if_false_goto(cmp, ctx.end_label);
    }
  }
  executables END DO
    {
    SdtForCtx ctx = sdt_for_pop();
    const char *step = (ctx.step_value && ctx.step_value[0] != '\0') ? ctx.step_value : "1";
    char *next = tac_new_temp();
    tac_emit_binary(next, ctx.var_name, "+", step);
    tac_emit_assign(ctx.var_name, next);
    tac_emit_goto(ctx.start_label);
    tac_emit_label(ctx.end_label);
    $$ = NODE("do_stmt", 10, LEAF("DO"), LEAF("IDENTIFIER"), LEAF("ASSIGN"), LEAF("expression"), LEAF("COMMA"), LEAF("expression"), LEAF("step_opt"), $9, LEAF("END"), LEAF("DO"));
    }
  ;

dowhile_stmt: DO WHILE LPAREN
  {
    SdtLoopCtx ctx = sdt_loop_push();
    tac_emit_label(ctx.start_label);
  }
  expression RPAREN
  {
    SdtLoopCtx ctx = sdt_loop_peek();
    if ($5 && $5->type != SDT_TYPE_LOGICAL && $5->type != SDT_TYPE_UNKNOWN) {
      sdt_semantic_error("DO WHILE condition must be LOGICAL, got %s", sdt_semantic_type_name($5->type));
    }
    if ($5) {
      tac_emit_if_false_goto($5->place, ctx.end_label);
    }
  }
  executables END DO
  {
    SdtLoopCtx ctx = sdt_loop_pop();
    tac_emit_goto(ctx.start_label);
    tac_emit_label(ctx.end_label);
    $$ = NODE("dowhile_stmt", 8, LEAF("DO"), LEAF("WHILE"), LEAF("LPAREN"), LEAF("expression"), LEAF("RPAREN"), $8, LEAF("END"), LEAF("DO"));
  }
  ;

select_stmt: SELECT CASE LPAREN expression RPAREN
  {
    tac_emit_raw("select %s", $4 ? $4->place : "");
  }
  case_blocks END SELECT
  {
    tac_emit_raw("end_select");
    $$ = NODE("select_stmt", 8, LEAF("SELECT"), LEAF("CASE"), LEAF("LPAREN"), LEAF("expression"), LEAF("RPAREN"), $7, LEAF("END"), LEAF("SELECT"));
  }
  ;

select_rank_stmt: SELECT RANK LPAREN identifier RPAREN
  {
    tac_emit_raw("select_rank %s", $4 ? $4 : "");
  }
  rank_blocks END SELECT
  {
    tac_emit_raw("end_select_rank");
    $$ = NODE("select_rank_stmt", 8, LEAF("SELECT"), LEAF("RANK"), LEAF("LPAREN"), LEAF("IDENTIFIER"), LEAF("RPAREN"), $7, LEAF("END"), LEAF("SELECT"));
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

rank_block: RANK LPAREN rank_selector RPAREN
    {
        tac_emit_raw("rank_case");
    }
    executables
    {
        $$ = NODE("rank_block", 5, LEAF("RANK"), LEAF("LPAREN"), $3, LEAF("RPAREN"), $6);
    }
  | RANK DEFAULT
    {
        tac_emit_raw("rank_default");
    }
    executables
    {
        $$ = NODE("rank_block", 3, LEAF("RANK"), LEAF("DEFAULT"), $4);
    }
  ;

rank_selector: INT_CONST
    {
        $$ = NODE("rank_selector", 1, LEAF("INT_CONST"));
    }
  | MUL_OP
    {
        $$ = NODE("rank_selector", 1, LEAF("MUL_OP"));
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

case_block: CASE LPAREN expression RPAREN
    {
    tac_emit_raw("case %s", $3 ? $3->place : "");
    }
    executables
    {
    $$ = NODE("case_block", 5, LEAF("CASE"), LEAF("LPAREN"), LEAF("expression"), LEAF("RPAREN"), $6);
    }
  | CASE DEFAULT
    {
        tac_emit_raw("case_default");
    }
    executables
    {
        $$ = NODE("case_block", 3, LEAF("CASE"), LEAF("DEFAULT"), $4);
    }
  ;

call_stmt: CALL callable_name LPAREN argument_values RPAREN
    {
        if ($4) {
            SdtArgNode *arg = $4->head;
            while (arg) {
                tac_emit_raw("param %s", arg->place ? arg->place : "");
                arg = arg->next;
            }
            tac_emit_raw("call %s, %d", $2 ? $2 : "", $4->count);
        } else {
            tac_emit_raw("call %s, 0", $2 ? $2 : "");
        }
        $$ = NODE("call_stmt", 5, LEAF("CALL"), LEAF("callable_name"), LEAF("LPAREN"), LEAF("argument_values"), LEAF("RPAREN"));
    }
  ;

callable_name: identifier
    {
    $$ = $1;
    }
  | INTRINSIC
    {
        $$ = $1;
    }
  ;

return_stmt: RETURN
    {
        tac_emit_raw("return");
        $$ = NODE("return_stmt", 1, LEAF("RETURN"));
    }
  ;

stop_stmt: STOP
    {
        tac_emit_raw("stop");
        $$ = NODE("stop_stmt", 1, LEAF("STOP"));
    }
  | STOP INT_CONST
    {
        tac_emit_raw("stop %s", $2 ? $2 : "");
        $$ = NODE("stop_stmt", 2, LEAF("STOP"), LEAF("INT_CONST"));
    }
  | STOP STRING
    {
        tac_emit_raw("stop %s", $2 ? $2 : "");
        $$ = NODE("stop_stmt", 2, LEAF("STOP"), LEAF("STRING"));
    }
  ;

pointer_stmt: variable_ref PTR_ASSIGN variable_ref
    {
    if ($1 && $3) {
      tac_emit_raw("%s => %s", $1->place, $3->place);
    }
    $$ = NODE("pointer_stmt", 3, LEAF("variable_ref"), LEAF("PTR_ASSIGN"), LEAF("variable_ref"));
    }
  ;

step_opt: /* empty */
  {
    $$ = tac_make_typed_value(strdup("1"), SDT_TYPE_INTEGER);
  }
  | COMMA expression
    {
        $$ = $2;
    }
  ;

print_stmt: PRINT MUL_OP COMMA print_args
    {
        if ($4) {
            SdtArgNode *arg = $4->head;
            while (arg) {
                tac_emit_raw("print %s", arg->place ? arg->place : "");
                arg = arg->next;
            }
        }
    $$ = NODE("print_stmt", 4, LEAF("PRINT"), LEAF("MUL_OP"), LEAF("COMMA"), LEAF("print_args"));
    }
  ;

print_args: expression
    {
    $$ = sdt_arg_list_prepend($1 ? $1->place : "", sdt_arg_list_empty());
    }
  | print_args COMMA expression
    {
    $$ = sdt_arg_list_append($1, $3 ? $3->place : "");
    }
  ;

allocate_stmt: ALLOCATE LPAREN argument_values RPAREN
    {
        if ($3) {
            SdtArgNode *arg = $3->head;
            while (arg) {
                tac_emit_raw("allocate %s", arg->place ? arg->place : "");
                arg = arg->next;
            }
        }
        $$ = NODE("allocate_stmt", 4, LEAF("ALLOCATE"), LEAF("LPAREN"), LEAF("argument_values"), LEAF("RPAREN"));
    }
  ;

deallocate_stmt: DEALLOCATE LPAREN argument_values RPAREN
    {
        if ($3) {
            SdtArgNode *arg = $3->head;
            while (arg) {
                tac_emit_raw("deallocate %s", arg->place ? arg->place : "");
                arg = arg->next;
            }
        }
        $$ = NODE("deallocate_stmt", 4, LEAF("DEALLOCATE"), LEAF("LPAREN"), LEAF("argument_values"), LEAF("RPAREN"));
    }
  ;

  expression: expression ADD_OP expression
    {
    char *op = $2;
    char *temp = tac_new_temp();
    int ok = 1;
    SdtType result_type = sdt_semantic_eval_binary(op, $1 ? $1->type : SDT_TYPE_UNKNOWN, $3 ? $3->type : SDT_TYPE_UNKNOWN, &ok);
    if (!ok) {
      sdt_semantic_error("Invalid operands for operator '%s': %s and %s",
                         op ? op : "",
                         sdt_semantic_type_name($1 ? $1->type : SDT_TYPE_UNKNOWN),
                         sdt_semantic_type_name($3 ? $3->type : SDT_TYPE_UNKNOWN));
    }
    if ($1 && $3) {
      tac_emit_binary(temp, $1->place, op, $3->place);
    }
    $$ = tac_make_typed_value(temp, result_type);
    free(op);
    }
  | expression MUL_OP expression
    {
    char *op = $2;
    char *temp = tac_new_temp();
    int ok = 1;
    SdtType result_type = sdt_semantic_eval_binary(op, $1 ? $1->type : SDT_TYPE_UNKNOWN, $3 ? $3->type : SDT_TYPE_UNKNOWN, &ok);
    if (!ok) {
      sdt_semantic_error("Invalid operands for operator '%s': %s and %s",
                         op ? op : "",
                         sdt_semantic_type_name($1 ? $1->type : SDT_TYPE_UNKNOWN),
                         sdt_semantic_type_name($3 ? $3->type : SDT_TYPE_UNKNOWN));
    }
    if ($1 && $3) {
      tac_emit_binary(temp, $1->place, op, $3->place);
    }
    $$ = tac_make_typed_value(temp, result_type);
    free(op);
    }
  | expression EXPONENT expression
    {
    char *op = $2;
    char *temp = tac_new_temp();
    int ok = 1;
    SdtType result_type = sdt_semantic_eval_binary(op, $1 ? $1->type : SDT_TYPE_UNKNOWN, $3 ? $3->type : SDT_TYPE_UNKNOWN, &ok);
    if (!ok) {
      sdt_semantic_error("Invalid operands for operator '%s': %s and %s",
                         op ? op : "",
                         sdt_semantic_type_name($1 ? $1->type : SDT_TYPE_UNKNOWN),
                         sdt_semantic_type_name($3 ? $3->type : SDT_TYPE_UNKNOWN));
    }
    if ($1 && $3) {
      tac_emit_binary(temp, $1->place, op, $3->place);
    }
    $$ = tac_make_typed_value(temp, result_type);
    free(op);
    }
  | expression REL_OP expression
    {
    char *op = $2;
    char *temp = tac_new_temp();
    int ok = 1;
    SdtType result_type = sdt_semantic_eval_binary(op, $1 ? $1->type : SDT_TYPE_UNKNOWN, $3 ? $3->type : SDT_TYPE_UNKNOWN, &ok);
    if (!ok) {
      sdt_semantic_error("Type mismatch in comparison '%s': %s and %s",
                         op ? op : "",
                         sdt_semantic_type_name($1 ? $1->type : SDT_TYPE_UNKNOWN),
                         sdt_semantic_type_name($3 ? $3->type : SDT_TYPE_UNKNOWN));
    }
    if ($1 && $3) {
      tac_emit_binary(temp, $1->place, op, $3->place);
    }
    $$ = tac_make_typed_value(temp, result_type);
    free(op);
    }
  | expression LOGICAL_OP expression
    {
    char *op = $2;
    char *temp = tac_new_temp();
    int ok = 1;
    SdtType result_type = sdt_semantic_eval_binary(op, $1 ? $1->type : SDT_TYPE_UNKNOWN, $3 ? $3->type : SDT_TYPE_UNKNOWN, &ok);
    if (!ok) {
      sdt_semantic_error("Invalid operands for logical operator '%s': %s and %s",
                         op ? op : "",
                         sdt_semantic_type_name($1 ? $1->type : SDT_TYPE_UNKNOWN),
                         sdt_semantic_type_name($3 ? $3->type : SDT_TYPE_UNKNOWN));
    }
    if ($1 && $3) {
      tac_emit_binary(temp, $1->place, op, $3->place);
    }
    $$ = tac_make_typed_value(temp, result_type);
    free(op);
    }
  | factor
    {
    $$ = $1;
    }
  | ADD_OP expression %prec UNARY
    {
    char *op = $1;
    char *temp = tac_new_temp();
    int ok = 1;
    SdtType result_type = sdt_semantic_eval_unary(op, $2 ? $2->type : SDT_TYPE_UNKNOWN, &ok);
    if (!ok) {
      sdt_semantic_error("Invalid operand for unary operator '%s': %s",
                         op ? op : "",
                         sdt_semantic_type_name($2 ? $2->type : SDT_TYPE_UNKNOWN));
    }
    if ($2) {
      tac_emit_unary(temp, op, $2->place);
    }
    $$ = tac_make_typed_value(temp, result_type);
    free(op);
    }
  | LOGICAL_OP expression %prec UNARY
    {
    char *op = $1;
    char *temp = tac_new_temp();
    int ok = 1;
    SdtType result_type = sdt_semantic_eval_unary(op, $2 ? $2->type : SDT_TYPE_UNKNOWN, &ok);
    if (!ok) {
      sdt_semantic_error("Invalid operand for unary operator '%s': %s",
                         op ? op : "",
                         sdt_semantic_type_name($2 ? $2->type : SDT_TYPE_UNKNOWN));
    }
    if ($2) {
      tac_emit_unary(temp, op, $2->place);
    }
    $$ = tac_make_typed_value(temp, result_type);
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
        $$ = tac_make_typed_value($1, SDT_TYPE_INTEGER);
    }
  | REAL_CONST
    {
        $$ = tac_make_typed_value($1, SDT_TYPE_REAL);
    }
  | LOGICAL_CONST
    {
        $$ = tac_make_typed_value($1, SDT_TYPE_LOGICAL);
    }
  | STRING
    {
        $$ = tac_make_typed_value($1, SDT_TYPE_CHARACTER);
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
        int is_array = sdt_is_array($1 ? $1->place : NULL);
        if (is_array) {
          char *indexed = sdt_format_index($1 ? $1->place : NULL, $2);
          $$ = tac_make_typed_value(indexed, $1 ? $1->type : SDT_TYPE_UNKNOWN);
        } else {
          SdtType declared_type = SDT_TYPE_UNKNOWN;
          if ($1 && $1->place && sdt_semantic_lookup($1->place, &declared_type, NULL)) {
            sdt_semantic_error("Identifier '%s' is not an array or procedure but used with ()", $1->place);
          }
          int argc = 0;
          SdtArgNode *arg = $2->head;
          while (arg) {
            tac_emit_raw("param %s", arg->place ? arg->place : "");
            arg = arg->next;
          }
          argc = $2->count;
          char *temp = tac_new_temp();
          tac_emit_raw("%s = call %s, %d", temp, $1 ? $1->place : "", argc);
          $$ = tac_make_typed_value(temp, SDT_TYPE_UNKNOWN);
        }
      } else {
        if ($1 && $1->type == SDT_TYPE_UNKNOWN && sdt_semantic_is_implicit_none()) {
          sdt_semantic_error("Use of undeclared identifier '%s' with IMPLICIT NONE in effect",
                             $1->place ? $1->place : "");
        }
        $$ = $1;
      }
    }
  ;

complex_literal: LPAREN expression COMMA expression RPAREN
  {
  char *text = sdt_format_complex($2 ? $2->place : NULL, $4 ? $4->place : NULL);
  $$ = tac_make_typed_value(text, SDT_TYPE_COMPLEX);
  }
  ;

primary_suffix_opt: /* empty */
  {
    $$ = NULL;
  }
  | LPAREN argument_values RPAREN
    {
        $$ = $2;
    }
  ;

variable_ref: identifier
    {
    SdtType var_type = SDT_TYPE_UNKNOWN;
    (void)sdt_semantic_lookup($1, &var_type, NULL);
    $$ = tac_make_typed_value($1, var_type);
    }
  | variable_ref DERIVED_TYPE_COMPONENT identifier
    {
    char *combined = sdt_append_derived($1 ? $1->place : NULL, $3);
    $$ = tac_make_typed_value(combined, SDT_TYPE_UNKNOWN);
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
        $$ = NODE("subprogram", 8, LEAF("SUBROUTINE"), LEAF("IDENTIFIER"), LEAF("LPAREN"), $4, LEAF("RPAREN"), $6, LEAF("END"), LEAF("SUBROUTINE"));
    }
  | SUBROUTINE identifier LPAREN identifier_list_opt RPAREN program_body END SUBROUTINE identifier
    {
        $$ = NODE("subprogram", 9, LEAF("SUBROUTINE"), LEAF("IDENTIFIER"), LEAF("LPAREN"), $4, LEAF("RPAREN"), $6, LEAF("END"), LEAF("SUBROUTINE"), LEAF("IDENTIFIER"));
    }
  | FUNCTION identifier LPAREN identifier_list_opt RPAREN program_body END FUNCTION
    {
        $$ = NODE("subprogram", 8, LEAF("FUNCTION"), LEAF("IDENTIFIER"), LEAF("LPAREN"), $4, LEAF("RPAREN"), $6, LEAF("END"), LEAF("FUNCTION"));
    }
  | FUNCTION identifier LPAREN identifier_list_opt RPAREN program_body END FUNCTION identifier
    {
        $$ = NODE("subprogram", 9, LEAF("FUNCTION"), LEAF("IDENTIFIER"), LEAF("LPAREN"), $4, LEAF("RPAREN"), $6, LEAF("END"), LEAF("FUNCTION"), LEAF("IDENTIFIER"));
    }
  | RECURSIVE FUNCTION identifier LPAREN identifier_list_opt RPAREN RESULT LPAREN identifier RPAREN program_body END FUNCTION
    {
        $$ = NODE("subprogram", 13, LEAF("RECURSIVE"), LEAF("FUNCTION"), LEAF("IDENTIFIER"), LEAF("LPAREN"), $5, LEAF("RPAREN"), LEAF("RESULT"), LEAF("LPAREN"), LEAF("IDENTIFIER"), LEAF("RPAREN"), $11, LEAF("END"), LEAF("FUNCTION"));
    }
  | RECURSIVE FUNCTION identifier LPAREN identifier_list_opt RPAREN RESULT LPAREN identifier RPAREN program_body END FUNCTION identifier
    {
        $$ = NODE("subprogram", 14, LEAF("RECURSIVE"), LEAF("FUNCTION"), LEAF("IDENTIFIER"), LEAF("LPAREN"), $5, LEAF("RPAREN"), LEAF("RESULT"), LEAF("LPAREN"), LEAF("IDENTIFIER"), LEAF("RPAREN"), $11, LEAF("END"), LEAF("FUNCTION"), LEAF("IDENTIFIER"));
    }
  ;

argument_values: /* empty */
  {
    $$ = sdt_arg_list_empty();
  }
  | expression
    {
      $$ = sdt_arg_list_prepend($1 ? $1->place : "", sdt_arg_list_empty());
    }
  | expression COMMA argument_values
    {
      $$ = sdt_arg_list_prepend($1 ? $1->place : "", $3);
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
        $$ = $1;
    }
  | RESULT
    {
        $$ = strdup("result");
    }
  ;

type_def: TYPE DECL_SEP identifier type_def_body END_TYPE identifier
    {
    $$ = NODE("type_def", 6, LEAF("TYPE"), LEAF("DECL_SEP"), LEAF("IDENTIFIER"), $4, LEAF("END_TYPE"), LEAF("IDENTIFIER"));
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
        $$ = NODE("pp_define_undef", 2, LEAF("PP_DEFINE"), LEAF("IDENTIFIER"));
    }
  | PP_DEFINE identifier INT_CONST
    {
        $$ = NODE("pp_define_undef", 3, LEAF("PP_DEFINE"), LEAF("IDENTIFIER"), LEAF("INT_CONST"));
    }
  | PP_UNDEF identifier
    {
        $$ = NODE("pp_define_undef", 2, LEAF("PP_UNDEF"), LEAF("IDENTIFIER"));
    }
  ;

pp_if_block: PP_IFDEF identifier declarations pp_else_opt PP_ENDIF
    {
        $$ = NODE("pp_if_block", 5, LEAF("PP_IFDEF"), LEAF("IDENTIFIER"), $3, $4, LEAF("PP_ENDIF"));
    }
  | PP_IFNDEF identifier declarations pp_else_opt PP_ENDIF
    {
        $$ = NODE("pp_if_block", 5, LEAF("PP_IFNDEF"), LEAF("IDENTIFIER"), $3, $4, LEAF("PP_ENDIF"));
    }
  | PP_IF identifier declarations pp_else_opt PP_ENDIF
    {
        $$ = NODE("pp_if_block", 5, LEAF("PP_IF"), LEAF("IDENTIFIER"), $3, $4, LEAF("PP_ENDIF"));
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
extern int token_column;
extern int paren_balance;
extern int if_balance;
extern char current_line[];

void yyerror(const char *s) {
  const char *code_prefix = "-> Code: ";
  const char *near_text = (yytext && yytext[0] != '\0') ? yytext : "EOF";
  const char *specific_hint = NULL;

  fprintf(stderr, "\x1b[31mPARSE ERROR\x1b[0m\n");
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

  if (paren_balance > 0) {
    specific_hint = "Missing closing ')'";
  } else if (if_balance > 0) {
    specific_hint = "Missing ENDIF for an IF block";
  } 
  if (specific_hint) {
    fprintf(stderr, "Hint    : %s\n", specific_hint);
  } else {
    fprintf(stderr, "Hint    : Check syntax near the token and ensure blocks and parentheses are closed.\n");
  }
}

extern FILE *yyin;

int main(int argc, char **argv) {
  DTPrintMode mode = DT_POSTORDER;
  int print_tree = 0;

    if (argc < 2) {
        printf("Usage: ./compiler <file> [--tree]\n");
        return 1;
    }

    // check optional flags
    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "--tree") == 0) {
          mode = DT_TREE;
          print_tree = 1;
        }
    }

    FILE *file = fopen(argv[1], "r");
    if (!file) {
        perror("Error opening file");
        return 1;
    }

    yyin = file;

    printf("Starting parse\n");
    tac_init();
    sdt_semantic_reset();

    if (yyparse() == 0) {
        printf("Parsing done!\n");
      if (sdt_semantic_error_count() > 0) {
        fprintf(stderr, "\nSemantic analysis failed with %d error(s).\n", sdt_semantic_error_count());
        fclose(file);
        return 1;
      }
      printf("\nTAC Output:\n");
      tac_print(stdout);
      if (print_tree) {
        printf("\nDerivation Tree Output:\n");
        dt_print(dt_get_root(), mode);
      }
    } else {
        printf("Parsing failed.\n");
    }

    fclose(file);
    return 0;
}
