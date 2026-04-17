%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "derivation_tree.h"
#include "../ir/tac.h"

void yyerror(const char *s);
int yylex();

#define NODE(name, count, ...) dt_make_node((name), (count), __VA_ARGS__)
#define NODE0(name) dt_make_node((name), 0)
#define LEAF(name) dt_make_leaf((name))

static char *sdt_append_derived(const char *base, const char *field)
{
  if (!field) return NULL;
  if (!base || base[0] == '\0') return strdup(field);

  size_t base_len = strlen(base);
  size_t field_len = strlen(field);
  size_t total = base_len + 1 + field_len;
  char *combined = (char *)malloc(total + 1);
  if (!combined) return strdup(field);

  memcpy(combined, base, base_len);
  combined[base_len] = '%';
  memcpy(combined + base_len + 1, field, field_len);
  combined[total] = '\0';
  return combined;
}

// Context Manager for execution rings (Solves the Module vs Execution bug)
typedef enum { CTX_GLOBAL, CTX_MODULE, CTX_PROGRAM, CTX_FUNCTION } ParseContext;
static ParseContext g_ctx = CTX_GLOBAL;

#define EMIT_IF_EXEC(stmt) if (g_ctx == CTX_PROGRAM || g_ctx == CTX_FUNCTION) { stmt; }

typedef struct {
  char *else_label;
  char *end_label;
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
static const char *g_decl_name = NULL;
static TacValue *g_decl_init = NULL;
static int g_decl_has_array = 0;

#define SDT_ARRAY_MAX 256
static char *g_array_names[SDT_ARRAY_MAX];
static int g_array_count = 0;

static SdtArgNode *sdt_arg_node_new(const char *place) {
  SdtArgNode *node = (SdtArgNode *)malloc(sizeof(SdtArgNode));
  if (!node) return NULL;
  node->place = place ? strdup(place) : strdup("");
  node->next = NULL;
  return node;
}

static SdtArgList *sdt_arg_list_empty(void) {
  SdtArgList *list = (SdtArgList *)malloc(sizeof(SdtArgList));
  if (!list) return NULL;
  list->head = NULL;
  list->count = 0;
  return list;
}

static SdtArgList *sdt_arg_list_prepend(const char *place, SdtArgList *tail) {
  SdtArgList *list = tail ? tail : sdt_arg_list_empty();
  if (!list) return NULL;
  SdtArgNode *node = sdt_arg_node_new(place);
  if (!node) return list;
  node->next = list->head;
  list->head = node;
  list->count++;
  return list;
}

static SdtArgList *sdt_arg_list_append(SdtArgList *list, const char *place) {
  SdtArgList *out = list ? list : sdt_arg_list_empty();
  if (!out) return NULL;
  SdtArgNode *node = sdt_arg_node_new(place);
  if (!node) return out;
  if (!out->head) {
    out->head = node;
  } else {
    SdtArgNode *cur = out->head;
    while (cur->next) cur = cur->next;
    cur->next = node;
  }
  out->count++;
  return out;
}

static SdtForCtx sdt_for_push(const char *var_name, const char *step_value) {
  SdtForCtx ctx;
  ctx.var_name = var_name ? strdup(var_name) : strdup("");
  ctx.step_value = step_value ? strdup(step_value) : strdup("1");
  ctx.start_label = tac_new_label();
  ctx.end_label = tac_new_label();
  if (g_for_top < SDT_STACK_MAX) g_for_stack[g_for_top++] = ctx;
  return ctx;
}

static SdtForCtx sdt_for_pop(void) {
  if (g_for_top > 0) return g_for_stack[--g_for_top];
  SdtForCtx empty = { NULL, NULL, NULL, NULL };
  return empty;
}

static SdtIfCtx sdt_if_push(void) {
  SdtIfCtx ctx;
  ctx.else_label = tac_new_label();
  ctx.end_label = tac_new_label();
  if (g_if_top < SDT_STACK_MAX) g_if_stack[g_if_top++] = ctx;
  return ctx;
}

static SdtIfCtx sdt_if_peek(void) {
  if (g_if_top > 0) return g_if_stack[g_if_top - 1];
  SdtIfCtx empty = { NULL, NULL };
  return empty;
}

static SdtIfCtx sdt_if_pop(void) {
  if (g_if_top > 0) return g_if_stack[--g_if_top];
  SdtIfCtx empty = { NULL, NULL };
  return empty;
}

static SdtLoopCtx sdt_loop_push(void) {
  SdtLoopCtx ctx;
  ctx.start_label = tac_new_label();
  ctx.end_label = tac_new_label();
  if (g_loop_top < SDT_STACK_MAX) g_loop_stack[g_loop_top++] = ctx;
  return ctx;
}

static SdtLoopCtx sdt_loop_peek(void) {
  if (g_loop_top > 0) return g_loop_stack[g_loop_top - 1];
  SdtLoopCtx empty = { NULL, NULL };
  return empty;
}

static SdtLoopCtx sdt_loop_pop(void) {
  if (g_loop_top > 0) return g_loop_stack[--g_loop_top];
  SdtLoopCtx empty = { NULL, NULL };
  return empty;
}

static char *sdt_format_complex(const char *real_part, const char *imag_part) {
  const char *real_val = (real_part && real_part[0] != '\0') ? real_part : "0";
  const char *imag_val = (imag_part && imag_part[0] != '\0') ? imag_part : "0";
  size_t len = strlen(real_val) + strlen(imag_val) + strlen("complex(, )") + 1;
  char *out = (char *)malloc(len);
  if (!out) return strdup("complex(0, 0)");
  snprintf(out, len, "complex(%s, %s)", real_val, imag_val);
  return out;
}

static void sdt_register_array(const char *name) {
  if (!name || name[0] == '\0') return;
  for (int i = 0; i < g_array_count; ++i) {
    if (g_array_names[i] && strcmp(g_array_names[i], name) == 0) return;
  }
  if (g_array_count < SDT_ARRAY_MAX) g_array_names[g_array_count++] = strdup(name);
}

static int sdt_is_array(const char *name) {
  if (!name || name[0] == '\0') return 0;
  for (int i = 0; i < g_array_count; ++i) {
    if (g_array_names[i] && strcmp(g_array_names[i], name) == 0) return 1;
  }
  return 0;
}

static char *sdt_format_index(const char *base, const SdtArgList *args) {
  const char *base_name = (base && base[0] != '\0') ? base : "";
  size_t len = strlen(base_name) + 2;
  if (args) {
    const SdtArgNode *cur = args->head;
    while (cur) {
      const char *val = (cur->place && cur->place[0] != '\0') ? cur->place : "";
      len += strlen(val);
      if (cur->next) len += 2;
      cur = cur->next;
    }
  }
  char *out = (char *)malloc(len + 1);
  if (!out) return strdup(base_name);
  size_t offset = 0;
  offset += (size_t)snprintf(out + offset, len + 1 - offset, "%s(", base_name);
  if (args) {
    const SdtArgNode *cur = args->head;
    while (cur) {
      const char *val = (cur->place && cur->place[0] != '\0') ? cur->place : "";
      offset += (size_t)snprintf(out + offset, len + 1 - offset, "%s", val);
      if (cur->next) offset += (size_t)snprintf(out + offset, len + 1 - offset, ", ");
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
%type <node> select_rank_stmt rank_blocks rank_block rank_selector case_blocks case_block
%type <node> call_stmt return_stmt stop_stmt pointer_stmt print_stmt
%type <node> allocate_stmt deallocate_stmt
%type <node> subprogram_list subprogram
%type <node> identifier_list_opt type_def type_def_body type_def_declarations
%type <node> type_def_declaration pp_define_undef pp_if_block pp_else_opt
%type <tac> expression factor primary variable_ref assignment_stmt complex_literal
%type <tac> step_opt
%type <args> print_args argument_values primary_suffix_opt
%type <text> identifier callable_name opt_identifier

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
    { $$ = NODE("compilation_units", 1, $1); }
  | compilation_units compilation_unit
    { $$ = NODE("compilation_units", 2, $1, $2); }
  ;

compilation_unit: program_unit
    { $$ = NODE("compilation_unit", 1, $1); }
  | module_unit
    { $$ = NODE("compilation_unit", 1, $1); }
  ;

free_form: preamble declarations executables
    { $$ = NODE("free_form", 3, $1, $2, $3); }
  ;

program_unit: PROGRAM IDENTIFIER 
    { 
        g_ctx = CTX_PROGRAM; 
        tac_emit_quad("program", $2, "-", "-"); 
    } 
    program_body END PROGRAM opt_identifier
    {
        tac_emit_quad("end_prog", "-", "-", "-");
        g_ctx = CTX_GLOBAL;
        if ($7) {
            $$ = NODE("program_unit", 6, LEAF("PROGRAM"), LEAF($2), $4, LEAF("END"), LEAF("PROGRAM"), LEAF($7));
        } else {
            $$ = NODE("program_unit", 5, LEAF("PROGRAM"), LEAF($2), $4, LEAF("END"), LEAF("PROGRAM"));
        }
    }
  ;

module_unit: MODULE IDENTIFIER 
    { g_ctx = CTX_MODULE; } 
    module_body END MODULE opt_identifier
    {
        g_ctx = CTX_GLOBAL;
        if ($7) {
            $$ = NODE("module_unit", 6, LEAF("MODULE"), LEAF($2), $4, LEAF("END"), LEAF("MODULE"), LEAF($7));
        } else {
            $$ = NODE("module_unit", 5, LEAF("MODULE"), LEAF($2), $4, LEAF("END"), LEAF("MODULE"));
        }
    }
  ;

program_body: preamble declarations executables contains_block
    { $$ = NODE("program_body", 4, $1, $2, $3, $4); }
  ;

module_body: preamble declarations executables contains_block
    { $$ = NODE("module_body", 4, $1, $2, $3, $4); }
  ;

contains_block: CONTAINS subprogram_list
  { $$ = NODE("contains_block", 2, LEAF("CONTAINS"), $2); }
  | /* empty */
  { $$ = NODE0("contains_block"); }
  ;

declarations: /* empty */
  { $$ = NODE0("declarations"); }
  | declaration declarations
  { $$ = NODE("declarations", 2, $1, $2); }
  ;

preamble: /* empty */
  { $$ = NODE0("preamble"); }
  | preamble pp_item
  { $$ = NODE("preamble", 2, $1, $2); }
  ;

pp_item: pp_define_undef { $$ = NODE("pp_item", 1, $1); }
  | pp_if_block { $$ = NODE("pp_item", 1, $1); }
  ;

declaration: type_spec declaration_attributes DECL_SEP declarator_list
    { $$ = NODE("declaration", 4, $1, $2, LEAF("DECL_SEP"), $4); }
  | IMPLICIT NONE
    { $$ = NODE("declaration", 2, LEAF("IMPLICIT"), LEAF("NONE")); }
  | USE identifier
    { $$ = NODE("declaration", 2, LEAF("USE"), LEAF("IDENTIFIER")); }
  | type_def
    { $$ = NODE("declaration", 1, $1); }
  ;

type_spec: INTEGER { $$ = NODE("type_spec", 1, LEAF("INTEGER")); }
  | REAL { $$ = NODE("type_spec", 1, LEAF("REAL")); }
  | LOGICAL { $$ = NODE("type_spec", 1, LEAF("LOGICAL")); }
  | char_type_spec { $$ = NODE("type_spec", 1, $1); }
  | TYPE LPAREN identifier RPAREN { $$ = NODE("type_spec", 4, LEAF("TYPE"), LEAF("LPAREN"), LEAF("IDENTIFIER"), LEAF("RPAREN")); }
  | CLASS identifier { $$ = NODE("type_spec", 2, LEAF("CLASS"), LEAF("IDENTIFIER")); }
  | COMPLEX { $$ = NODE("type_spec", 1, LEAF("COMPLEX")); }
  ;

char_type_spec: CHARACTER char_len_opt { $$ = NODE("char_type_spec", 2, LEAF("CHARACTER"), $2); }
  ;

char_len_opt: /* empty */ { $$ = NODE0("char_len_opt"); }
  | LPAREN LENGTH_SPECIFIER ASSIGN char_len_value RPAREN { $$ = NODE("char_len_opt", 5, LEAF("LPAREN"), LEAF("LENGTH_SPECIFIER"), LEAF("ASSIGN"), $4, LEAF("RPAREN")); }
  ;

char_len_value: COLON { $$ = NODE("char_len_value", 1, LEAF("COLON")); }
  | INT_CONST { $$ = NODE("char_len_value", 1, LEAF("INT_CONST")); }
  | identifier { $$ = NODE("char_len_value", 1, LEAF("IDENTIFIER")); }
  ;

attributes: attribute { $$ = NODE("attributes", 1, $1); }
  | attribute COMMA attributes { $$ = NODE("attributes", 3, $1, LEAF("COMMA"), $3); }
  ;

attribute: ALLOCATABLE { $$ = NODE("attribute", 1, LEAF("ALLOCATABLE")); }
  | POINTER { $$ = NODE("attribute", 1, LEAF("POINTER")); }
  | TARGET { $$ = NODE("attribute", 1, LEAF("TARGET")); }
  | INTENT LPAREN IN RPAREN { $$ = NODE("attribute", 4, LEAF("INTENT"), LEAF("LPAREN"), LEAF("IN"), LEAF("RPAREN")); }
  | INTENT LPAREN OUT RPAREN { $$ = NODE("attribute", 4, LEAF("INTENT"), LEAF("LPAREN"), LEAF("OUT"), LEAF("RPAREN")); }
  | INTENT LPAREN INOUT RPAREN { $$ = NODE("attribute", 4, LEAF("INTENT"), LEAF("LPAREN"), LEAF("INOUT"), LEAF("RPAREN")); }
  ;

declaration_attributes: /* empty */ { $$ = NODE0("declaration_attributes"); }
  | COMMA attributes { $$ = NODE("declaration_attributes", 2, LEAF("COMMA"), $2); }
  ;

identifier_list: identifier { $$ = NODE("identifier_list", 1, LEAF("IDENTIFIER")); }
  | identifier COMMA identifier_list { $$ = NODE("identifier_list", 3, LEAF("IDENTIFIER"), LEAF("COMMA"), $3); }
  ;

declarator_list: declarator { $$ = NODE("declarator_list", 1, $1); }
  | declarator COMMA declarator_list { $$ = NODE("declarator_list", 3, $1, LEAF("COMMA"), $3); }
  ;

declarator: identifier array_spec_opt
    { g_decl_name = $1; }
    init_opt
    {
      if (g_decl_name && g_decl_init && g_decl_init->place) {
        EMIT_IF_EXEC(tac_emit_assign(g_decl_name, g_decl_init->place));
      }
      if (g_decl_name && g_decl_has_array) { sdt_register_array(g_decl_name); }
      g_decl_init = NULL;
      $$ = NODE("declarator", 3, LEAF("IDENTIFIER"), $2, $4);
    }
  ;

array_spec_opt: /* empty */ { g_decl_has_array = 0; $$ = NODE0("array_spec_opt"); }
  | array_spec { g_decl_has_array = 1; $$ = NODE("array_spec_opt", 1, $1); }
  ;

array_spec: LPAREN array_spec_list RPAREN { $$ = NODE("array_spec", 3, LEAF("LPAREN"), $2, LEAF("RPAREN")); }
  ;

array_spec_list: array_spec_item { $$ = NODE("array_spec_list", 1, $1); }
  | array_spec_list COMMA array_spec_item { $$ = NODE("array_spec_list", 3, $1, LEAF("COMMA"), $3); }
  ;

array_spec_item: ASSUMED_RANK_SPECIFIER { $$ = NODE("array_spec_item", 1, LEAF("ASSUMED_RANK_SPECIFIER")); }
  | COLON { $$ = NODE("array_spec_item", 1, LEAF("COLON")); }
  | expression { $$ = NODE("array_spec_item", 1, LEAF("expression")); }
  | expression COLON { $$ = NODE("array_spec_item", 2, LEAF("expression"), LEAF("COLON")); }
  | COLON expression { $$ = NODE("array_spec_item", 2, LEAF("COLON"), LEAF("expression")); }
  | expression COLON expression { $$ = NODE("array_spec_item", 3, LEAF("expression"), LEAF("COLON"), LEAF("expression")); }
  ;

init_opt: /* empty */ { g_decl_init = NULL; $$ = NODE0("init_opt"); }
  | ASSIGN expression { g_decl_init = $2; $$ = NODE("init_opt", 2, LEAF("ASSIGN"), LEAF("expression")); }
  ;

executables: /* empty */ { $$ = NODE0("executables"); }
  | executables executable { $$ = NODE("executables", 2, $1, $2); }
  ;

executable: assignment_stmt { $$ = NODE0("executable"); }
  | if_stmt { $$ = NODE("executable", 1, $1); }
  | print_stmt { $$ = NODE("executable", 1, $1); }
  | allocate_stmt { $$ = NODE("executable", 1, $1); }
  | deallocate_stmt { $$ = NODE("executable", 1, $1); }
  | do_stmt { $$ = NODE("executable", 1, $1); }
  | dowhile_stmt { $$ = NODE("executable", 1, $1); }
  | select_rank_stmt { $$ = NODE("executable", 1, $1); }
  | select_stmt { $$ = NODE("executable", 1, $1); }
  | call_stmt { $$ = NODE("executable", 1, $1); }
  | return_stmt { $$ = NODE("executable", 1, $1); }
  | stop_stmt { $$ = NODE("executable", 1, $1); }
  | pointer_stmt { $$ = NODE("executable", 1, $1); }
  ;

assignment_stmt: variable_ref ASSIGN expression
  {
    if ($1 && $3) {
      EMIT_IF_EXEC(tac_emit_assign($1->place, $3->place));
    }
    $$ = tac_make_value(NULL);
  }
  ;

if_stmt: IF LPAREN expression RPAREN THEN
  {
    SdtIfCtx ctx = sdt_if_push();
    if ($3) { EMIT_IF_EXEC(tac_emit_if_false_goto($3->place, ctx.else_label)); }
  }
  executables ELSE
  {
    SdtIfCtx ctx = sdt_if_peek();
    EMIT_IF_EXEC(tac_emit_goto(ctx.end_label));
    EMIT_IF_EXEC(tac_emit_label(ctx.else_label));
  }
  executables ENDIF
  {
    SdtIfCtx ctx = sdt_if_pop();
    EMIT_IF_EXEC(tac_emit_label(ctx.end_label));
    $$ = NODE("if_stmt", 9, LEAF("IF"), LEAF("LPAREN"), LEAF("expression"), LEAF("RPAREN"), LEAF("THEN"), $7, LEAF("ELSE"), $10, LEAF("ENDIF"));
  }
  ;

do_stmt: DO IDENTIFIER ASSIGN expression COMMA expression step_opt
  {
    SdtForCtx ctx = sdt_for_push($2, $7 ? $7->place : NULL);
    if ($4) { EMIT_IF_EXEC(tac_emit_assign($2, $4->place)); }
    EMIT_IF_EXEC(tac_emit_label(ctx.start_label));
    {
      char *cmp = tac_new_temp();
      EMIT_IF_EXEC(tac_emit_binary(cmp, $2, "<=", $6 ? $6->place : "0"));
      EMIT_IF_EXEC(tac_emit_if_false_goto(cmp, ctx.end_label));
    }
  }
  executables END DO
  {
    SdtForCtx ctx = sdt_for_pop();
    const char *step = (ctx.step_value && ctx.step_value[0] != '\0') ? ctx.step_value : "1";
    char *next = tac_new_temp();
    EMIT_IF_EXEC(tac_emit_binary(next, ctx.var_name, "+", step));
    EMIT_IF_EXEC(tac_emit_assign(ctx.var_name, next));
    EMIT_IF_EXEC(tac_emit_goto(ctx.start_label));
    EMIT_IF_EXEC(tac_emit_label(ctx.end_label));
    $$ = NODE("do_stmt", 10, LEAF("DO"), LEAF("IDENTIFIER"), LEAF("ASSIGN"), LEAF("expression"), LEAF("COMMA"), LEAF("expression"), LEAF("step_opt"), $9, LEAF("END"), LEAF("DO"));
  }
  ;

dowhile_stmt: DO WHILE LPAREN
  {
    SdtLoopCtx ctx = sdt_loop_push();
    EMIT_IF_EXEC(tac_emit_label(ctx.start_label));
  }
  expression RPAREN
  {
    SdtLoopCtx ctx = sdt_loop_peek();
    if ($5) { EMIT_IF_EXEC(tac_emit_if_false_goto($5->place, ctx.end_label)); }
  }
  executables END DO
  {
    SdtLoopCtx ctx = sdt_loop_pop();
    EMIT_IF_EXEC(tac_emit_goto(ctx.start_label));
    EMIT_IF_EXEC(tac_emit_label(ctx.end_label));
    $$ = NODE("dowhile_stmt", 8, LEAF("DO"), LEAF("WHILE"), LEAF("LPAREN"), LEAF("expression"), LEAF("RPAREN"), $8, LEAF("END"), LEAF("DO"));
  }
  ;

select_stmt: SELECT CASE LPAREN expression RPAREN
  { EMIT_IF_EXEC(tac_emit_quad("select", $4 ? $4->place : "", "-", "-")); }
  case_blocks END SELECT
  {
    EMIT_IF_EXEC(tac_emit_quad("end_select", "-", "-", "-"));
    $$ = NODE("select_stmt", 8, LEAF("SELECT"), LEAF("CASE"), LEAF("LPAREN"), LEAF("expression"), LEAF("RPAREN"), $7, LEAF("END"), LEAF("SELECT"));
  }
  ;

select_rank_stmt: SELECT RANK LPAREN identifier RPAREN
  { EMIT_IF_EXEC(tac_emit_quad("select_rank", $4 ? $4 : "", "-", "-")); }
  rank_blocks END SELECT
  {
    EMIT_IF_EXEC(tac_emit_quad("end_s_rank", "-", "-", "-"));
    $$ = NODE("select_rank_stmt", 8, LEAF("SELECT"), LEAF("RANK"), LEAF("LPAREN"), LEAF("IDENTIFIER"), LEAF("RPAREN"), $7, LEAF("END"), LEAF("SELECT"));
  }
  ;

rank_blocks: rank_block { $$ = NODE("rank_blocks", 1, $1); }
  | rank_blocks rank_block { $$ = NODE("rank_blocks", 2, $1, $2); }
  ;

rank_block: RANK LPAREN rank_selector RPAREN
  { EMIT_IF_EXEC(tac_emit_quad("rank_case", "-", "-", "-")); }
  executables
  { $$ = NODE("rank_block", 5, LEAF("RANK"), LEAF("LPAREN"), $3, LEAF("RPAREN"), $6); }
  | RANK DEFAULT
  { EMIT_IF_EXEC(tac_emit_quad("rank_def", "-", "-", "-")); }
  executables
  { $$ = NODE("rank_block", 3, LEAF("RANK"), LEAF("DEFAULT"), $4); }
  ;

rank_selector: INT_CONST { $$ = NODE("rank_selector", 1, LEAF("INT_CONST")); }
  | MUL_OP { $$ = NODE("rank_selector", 1, LEAF("MUL_OP")); }
  ;

case_blocks: case_block { $$ = NODE("case_blocks", 1, $1); }
  | case_blocks case_block { $$ = NODE("case_blocks", 2, $1, $2); }
  ;

case_block: CASE LPAREN expression RPAREN
  { EMIT_IF_EXEC(tac_emit_quad("case", $3 ? $3->place : "", "-", "-")); }
  executables
  { $$ = NODE("case_block", 5, LEAF("CASE"), LEAF("LPAREN"), LEAF("expression"), LEAF("RPAREN"), $6); }
  | CASE DEFAULT
  { EMIT_IF_EXEC(tac_emit_quad("case_def", "-", "-", "-")); }
  executables
  { $$ = NODE("case_block", 3, LEAF("CASE"), LEAF("DEFAULT"), $4); }
  ;

call_stmt: CALL callable_name LPAREN argument_values RPAREN
  {
    if ($4) {
      SdtArgNode *arg = $4->head;
      while (arg) {
        EMIT_IF_EXEC(tac_emit_quad("param", arg->place ? arg->place : "", "-", "-"));
        arg = arg->next;
      }
      char buf[16]; snprintf(buf, 16, "%d", $4->count);
      EMIT_IF_EXEC(tac_emit_quad("call", $2 ? $2 : "", buf, "-"));
    } else {
      EMIT_IF_EXEC(tac_emit_quad("call", $2 ? $2 : "", "0", "-"));
    }
    $$ = NODE("call_stmt", 5, LEAF("CALL"), LEAF("callable_name"), LEAF("LPAREN"), LEAF("argument_values"), LEAF("RPAREN"));
  }
  ;

callable_name: identifier { $$ = $1; } | INTRINSIC { $$ = $1; } ;

return_stmt: RETURN
  {
    EMIT_IF_EXEC(tac_emit_quad("return", "-", "-", "-"));
    $$ = NODE("return_stmt", 1, LEAF("RETURN"));
  }
  ;

stop_stmt: STOP
  {
    EMIT_IF_EXEC(tac_emit_quad("stop", "-", "-", "-"));
    $$ = NODE("stop_stmt", 1, LEAF("STOP"));
  }
  | STOP INT_CONST
  {
    EMIT_IF_EXEC(tac_emit_quad("stop", $2 ? $2 : "", "-", "-"));
    $$ = NODE("stop_stmt", 2, LEAF("STOP"), LEAF("INT_CONST"));
  }
  | STOP STRING
  {
    EMIT_IF_EXEC(tac_emit_quad("stop", $2 ? $2 : "", "-", "-"));
    $$ = NODE("stop_stmt", 2, LEAF("STOP"), LEAF("STRING"));
  }
  ;

pointer_stmt: variable_ref PTR_ASSIGN variable_ref
  {
    if ($1 && $3) { EMIT_IF_EXEC(tac_emit_quad("=>", $3->place, "-", $1->place)); }
    $$ = NODE("pointer_stmt", 3, LEAF("variable_ref"), LEAF("PTR_ASSIGN"), LEAF("variable_ref"));
  }
  ;

step_opt: /* empty */ { $$ = tac_make_value(strdup("1")); }
  | COMMA expression { $$ = $2; }
  ;

print_stmt: PRINT MUL_OP COMMA print_args
  {
    if ($4) {
      SdtArgNode *arg = $4->head;
      while (arg) {
        EMIT_IF_EXEC(tac_emit_quad("print", arg->place ? arg->place : "", "-", "-"));
        arg = arg->next;
      }
    }
    $$ = NODE("print_stmt", 4, LEAF("PRINT"), LEAF("MUL_OP"), LEAF("COMMA"), LEAF("print_args"));
  }
  ;

print_args: expression { $$ = sdt_arg_list_prepend($1 ? $1->place : "", sdt_arg_list_empty()); }
  | print_args COMMA expression { $$ = sdt_arg_list_append($1, $3 ? $3->place : ""); }
  ;

allocate_stmt: ALLOCATE LPAREN argument_values RPAREN
  {
    if ($3) {
      SdtArgNode *arg = $3->head;
      while (arg) {
        EMIT_IF_EXEC(tac_emit_quad("allocate", arg->place ? arg->place : "", "-", "-"));
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
        EMIT_IF_EXEC(tac_emit_quad("deallocate", arg->place ? arg->place : "", "-", "-"));
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
    if ($1 && $3) { EMIT_IF_EXEC(tac_emit_binary(temp, $1->place, op, $3->place)); }
    $$ = tac_make_value(temp);
    free(op);
  }
  | expression MUL_OP expression
  {
    char *op = $2;
    char *temp = tac_new_temp();
    if ($1 && $3) { EMIT_IF_EXEC(tac_emit_binary(temp, $1->place, op, $3->place)); }
    $$ = tac_make_value(temp);
    free(op);
  }
  | expression EXPONENT expression
  {
    char *op = $2;
    char *temp = tac_new_temp();
    if ($1 && $3) { EMIT_IF_EXEC(tac_emit_binary(temp, $1->place, op, $3->place)); }
    $$ = tac_make_value(temp);
    free(op);
  }
  | expression REL_OP expression
  {
    char *op = $2;
    char *temp = tac_new_temp();
    if ($1 && $3) { EMIT_IF_EXEC(tac_emit_binary(temp, $1->place, op, $3->place)); }
    $$ = tac_make_value(temp);
    free(op);
  }
  | expression LOGICAL_OP expression
  {
    char *op = $2;
    char *temp = tac_new_temp();
    if ($1 && $3) { EMIT_IF_EXEC(tac_emit_binary(temp, $1->place, op, $3->place)); }
    $$ = tac_make_value(temp);
    free(op);
  }
  | factor { $$ = $1; }
  | ADD_OP expression %prec UNARY
  {
    char *op = $1;
    char *temp = tac_new_temp();
    if ($2) { EMIT_IF_EXEC(tac_emit_unary(temp, op, $2->place)); }
    $$ = tac_make_value(temp);
    free(op);
  }
  | LOGICAL_OP expression %prec UNARY
  {
    char *op = $1;
    char *temp = tac_new_temp();
    if ($2) { EMIT_IF_EXEC(tac_emit_unary(temp, op, $2->place)); }
    $$ = tac_make_value(temp);
    free(op);
  }
  ;

factor: primary { $$ = $1; } ;

primary: INT_CONST { $$ = tac_make_value($1); }
  | REAL_CONST { $$ = tac_make_value($1); }
  | LOGICAL_CONST { $$ = tac_make_value($1); }
  | STRING { $$ = tac_make_value($1); }
  | complex_literal { $$ = $1; }
  | LPAREN expression RPAREN { $$ = $2; }
  | variable_ref primary_suffix_opt
  {
    if ($2) {
      if (sdt_is_array($1 ? $1->place : NULL)) {
        char *indexed = sdt_format_index($1 ? $1->place : NULL, $2);
        $$ = tac_make_value(indexed);
      } else {
        SdtArgNode *arg = $2->head;
        while (arg) {
          EMIT_IF_EXEC(tac_emit_quad("param", arg->place ? arg->place : "", "-", "-"));
          arg = arg->next;
        }
        int argc = $2->count;
        char *temp = tac_new_temp();
        char buf[16]; snprintf(buf, 16, "%d", argc);
        EMIT_IF_EXEC(tac_emit_quad("call", $1 ? $1->place : "", buf, temp));
        $$ = tac_make_value(temp);
      }
    } else {
      $$ = $1;
    }
  }
  ;

complex_literal: LPAREN expression COMMA expression RPAREN
  {
    char *text = sdt_format_complex($2 ? $2->place : NULL, $4 ? $4->place : NULL);
    $$ = tac_make_value(text);
  }
  ;

primary_suffix_opt: /* empty */ { $$ = NULL; }
  | LPAREN argument_values RPAREN { $$ = $2; }
  ;

variable_ref: identifier { $$ = tac_make_value($1); }
  | variable_ref DERIVED_TYPE_COMPONENT identifier
  {
    char *combined = sdt_append_derived($1 ? $1->place : NULL, $3);
    $$ = tac_make_value(combined);
  }
  ;

subprogram_list: /* empty */ { $$ = NODE0("subprogram_list"); }
  | subprogram_list subprogram { $$ = NODE("subprogram_list", 2, $1, $2); }
  ;

subprogram: SUBROUTINE identifier LPAREN identifier_list_opt RPAREN 
    { 
        g_ctx = CTX_FUNCTION; 
        tac_emit_quad("func", $2, "-", "-"); 
    }
    program_body END SUBROUTINE opt_identifier
    {
        tac_emit_quad("endfunc", "-", "-", "-");
        g_ctx = CTX_MODULE; 
        if ($10) {
            $$ = NODE("subprogram", 9, LEAF("SUBROUTINE"), LEAF("IDENTIFIER"), LEAF("LPAREN"), $4, LEAF("RPAREN"), $7, LEAF("END"), LEAF("SUBROUTINE"), LEAF($10));
        } else {
            $$ = NODE("subprogram", 8, LEAF("SUBROUTINE"), LEAF("IDENTIFIER"), LEAF("LPAREN"), $4, LEAF("RPAREN"), $7, LEAF("END"), LEAF("SUBROUTINE"));
        }
    }
  | FUNCTION identifier LPAREN identifier_list_opt RPAREN 
    { 
        g_ctx = CTX_FUNCTION; 
        tac_emit_quad("func", $2, "-", "-"); 
    }
    program_body END FUNCTION opt_identifier
    {
        tac_emit_quad("endfunc", "-", "-", "-");
        g_ctx = CTX_MODULE; 
        if ($10) {
            $$ = NODE("subprogram", 9, LEAF("FUNCTION"), LEAF("IDENTIFIER"), LEAF("LPAREN"), $4, LEAF("RPAREN"), $7, LEAF("END"), LEAF("FUNCTION"), LEAF($10));
        } else {
            $$ = NODE("subprogram", 8, LEAF("FUNCTION"), LEAF("IDENTIFIER"), LEAF("LPAREN"), $4, LEAF("RPAREN"), $7, LEAF("END"), LEAF("FUNCTION"));
        }
    }
  | RECURSIVE FUNCTION identifier LPAREN identifier_list_opt RPAREN RESULT LPAREN identifier RPAREN 
    { 
        g_ctx = CTX_FUNCTION; 
        tac_emit_quad("func", $3, "-", "-"); 
    }
    program_body END FUNCTION opt_identifier
    {
        tac_emit_quad("endfunc", "-", "-", "-");
        g_ctx = CTX_MODULE; 
        if ($15) {
            $$ = NODE("subprogram", 14, LEAF("RECURSIVE"), LEAF("FUNCTION"), LEAF("IDENTIFIER"), LEAF("LPAREN"), $5, LEAF("RPAREN"), LEAF("RESULT"), LEAF("LPAREN"), LEAF("IDENTIFIER"), LEAF("RPAREN"), $12, LEAF("END"), LEAF("FUNCTION"), LEAF($15));
        } else {
            $$ = NODE("subprogram", 13, LEAF("RECURSIVE"), LEAF("FUNCTION"), LEAF("IDENTIFIER"), LEAF("LPAREN"), $5, LEAF("RPAREN"), LEAF("RESULT"), LEAF("LPAREN"), LEAF("IDENTIFIER"), LEAF("RPAREN"), $12, LEAF("END"), LEAF("FUNCTION"));
        }
    }
  ;

argument_values: /* empty */ { $$ = sdt_arg_list_empty(); }
  | expression { $$ = sdt_arg_list_prepend($1 ? $1->place : "", sdt_arg_list_empty()); }
  | expression COMMA argument_values { $$ = sdt_arg_list_prepend($1 ? $1->place : "", $3); }
  ;

identifier_list_opt: /* empty */ { $$ = NODE0("identifier_list_opt"); }
  | identifier_list { $$ = NODE("identifier_list_opt", 1, $1); }
  ;

identifier: IDENTIFIER { $$ = $1; } | RESULT { $$ = strdup("result"); } ;

opt_identifier: IDENTIFIER { $$ = $1; } | /* empty */ { $$ = NULL; } ;

type_def: TYPE DECL_SEP identifier type_def_body END_TYPE identifier
  { $$ = NODE("type_def", 6, LEAF("TYPE"), LEAF("DECL_SEP"), LEAF("IDENTIFIER"), $4, LEAF("END_TYPE"), LEAF("IDENTIFIER")); }
  ;

type_def_body: /* empty */ { $$ = NODE0("type_def_body"); }
  | type_def_declarations { $$ = NODE("type_def_body", 1, $1); }
  ;

type_def_declarations: type_def_declaration { $$ = NODE("type_def_declarations", 1, $1); }
  | type_def_declarations type_def_declaration { $$ = NODE("type_def_declarations", 2, $1, $2); }
  ;

type_def_declaration: type_spec declaration_attributes DECL_SEP declarator_list
  { $$ = NODE("type_def_declaration", 4, $1, $2, LEAF("DECL_SEP"), $4); }
  ;

pp_define_undef: PP_DEFINE identifier { $$ = NODE("pp_define_undef", 2, LEAF("PP_DEFINE"), LEAF("IDENTIFIER")); }
  | PP_DEFINE identifier INT_CONST { $$ = NODE("pp_define_undef", 3, LEAF("PP_DEFINE"), LEAF("IDENTIFIER"), LEAF("INT_CONST")); }
  | PP_UNDEF identifier { $$ = NODE("pp_define_undef", 2, LEAF("PP_UNDEF"), LEAF("IDENTIFIER")); }
  ;

pp_if_block: PP_IFDEF identifier declarations pp_else_opt PP_ENDIF
  { $$ = NODE("pp_if_block", 5, LEAF("PP_IFDEF"), LEAF("IDENTIFIER"), $3, $4, LEAF("PP_ENDIF")); }
  | PP_IFNDEF identifier declarations pp_else_opt PP_ENDIF
  { $$ = NODE("pp_if_block", 5, LEAF("PP_IFNDEF"), LEAF("IDENTIFIER"), $3, $4, LEAF("PP_ENDIF")); }
  | PP_IF identifier declarations pp_else_opt PP_ENDIF
  { $$ = NODE("pp_if_block", 5, LEAF("PP_IF"), LEAF("IDENTIFIER"), $3, $4, LEAF("PP_ENDIF")); }
  | PP_IF INT_CONST declarations pp_else_opt PP_ENDIF
  { $$ = NODE("pp_if_block", 5, LEAF("PP_IF"), LEAF("INT_CONST"), $3, $4, LEAF("PP_ENDIF")); }
  ;

pp_else_opt: /* empty */ { $$ = NODE0("pp_else_opt"); }
  | PP_ELSE declarations { $$ = NODE("pp_else_opt", 2, LEAF("PP_ELSE"), $2); }
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

    if (yyparse() == 0) {
        printf("Parsing done!\n\n");
        
        // LAB REQUIREMENT PART 3: Call tabular quadruple printer
        printf("Intermediate Code (Quadruples):\n");
        tac_print_quads(stdout); 
        
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