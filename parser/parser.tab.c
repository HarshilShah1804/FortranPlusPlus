/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* First part of user prologue.  */
#line 1 "parser.y"

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

#define SDT_ARRAY_MAX 256
static char *g_array_names[SDT_ARRAY_MAX];
static int g_array_count = 0;

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
  if (g_if_top < SDT_STACK_MAX) {
    g_if_stack[g_if_top++] = ctx;
  }
  return ctx;
}

static SdtIfCtx sdt_if_peek(void)
{
  if (g_if_top > 0) {
    return g_if_stack[g_if_top - 1];
  }
  SdtIfCtx empty = { NULL, NULL };
  return empty;
}

static SdtIfCtx sdt_if_pop(void)
{
  if (g_if_top > 0) {
    return g_if_stack[--g_if_top];
  }
  SdtIfCtx empty = { NULL, NULL };
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

static void sdt_register_array(const char *name)
{
  if (!name || name[0] == '\0') {
    return;
  }

  for (int i = 0; i < g_array_count; ++i) {
    if (g_array_names[i] && strcmp(g_array_names[i], name) == 0) {
      return;
    }
  }

  if (g_array_count < SDT_ARRAY_MAX) {
    g_array_names[g_array_count++] = strdup(name);
  }
}

static int sdt_is_array(const char *name)
{
  if (!name || name[0] == '\0') {
    return 0;
  }

  for (int i = 0; i < g_array_count; ++i) {
    if (g_array_names[i] && strcmp(g_array_names[i], name) == 0) {
      return 1;
    }
  }
  return 0;
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


#line 401 "parser.tab.c"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif

#include "parser.tab.h"
/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_PROGRAM = 3,                    /* PROGRAM  */
  YYSYMBOL_MODULE = 4,                     /* MODULE  */
  YYSYMBOL_END = 5,                        /* END  */
  YYSYMBOL_CONTAINS = 6,                   /* CONTAINS  */
  YYSYMBOL_USE = 7,                        /* USE  */
  YYSYMBOL_NONE = 8,                       /* NONE  */
  YYSYMBOL_IMPLICIT = 9,                   /* IMPLICIT  */
  YYSYMBOL_INTEGER = 10,                   /* INTEGER  */
  YYSYMBOL_REAL = 11,                      /* REAL  */
  YYSYMBOL_LOGICAL = 12,                   /* LOGICAL  */
  YYSYMBOL_CHARACTER = 13,                 /* CHARACTER  */
  YYSYMBOL_TYPE = 14,                      /* TYPE  */
  YYSYMBOL_CLASS = 15,                     /* CLASS  */
  YYSYMBOL_END_TYPE = 16,                  /* END_TYPE  */
  YYSYMBOL_COMPLEX = 17,                   /* COMPLEX  */
  YYSYMBOL_IF = 18,                        /* IF  */
  YYSYMBOL_THEN = 19,                      /* THEN  */
  YYSYMBOL_ELSE = 20,                      /* ELSE  */
  YYSYMBOL_DO = 21,                        /* DO  */
  YYSYMBOL_ENDIF = 22,                     /* ENDIF  */
  YYSYMBOL_LEN = 23,                       /* LEN  */
  YYSYMBOL_WHILE = 24,                     /* WHILE  */
  YYSYMBOL_SELECT = 25,                    /* SELECT  */
  YYSYMBOL_CASE = 26,                      /* CASE  */
  YYSYMBOL_DEFAULT = 27,                   /* DEFAULT  */
  YYSYMBOL_RANK = 28,                      /* RANK  */
  YYSYMBOL_STOP = 29,                      /* STOP  */
  YYSYMBOL_PRINT = 30,                     /* PRINT  */
  YYSYMBOL_CALL = 31,                      /* CALL  */
  YYSYMBOL_SUBROUTINE = 32,                /* SUBROUTINE  */
  YYSYMBOL_FUNCTION = 33,                  /* FUNCTION  */
  YYSYMBOL_RETURN = 34,                    /* RETURN  */
  YYSYMBOL_RECURSIVE = 35,                 /* RECURSIVE  */
  YYSYMBOL_RESULT = 36,                    /* RESULT  */
  YYSYMBOL_ALLOCATE = 37,                  /* ALLOCATE  */
  YYSYMBOL_DEALLOCATE = 38,                /* DEALLOCATE  */
  YYSYMBOL_ALLOCATED = 39,                 /* ALLOCATED  */
  YYSYMBOL_POINTER = 40,                   /* POINTER  */
  YYSYMBOL_TARGET = 41,                    /* TARGET  */
  YYSYMBOL_ALLOCATABLE = 42,               /* ALLOCATABLE  */
  YYSYMBOL_INTENT = 43,                    /* INTENT  */
  YYSYMBOL_IN = 44,                        /* IN  */
  YYSYMBOL_OUT = 45,                       /* OUT  */
  YYSYMBOL_INOUT = 46,                     /* INOUT  */
  YYSYMBOL_OPEN = 47,                      /* OPEN  */
  YYSYMBOL_CLOSE = 48,                     /* CLOSE  */
  YYSYMBOL_INQUIRE = 49,                   /* INQUIRE  */
  YYSYMBOL_WRITE = 50,                     /* WRITE  */
  YYSYMBOL_READ = 51,                      /* READ  */
  YYSYMBOL_ERROR = 52,                     /* ERROR  */
  YYSYMBOL_LPAREN = 53,                    /* LPAREN  */
  YYSYMBOL_RPAREN = 54,                    /* RPAREN  */
  YYSYMBOL_COMMA = 55,                     /* COMMA  */
  YYSYMBOL_COLON = 56,                     /* COLON  */
  YYSYMBOL_ASSUMED_RANK_SPECIFIER = 57,    /* ASSUMED_RANK_SPECIFIER  */
  YYSYMBOL_CONCAT = 58,                    /* CONCAT  */
  YYSYMBOL_PTR_ASSIGN = 59,                /* PTR_ASSIGN  */
  YYSYMBOL_PP_DEFINE = 60,                 /* PP_DEFINE  */
  YYSYMBOL_PP_UNDEF = 61,                  /* PP_UNDEF  */
  YYSYMBOL_PP_IFDEF = 62,                  /* PP_IFDEF  */
  YYSYMBOL_PP_IFNDEF = 63,                 /* PP_IFNDEF  */
  YYSYMBOL_PP_IF = 64,                     /* PP_IF  */
  YYSYMBOL_PP_ELIF = 65,                   /* PP_ELIF  */
  YYSYMBOL_PP_ELSE = 66,                   /* PP_ELSE  */
  YYSYMBOL_PP_ENDIF = 67,                  /* PP_ENDIF  */
  YYSYMBOL_LENGTH_SPECIFIER = 68,          /* LENGTH_SPECIFIER  */
  YYSYMBOL_IDENTIFIER = 69,                /* IDENTIFIER  */
  YYSYMBOL_INT_CONST = 70,                 /* INT_CONST  */
  YYSYMBOL_REAL_CONST = 71,                /* REAL_CONST  */
  YYSYMBOL_STRING = 72,                    /* STRING  */
  YYSYMBOL_LOGICAL_CONST = 73,             /* LOGICAL_CONST  */
  YYSYMBOL_INTRINSIC = 74,                 /* INTRINSIC  */
  YYSYMBOL_ADD_OP = 75,                    /* ADD_OP  */
  YYSYMBOL_MUL_OP = 76,                    /* MUL_OP  */
  YYSYMBOL_REL_OP = 77,                    /* REL_OP  */
  YYSYMBOL_LOGICAL_OP = 78,                /* LOGICAL_OP  */
  YYSYMBOL_EXPONENT = 79,                  /* EXPONENT  */
  YYSYMBOL_ASSIGN = 80,                    /* ASSIGN  */
  YYSYMBOL_DECL_SEP = 81,                  /* DECL_SEP  */
  YYSYMBOL_DERIVED_TYPE_COMPONENT = 82,    /* DERIVED_TYPE_COMPONENT  */
  YYSYMBOL_UNARY = 83,                     /* UNARY  */
  YYSYMBOL_LOWER_THAN_ELSE = 84,           /* LOWER_THAN_ELSE  */
  YYSYMBOL_YYACCEPT = 85,                  /* $accept  */
  YYSYMBOL_start = 86,                     /* start  */
  YYSYMBOL_compilation_units = 87,         /* compilation_units  */
  YYSYMBOL_compilation_unit = 88,          /* compilation_unit  */
  YYSYMBOL_free_form = 89,                 /* free_form  */
  YYSYMBOL_program_unit = 90,              /* program_unit  */
  YYSYMBOL_module_unit = 91,               /* module_unit  */
  YYSYMBOL_program_body = 92,              /* program_body  */
  YYSYMBOL_module_body = 93,               /* module_body  */
  YYSYMBOL_contains_block = 94,            /* contains_block  */
  YYSYMBOL_95_1 = 95,                      /* $@1  */
  YYSYMBOL_declarations = 96,              /* declarations  */
  YYSYMBOL_preamble = 97,                  /* preamble  */
  YYSYMBOL_pp_item = 98,                   /* pp_item  */
  YYSYMBOL_declaration = 99,               /* declaration  */
  YYSYMBOL_type_spec = 100,                /* type_spec  */
  YYSYMBOL_char_type_spec = 101,           /* char_type_spec  */
  YYSYMBOL_char_len_opt = 102,             /* char_len_opt  */
  YYSYMBOL_char_len_value = 103,           /* char_len_value  */
  YYSYMBOL_attributes = 104,               /* attributes  */
  YYSYMBOL_attribute = 105,                /* attribute  */
  YYSYMBOL_declaration_attributes = 106,   /* declaration_attributes  */
  YYSYMBOL_identifier_list = 107,          /* identifier_list  */
  YYSYMBOL_declarator_list = 108,          /* declarator_list  */
  YYSYMBOL_declarator = 109,               /* declarator  */
  YYSYMBOL_110_2 = 110,                    /* $@2  */
  YYSYMBOL_array_spec_opt = 111,           /* array_spec_opt  */
  YYSYMBOL_array_spec = 112,               /* array_spec  */
  YYSYMBOL_array_spec_list = 113,          /* array_spec_list  */
  YYSYMBOL_array_spec_item = 114,          /* array_spec_item  */
  YYSYMBOL_init_opt = 115,                 /* init_opt  */
  YYSYMBOL_executables = 116,              /* executables  */
  YYSYMBOL_executable = 117,               /* executable  */
  YYSYMBOL_assignment_stmt = 118,          /* assignment_stmt  */
  YYSYMBOL_if_stmt = 119,                  /* if_stmt  */
  YYSYMBOL_120_3 = 120,                    /* $@3  */
  YYSYMBOL_121_4 = 121,                    /* $@4  */
  YYSYMBOL_do_stmt = 122,                  /* do_stmt  */
  YYSYMBOL_123_5 = 123,                    /* $@5  */
  YYSYMBOL_dowhile_stmt = 124,             /* dowhile_stmt  */
  YYSYMBOL_125_6 = 125,                    /* $@6  */
  YYSYMBOL_126_7 = 126,                    /* $@7  */
  YYSYMBOL_select_stmt = 127,              /* select_stmt  */
  YYSYMBOL_128_8 = 128,                    /* $@8  */
  YYSYMBOL_select_rank_stmt = 129,         /* select_rank_stmt  */
  YYSYMBOL_130_9 = 130,                    /* $@9  */
  YYSYMBOL_rank_blocks = 131,              /* rank_blocks  */
  YYSYMBOL_rank_block = 132,               /* rank_block  */
  YYSYMBOL_133_10 = 133,                   /* $@10  */
  YYSYMBOL_134_11 = 134,                   /* $@11  */
  YYSYMBOL_rank_selector = 135,            /* rank_selector  */
  YYSYMBOL_case_blocks = 136,              /* case_blocks  */
  YYSYMBOL_case_block = 137,               /* case_block  */
  YYSYMBOL_138_12 = 138,                   /* $@12  */
  YYSYMBOL_139_13 = 139,                   /* $@13  */
  YYSYMBOL_call_stmt = 140,                /* call_stmt  */
  YYSYMBOL_callable_name = 141,            /* callable_name  */
  YYSYMBOL_return_stmt = 142,              /* return_stmt  */
  YYSYMBOL_stop_stmt = 143,                /* stop_stmt  */
  YYSYMBOL_pointer_stmt = 144,             /* pointer_stmt  */
  YYSYMBOL_step_opt = 145,                 /* step_opt  */
  YYSYMBOL_print_stmt = 146,               /* print_stmt  */
  YYSYMBOL_print_args = 147,               /* print_args  */
  YYSYMBOL_allocate_stmt = 148,            /* allocate_stmt  */
  YYSYMBOL_deallocate_stmt = 149,          /* deallocate_stmt  */
  YYSYMBOL_expression = 150,               /* expression  */
  YYSYMBOL_factor = 151,                   /* factor  */
  YYSYMBOL_primary = 152,                  /* primary  */
  YYSYMBOL_complex_literal = 153,          /* complex_literal  */
  YYSYMBOL_primary_suffix_opt = 154,       /* primary_suffix_opt  */
  YYSYMBOL_variable_ref = 155,             /* variable_ref  */
  YYSYMBOL_subprogram_list = 156,          /* subprogram_list  */
  YYSYMBOL_subprogram = 157,               /* subprogram  */
  YYSYMBOL_argument_values = 158,          /* argument_values  */
  YYSYMBOL_identifier_list_opt = 159,      /* identifier_list_opt  */
  YYSYMBOL_identifier = 160,               /* identifier  */
  YYSYMBOL_type_def = 161,                 /* type_def  */
  YYSYMBOL_type_def_body = 162,            /* type_def_body  */
  YYSYMBOL_type_def_declarations = 163,    /* type_def_declarations  */
  YYSYMBOL_type_def_declaration = 164,     /* type_def_declaration  */
  YYSYMBOL_pp_define_undef = 165,          /* pp_define_undef  */
  YYSYMBOL_pp_if_block = 166,              /* pp_if_block  */
  YYSYMBOL_pp_else_opt = 167               /* pp_else_opt  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;




#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_int16 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if 1

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* 1 */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  12
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   432

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  85
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  83
/* YYNRULES -- Number of rules.  */
#define YYNRULES  177
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  343

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   339


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,    66,    67,    68,    69,    70,    71,    72,    73,    74,
      75,    76,    77,    78,    79,    80,    81,    82,    83,    84
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   387,   387,   392,   399,   403,   409,   413,   419,   425,
     429,   435,   439,   445,   451,   458,   457,   467,   473,   476,
     483,   486,   492,   496,   502,   506,   510,   514,   520,   524,
     528,   532,   536,   540,   544,   550,   557,   560,   566,   570,
     574,   580,   584,   590,   594,   598,   602,   606,   610,   617,
     620,   626,   630,   636,   640,   647,   646,   664,   668,   675,
     681,   685,   691,   695,   699,   703,   707,   711,   718,   722,
     730,   733,   739,   743,   747,   751,   755,   759,   763,   767,
     771,   775,   779,   783,   787,   793,   803,   810,   802,   824,
     823,   850,   855,   849,   871,   870,   882,   881,   892,   896,
     903,   902,   911,   910,   920,   924,   930,   934,   941,   940,
     949,   948,   958,   974,   978,   984,   991,   996,  1001,  1008,
    1018,  1021,  1027,  1040,  1044,  1050,  1063,  1076,  1086,  1096,
    1106,  1116,  1126,  1130,  1140,  1152,  1158,  1162,  1166,  1170,
    1174,  1178,  1182,  1206,  1214,  1217,  1223,  1227,  1235,  1238,
    1244,  1248,  1252,  1256,  1260,  1264,  1271,  1274,  1278,  1285,
    1288,  1294,  1298,  1304,  1311,  1314,  1320,  1324,  1330,  1336,
    1340,  1344,  1350,  1354,  1358,  1362,  1369,  1372
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if 1
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "PROGRAM", "MODULE",
  "END", "CONTAINS", "USE", "NONE", "IMPLICIT", "INTEGER", "REAL",
  "LOGICAL", "CHARACTER", "TYPE", "CLASS", "END_TYPE", "COMPLEX", "IF",
  "THEN", "ELSE", "DO", "ENDIF", "LEN", "WHILE", "SELECT", "CASE",
  "DEFAULT", "RANK", "STOP", "PRINT", "CALL", "SUBROUTINE", "FUNCTION",
  "RETURN", "RECURSIVE", "RESULT", "ALLOCATE", "DEALLOCATE", "ALLOCATED",
  "POINTER", "TARGET", "ALLOCATABLE", "INTENT", "IN", "OUT", "INOUT",
  "OPEN", "CLOSE", "INQUIRE", "WRITE", "READ", "ERROR", "LPAREN", "RPAREN",
  "COMMA", "COLON", "ASSUMED_RANK_SPECIFIER", "CONCAT", "PTR_ASSIGN",
  "PP_DEFINE", "PP_UNDEF", "PP_IFDEF", "PP_IFNDEF", "PP_IF", "PP_ELIF",
  "PP_ELSE", "PP_ENDIF", "LENGTH_SPECIFIER", "IDENTIFIER", "INT_CONST",
  "REAL_CONST", "STRING", "LOGICAL_CONST", "INTRINSIC", "ADD_OP", "MUL_OP",
  "REL_OP", "LOGICAL_OP", "EXPONENT", "ASSIGN", "DECL_SEP",
  "DERIVED_TYPE_COMPONENT", "UNARY", "LOWER_THAN_ELSE", "$accept", "start",
  "compilation_units", "compilation_unit", "free_form", "program_unit",
  "module_unit", "program_body", "module_body", "contains_block", "$@1",
  "declarations", "preamble", "pp_item", "declaration", "type_spec",
  "char_type_spec", "char_len_opt", "char_len_value", "attributes",
  "attribute", "declaration_attributes", "identifier_list",
  "declarator_list", "declarator", "$@2", "array_spec_opt", "array_spec",
  "array_spec_list", "array_spec_item", "init_opt", "executables",
  "executable", "assignment_stmt", "if_stmt", "$@3", "$@4", "do_stmt",
  "$@5", "dowhile_stmt", "$@6", "$@7", "select_stmt", "$@8",
  "select_rank_stmt", "$@9", "rank_blocks", "rank_block", "$@10", "$@11",
  "rank_selector", "case_blocks", "case_block", "$@12", "$@13",
  "call_stmt", "callable_name", "return_stmt", "stop_stmt", "pointer_stmt",
  "step_opt", "print_stmt", "print_args", "allocate_stmt",
  "deallocate_stmt", "expression", "factor", "primary", "complex_literal",
  "primary_suffix_opt", "variable_ref", "subprogram_list", "subprogram",
  "argument_values", "identifier_list_opt", "identifier", "type_def",
  "type_def_body", "type_def_declarations", "type_def_declaration",
  "pp_define_undef", "pp_if_block", "pp_else_opt", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-286)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-1)

#define yytable_value_is_error(Yyn) \
  ((Yyn) == YYTABLE_NINF)

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     111,   -10,    32,   119,   111,  -286,  -286,  -286,  -286,   276,
    -286,  -286,  -286,  -286,   -18,   138,  -286,  -286,  -286,    74,
     -15,   -18,  -286,   -18,   -18,   -18,   -18,   -12,  -286,  -286,
     396,    93,  -286,  -286,  -286,  -286,   145,   276,   152,   276,
    -286,  -286,  -286,  -286,   102,  -286,   -18,   -18,  -286,   109,
    -286,   396,   396,   396,   396,    49,  -286,    98,    91,   191,
    -286,   194,  -286,   124,   141,    94,  -286,   133,   133,   133,
     133,   158,   -21,   107,     5,   142,   -22,  -286,   167,   176,
    -286,  -286,  -286,  -286,  -286,  -286,  -286,  -286,  -286,  -286,
    -286,  -286,  -286,  -286,    65,  -286,  -286,  -286,  -286,   177,
    -286,   178,   -18,   163,   185,   173,   185,    -6,  -286,   190,
      93,   229,    94,  -286,   396,   179,   181,   186,   188,   115,
     199,   204,   203,   213,  -286,  -286,   224,  -286,   215,  -286,
     115,   115,   -18,   115,   -18,   193,    98,  -286,   237,   241,
    -286,  -286,  -286,  -286,  -286,  -286,  -286,   243,  -286,   217,
     -18,  -286,  -286,  -286,  -286,  -286,  -286,   115,  -286,  -286,
    -286,  -286,   115,   115,   182,  -286,  -286,  -286,   -45,  -286,
     115,   115,   -18,   115,   115,   299,   247,   248,   222,   312,
    -286,   251,   252,   257,  -286,   -18,   288,  -286,  -286,  -286,
    -286,   -18,  -286,    77,  -286,  -286,   294,   115,   115,   115,
     115,   115,   115,  -286,   115,   307,   196,   263,   266,   312,
     268,   115,  -286,  -286,  -286,  -286,  -286,  -286,   115,  -286,
     105,  -286,   323,   245,   131,  -286,  -286,   115,  -286,    -3,
     244,    15,   149,   244,   272,   256,   115,  -286,  -286,   115,
    -286,  -286,   312,  -286,   288,   115,   115,  -286,   -18,   -18,
     296,  -286,   274,  -286,  -286,  -286,   317,   304,   314,   312,
    -286,   312,   312,   290,   295,   -18,  -286,    92,  -286,   115,
    -286,    -7,    10,  -286,    12,    17,  -286,   -18,   -18,   302,
    -286,   144,   312,  -286,  -286,   115,   331,  -286,  -286,   -49,
     339,  -286,  -286,   311,   318,   326,   -18,  -286,   360,   171,
    -286,   292,  -286,  -286,  -286,  -286,   343,  -286,  -286,   -18,
    -286,   350,   278,  -286,   391,    49,  -286,    49,  -286,   409,
    -286,   410,   380,  -286,  -286,  -286,  -286,   385,   386,   365,
      49,    49,   -18,   -18,   -18,  -286,  -286,   366,  -286,   416,
     389,   -18,  -286
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
      20,     0,     0,     0,     2,     4,     3,     6,     7,    18,
      20,    20,     1,     5,     0,     0,    28,    29,    30,    36,
       0,     0,    34,     0,     0,     0,     0,     0,    70,    21,
      18,    49,    31,    27,    22,    23,     0,    18,     0,    18,
     162,   161,    26,    25,     0,    35,     0,     0,    33,   169,
     171,    18,    18,    18,    18,     8,    19,     0,     0,     0,
      70,     0,    70,     0,     0,   164,   170,   176,   176,   176,
     176,     0,     0,     0,   116,     0,     0,   115,     0,     0,
      71,    72,    73,    77,    78,    80,    79,    81,    82,    83,
      84,    74,    75,    76,     0,   146,    44,    45,    43,     0,
      50,    41,     0,    10,    17,    12,    17,     0,    32,     0,
      49,     0,   165,   166,    18,     0,     0,     0,     0,     0,
       0,     0,     0,     0,   117,   118,     0,   114,     0,   113,
     156,   156,     0,     0,     0,     0,     0,    24,    53,    57,
       9,    15,    13,    11,    14,    38,    39,     0,    40,     0,
       0,   167,   177,   172,   173,   175,   174,     0,   136,   137,
     139,   138,     0,     0,     0,   132,   135,   140,   144,    91,
       0,     0,     0,     0,   156,   157,     0,     0,   119,    85,
     147,     0,     0,     0,    42,     0,     0,    55,    58,   148,
      37,     0,   163,     0,   133,   134,     0,     0,     0,     0,
       0,     0,   156,   142,     0,     0,     0,     0,   122,   123,
       0,   156,   125,   126,    46,    47,    48,    54,    63,    62,
       0,    60,    64,    68,    16,   168,   141,     0,    86,   127,
     128,   130,   131,   129,     0,     0,     0,    94,    96,     0,
     112,   158,    66,    59,     0,    65,     0,    56,     0,     0,
       0,   149,     0,    70,   145,    92,   120,     0,     0,   124,
      61,    67,    69,     0,     0,     0,   143,     0,    70,     0,
      89,     0,     0,   106,     0,     0,    98,   159,   159,     0,
      87,     0,   121,    70,   110,     0,     0,   107,   102,     0,
       0,    99,   160,     0,    51,     0,   159,    70,     0,     0,
      70,     0,    95,    70,   104,   105,     0,    97,    20,     0,
      20,     0,     0,    93,     0,   111,   108,   103,   100,     0,
      52,     0,     0,    88,    90,    70,    70,     0,     0,     0,
     109,   101,   150,   152,     0,   151,   153,     0,    20,     0,
       0,   154,   155
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -286,  -286,  -286,   419,  -286,  -286,  -286,  -285,  -286,   319,
    -286,   -11,    89,  -286,  -286,   -63,  -286,  -286,  -286,   291,
    -286,   316,   120,  -156,  -286,  -286,  -286,  -286,  -286,   180,
    -286,   -56,  -286,  -286,  -286,  -286,  -286,  -286,  -286,  -286,
    -286,  -286,  -286,  -286,  -286,  -286,  -286,   153,  -286,  -286,
    -286,  -286,   159,  -286,  -286,  -286,  -286,  -286,  -286,  -286,
    -286,  -286,  -286,  -286,  -286,  -102,  -286,  -286,  -286,  -286,
     -50,  -286,  -286,  -130,  -262,   -14,  -286,  -286,  -286,   320,
    -286,  -286,   208
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
       0,     3,     4,     5,     6,     7,     8,    36,    38,   142,
     189,    28,    37,    29,    30,    31,    32,    45,   147,   100,
     101,    58,   292,   137,   138,   223,   187,   188,   220,   221,
     247,    55,    80,    81,    82,   253,   297,    83,   283,    84,
     204,   268,    85,   257,    86,   258,   275,   276,   326,   303,
     306,   272,   273,   325,   300,    87,   128,    88,    89,    90,
     270,    91,   208,    92,    93,   175,   165,   166,   167,   203,
     168,   224,   251,   176,   293,    95,    33,   111,   112,   113,
      34,    35,   115
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int16 yytable[] =
{
      42,   177,   110,   120,   104,    94,   106,    48,   202,    49,
      50,    51,    52,    54,    40,   286,   295,   164,    40,    56,
     284,   304,   290,   319,    40,   321,    60,   305,    62,   217,
      40,   179,    64,    65,   311,   225,   271,   134,    46,   288,
      67,    68,    69,    70,   210,   274,   285,    41,   121,   110,
     145,    41,   127,   339,    94,   193,    94,    41,    53,    10,
     194,   195,   129,    41,   146,   289,    47,    71,   205,   206,
      72,   209,   234,   198,    73,   124,   201,   125,    74,    75,
      76,   241,   178,    77,   222,    40,    78,    79,   139,     9,
     197,   198,    -1,   148,   201,   229,   230,   231,   232,   233,
      39,    11,   235,   152,    16,    17,    18,    19,   109,    21,
      71,    22,   280,    72,     1,     2,   242,    73,    41,    12,
     180,    74,    75,    76,   132,   252,    77,    44,    40,    78,
      79,   226,   227,   122,   256,   123,   192,   259,    96,    97,
      98,    99,   222,   261,   262,   133,    43,   134,    57,   298,
      59,    40,   197,   198,   199,   200,   201,    61,   207,   243,
     244,    41,    71,   248,   249,    72,   250,   282,   157,    73,
      63,   139,   102,    74,    75,    76,   314,   139,    77,    66,
      40,    78,    79,   301,    41,   158,   159,   160,   161,    71,
     162,   141,    72,   163,   103,   108,    73,   267,   105,   114,
      74,    75,    76,    71,   107,    77,    72,    40,    78,    79,
      73,   119,   281,    41,    74,    75,    76,    94,   126,    77,
     130,    40,    78,    79,   197,   198,   199,   299,   201,   131,
     135,    94,   140,   136,   263,   264,   196,   181,   182,   183,
      41,   312,   143,    46,   315,   150,   153,   317,   154,    94,
     237,   279,   169,   155,    41,   156,   171,   197,   198,   199,
     200,   201,    94,   294,   294,    94,   172,    94,   174,   330,
     331,   197,   198,   199,   200,   201,   116,   117,   118,   173,
      94,    94,   294,    14,   170,    15,    16,    17,    18,    19,
      20,    21,   185,    22,   186,   294,    71,   190,   191,    72,
     323,   212,   213,    73,   134,   214,   215,    74,    75,    76,
     255,   216,    77,   228,    40,    78,    79,   238,   335,   336,
     337,   239,   240,   201,    40,   246,   254,   342,   266,   265,
     271,   197,   198,   199,   200,   201,    23,    24,    25,    26,
      27,   157,   274,   277,   218,   219,   316,    41,   278,   197,
     198,   199,   200,   201,   211,   296,   302,    41,   158,   159,
     160,   161,   236,   162,   307,   308,   163,   197,   198,   199,
     200,   201,   269,   309,   197,   198,   199,   200,   201,   245,
     310,   313,   197,   198,   199,   200,   201,   197,   198,   199,
     200,   201,   197,   198,   199,   200,   201,   318,   197,   198,
     199,   200,   201,    14,   322,    15,    16,    17,    18,    19,
      20,    21,   324,    22,   327,   328,   329,   332,   334,   333,
     338,   340,   341,    13,   260,   144,   149,   184,   291,   320,
       0,   287,   151
};

static const yytype_int16 yycheck[] =
{
      14,   131,    65,    24,    60,    55,    62,    21,    53,    23,
      24,    25,    26,    27,    36,     5,   278,   119,    36,    30,
      27,    70,     5,   308,    36,   310,    37,    76,    39,   185,
      36,   133,    46,    47,   296,   191,    26,    82,    53,    27,
      51,    52,    53,    54,   174,    28,    53,    69,    69,   112,
      56,    69,    74,   338,   104,   157,   106,    69,    70,    69,
     162,   163,    76,    69,    70,    53,    81,    18,   170,   171,
      21,   173,   202,    76,    25,    70,    79,    72,    29,    30,
      31,   211,   132,    34,   186,    36,    37,    38,   102,     0,
      75,    76,    77,   107,    79,   197,   198,   199,   200,   201,
      11,    69,   204,   114,    10,    11,    12,    13,    14,    15,
      18,    17,    20,    21,     3,     4,   218,    25,    69,     0,
     134,    29,    30,    31,    59,   227,    34,    53,    36,    37,
      38,    54,    55,    26,   236,    28,   150,   239,    40,    41,
      42,    43,   244,   245,   246,    80,     8,    82,    55,     5,
       5,    36,    75,    76,    77,    78,    79,     5,   172,    54,
      55,    69,    18,    32,    33,    21,    35,   269,    53,    25,
      68,   185,    81,    29,    30,    31,     5,   191,    34,    70,
      36,    37,    38,   285,    69,    70,    71,    72,    73,    18,
      75,     6,    21,    78,     3,    54,    25,   253,     4,    66,
      29,    30,    31,    18,    80,    34,    21,    36,    37,    38,
      25,    53,   268,    69,    29,    30,    31,   267,    76,    34,
      53,    36,    37,    38,    75,    76,    77,   283,    79,    53,
      53,   281,    69,    55,   248,   249,    54,    44,    45,    46,
      69,   297,    69,    53,   300,    16,    67,   303,    67,   299,
      54,   265,    53,    67,    69,    67,    53,    75,    76,    77,
      78,    79,   312,   277,   278,   315,    53,   317,    53,   325,
     326,    75,    76,    77,    78,    79,    68,    69,    70,    55,
     330,   331,   296,     7,    80,     9,    10,    11,    12,    13,
      14,    15,    55,    17,    53,   309,    18,    54,    81,    21,
      22,    54,    54,    25,    82,    54,    54,    29,    30,    31,
      54,    54,    34,    19,    36,    37,    38,    54,   332,   333,
     334,    55,    54,    79,    36,    80,    54,   341,    54,    33,
      26,    75,    76,    77,    78,    79,    60,    61,    62,    63,
      64,    53,    28,    53,    56,    57,    54,    69,    53,    75,
      76,    77,    78,    79,    55,    53,    25,    69,    70,    71,
      72,    73,    55,    75,    25,    54,    78,    75,    76,    77,
      78,    79,    55,    55,    75,    76,    77,    78,    79,    56,
      54,    21,    75,    76,    77,    78,    79,    75,    76,    77,
      78,    79,    75,    76,    77,    78,    79,    54,    75,    76,
      77,    78,    79,     7,    54,     9,    10,    11,    12,    13,
      14,    15,    21,    17,     5,     5,    36,    32,    53,    33,
      54,     5,    33,     4,   244,   106,   110,   136,   275,   309,
      -1,   272,   112
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,     3,     4,    86,    87,    88,    89,    90,    91,    97,
      69,    69,     0,    88,     7,     9,    10,    11,    12,    13,
      14,    15,    17,    60,    61,    62,    63,    64,    96,    98,
      99,   100,   101,   161,   165,   166,    92,    97,    93,    97,
      36,    69,   160,     8,    53,   102,    53,    81,   160,   160,
     160,   160,   160,    70,   160,   116,    96,    55,   106,     5,
      96,     5,    96,    68,   160,   160,    70,    96,    96,    96,
      96,    18,    21,    25,    29,    30,    31,    34,    37,    38,
     117,   118,   119,   122,   124,   127,   129,   140,   142,   143,
     144,   146,   148,   149,   155,   160,    40,    41,    42,    43,
     104,   105,    81,     3,   116,     4,   116,    80,    54,    14,
     100,   162,   163,   164,    66,   167,   167,   167,   167,    53,
      24,    69,    26,    28,    70,    72,    76,    74,   141,   160,
      53,    53,    59,    80,    82,    53,    55,   108,   109,   160,
      69,     6,    94,    69,    94,    56,    70,   103,   160,   106,
      16,   164,    96,    67,    67,    67,    67,    53,    70,    71,
      72,    73,    75,    78,   150,   151,   152,   153,   155,    53,
      80,    53,    53,    55,    53,   150,   158,   158,   155,   150,
     160,    44,    45,    46,   104,    55,    53,   111,   112,    95,
      54,    81,   160,   150,   150,   150,    54,    75,    76,    77,
      78,    79,    53,   154,   125,   150,   150,   160,   147,   150,
     158,    55,    54,    54,    54,    54,    54,   108,    56,    57,
     113,   114,   150,   110,   156,   108,    54,    55,    19,   150,
     150,   150,   150,   150,   158,   150,    55,    54,    54,    55,
      54,   158,   150,    54,    55,    56,    80,   115,    32,    33,
      35,   157,   150,   120,    54,    54,   150,   128,   130,   150,
     114,   150,   150,   160,   160,    33,    54,   116,   126,    55,
     145,    26,   136,   137,    28,   131,   132,    53,    53,   160,
      20,   116,   150,   123,    27,    53,     5,   137,    27,    53,
       5,   132,   107,   159,   160,   159,    53,   121,     5,   116,
     139,   150,    25,   134,    70,    76,   135,    25,    54,    55,
      54,   159,   116,    21,     5,   116,    54,   116,    54,    92,
     107,    92,    54,    22,    21,   138,   133,     5,     5,    36,
     116,   116,    32,    33,    53,   160,   160,   160,    54,    92,
       5,    33,   160
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_uint8 yyr1[] =
{
       0,    85,    86,    86,    87,    87,    88,    88,    89,    90,
      90,    91,    91,    92,    93,    95,    94,    94,    96,    96,
      97,    97,    98,    98,    99,    99,    99,    99,   100,   100,
     100,   100,   100,   100,   100,   101,   102,   102,   103,   103,
     103,   104,   104,   105,   105,   105,   105,   105,   105,   106,
     106,   107,   107,   108,   108,   110,   109,   111,   111,   112,
     113,   113,   114,   114,   114,   114,   114,   114,   115,   115,
     116,   116,   117,   117,   117,   117,   117,   117,   117,   117,
     117,   117,   117,   117,   117,   118,   120,   121,   119,   123,
     122,   125,   126,   124,   128,   127,   130,   129,   131,   131,
     133,   132,   134,   132,   135,   135,   136,   136,   138,   137,
     139,   137,   140,   141,   141,   142,   143,   143,   143,   144,
     145,   145,   146,   147,   147,   148,   149,   150,   150,   150,
     150,   150,   150,   150,   150,   151,   152,   152,   152,   152,
     152,   152,   152,   153,   154,   154,   155,   155,   156,   156,
     157,   157,   157,   157,   157,   157,   158,   158,   158,   159,
     159,   160,   160,   161,   162,   162,   163,   163,   164,   165,
     165,   165,   166,   166,   166,   166,   167,   167
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     1,     1,     1,     2,     1,     1,     3,     6,
       5,     6,     5,     4,     4,     0,     3,     0,     0,     2,
       0,     2,     1,     1,     4,     2,     2,     1,     1,     1,
       1,     1,     4,     2,     1,     2,     0,     5,     1,     1,
       1,     1,     3,     1,     1,     1,     4,     4,     4,     0,
       2,     1,     3,     1,     3,     0,     4,     0,     1,     3,
       1,     3,     1,     1,     1,     2,     2,     3,     0,     2,
       0,     2,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     3,     0,     0,    11,     0,
      11,     0,     0,    10,     0,     9,     0,     9,     1,     2,
       0,     6,     0,     4,     1,     1,     1,     2,     0,     6,
       0,     4,     5,     1,     1,     1,     1,     2,     2,     3,
       0,     2,     4,     1,     3,     4,     4,     3,     3,     3,
       3,     3,     1,     2,     2,     1,     1,     1,     1,     1,
       1,     3,     2,     5,     0,     3,     1,     3,     0,     2,
       8,     9,     8,     9,    13,    14,     0,     1,     3,     0,
       1,     1,     1,     6,     0,     1,     1,     2,     4,     2,
       3,     2,     5,     5,     5,     5,     0,     2
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)




# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp,
                 int yyrule)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)]);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif


/* Context of a parse error.  */
typedef struct
{
  yy_state_t *yyssp;
  yysymbol_kind_t yytoken;
} yypcontext_t;

/* Put in YYARG at most YYARGN of the expected tokens given the
   current YYCTX, and return the number of tokens stored in YYARG.  If
   YYARG is null, return the number of expected tokens (guaranteed to
   be less than YYNTOKENS).  Return YYENOMEM on memory exhaustion.
   Return 0 if there are more than YYARGN expected tokens, yet fill
   YYARG up to YYARGN. */
static int
yypcontext_expected_tokens (const yypcontext_t *yyctx,
                            yysymbol_kind_t yyarg[], int yyargn)
{
  /* Actual size of YYARG. */
  int yycount = 0;
  int yyn = yypact[+*yyctx->yyssp];
  if (!yypact_value_is_default (yyn))
    {
      /* Start YYX at -YYN if negative to avoid negative indexes in
         YYCHECK.  In other words, skip the first -YYN actions for
         this state because they are default actions.  */
      int yyxbegin = yyn < 0 ? -yyn : 0;
      /* Stay within bounds of both yycheck and yytname.  */
      int yychecklim = YYLAST - yyn + 1;
      int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
      int yyx;
      for (yyx = yyxbegin; yyx < yyxend; ++yyx)
        if (yycheck[yyx + yyn] == yyx && yyx != YYSYMBOL_YYerror
            && !yytable_value_is_error (yytable[yyx + yyn]))
          {
            if (!yyarg)
              ++yycount;
            else if (yycount == yyargn)
              return 0;
            else
              yyarg[yycount++] = YY_CAST (yysymbol_kind_t, yyx);
          }
    }
  if (yyarg && yycount == 0 && 0 < yyargn)
    yyarg[0] = YYSYMBOL_YYEMPTY;
  return yycount;
}




#ifndef yystrlen
# if defined __GLIBC__ && defined _STRING_H
#  define yystrlen(S) (YY_CAST (YYPTRDIFF_T, strlen (S)))
# else
/* Return the length of YYSTR.  */
static YYPTRDIFF_T
yystrlen (const char *yystr)
{
  YYPTRDIFF_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
# endif
#endif

#ifndef yystpcpy
# if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#  define yystpcpy stpcpy
# else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
yystpcpy (char *yydest, const char *yysrc)
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
# endif
#endif

#ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYPTRDIFF_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      YYPTRDIFF_T yyn = 0;
      char const *yyp = yystr;
      for (;;)
        switch (*++yyp)
          {
          case '\'':
          case ',':
            goto do_not_strip_quotes;

          case '\\':
            if (*++yyp != '\\')
              goto do_not_strip_quotes;
            else
              goto append;

          append:
          default:
            if (yyres)
              yyres[yyn] = *yyp;
            yyn++;
            break;

          case '"':
            if (yyres)
              yyres[yyn] = '\0';
            return yyn;
          }
    do_not_strip_quotes: ;
    }

  if (yyres)
    return yystpcpy (yyres, yystr) - yyres;
  else
    return yystrlen (yystr);
}
#endif


static int
yy_syntax_error_arguments (const yypcontext_t *yyctx,
                           yysymbol_kind_t yyarg[], int yyargn)
{
  /* Actual size of YYARG. */
  int yycount = 0;
  /* There are many possibilities here to consider:
     - If this state is a consistent state with a default action, then
       the only way this function was invoked is if the default action
       is an error action.  In that case, don't check for expected
       tokens because there are none.
     - The only way there can be no lookahead present (in yychar) is if
       this state is a consistent state with a default action.  Thus,
       detecting the absence of a lookahead is sufficient to determine
       that there is no unexpected or expected token to report.  In that
       case, just report a simple "syntax error".
     - Don't assume there isn't a lookahead just because this state is a
       consistent state with a default action.  There might have been a
       previous inconsistent state, consistent state with a non-default
       action, or user semantic action that manipulated yychar.
     - Of course, the expected token list depends on states to have
       correct lookahead information, and it depends on the parser not
       to perform extra reductions after fetching a lookahead from the
       scanner and before detecting a syntax error.  Thus, state merging
       (from LALR or IELR) and default reductions corrupt the expected
       token list.  However, the list is correct for canonical LR with
       one exception: it will still contain any token that will not be
       accepted due to an error action in a later state.
  */
  if (yyctx->yytoken != YYSYMBOL_YYEMPTY)
    {
      int yyn;
      if (yyarg)
        yyarg[yycount] = yyctx->yytoken;
      ++yycount;
      yyn = yypcontext_expected_tokens (yyctx,
                                        yyarg ? yyarg + 1 : yyarg, yyargn - 1);
      if (yyn == YYENOMEM)
        return YYENOMEM;
      else
        yycount += yyn;
    }
  return yycount;
}

/* Copy into *YYMSG, which is of size *YYMSG_ALLOC, an error message
   about the unexpected token YYTOKEN for the state stack whose top is
   YYSSP.

   Return 0 if *YYMSG was successfully written.  Return -1 if *YYMSG is
   not large enough to hold the message.  In that case, also set
   *YYMSG_ALLOC to the required number of bytes.  Return YYENOMEM if the
   required number of bytes is too large to store.  */
static int
yysyntax_error (YYPTRDIFF_T *yymsg_alloc, char **yymsg,
                const yypcontext_t *yyctx)
{
  enum { YYARGS_MAX = 5 };
  /* Internationalized format string. */
  const char *yyformat = YY_NULLPTR;
  /* Arguments of yyformat: reported tokens (one for the "unexpected",
     one per "expected"). */
  yysymbol_kind_t yyarg[YYARGS_MAX];
  /* Cumulated lengths of YYARG.  */
  YYPTRDIFF_T yysize = 0;

  /* Actual size of YYARG. */
  int yycount = yy_syntax_error_arguments (yyctx, yyarg, YYARGS_MAX);
  if (yycount == YYENOMEM)
    return YYENOMEM;

  switch (yycount)
    {
#define YYCASE_(N, S)                       \
      case N:                               \
        yyformat = S;                       \
        break
    default: /* Avoid compiler warnings. */
      YYCASE_(0, YY_("syntax error"));
      YYCASE_(1, YY_("syntax error, unexpected %s"));
      YYCASE_(2, YY_("syntax error, unexpected %s, expecting %s"));
      YYCASE_(3, YY_("syntax error, unexpected %s, expecting %s or %s"));
      YYCASE_(4, YY_("syntax error, unexpected %s, expecting %s or %s or %s"));
      YYCASE_(5, YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s"));
#undef YYCASE_
    }

  /* Compute error message size.  Don't count the "%s"s, but reserve
     room for the terminator.  */
  yysize = yystrlen (yyformat) - 2 * yycount + 1;
  {
    int yyi;
    for (yyi = 0; yyi < yycount; ++yyi)
      {
        YYPTRDIFF_T yysize1
          = yysize + yytnamerr (YY_NULLPTR, yytname[yyarg[yyi]]);
        if (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM)
          yysize = yysize1;
        else
          return YYENOMEM;
      }
  }

  if (*yymsg_alloc < yysize)
    {
      *yymsg_alloc = 2 * yysize;
      if (! (yysize <= *yymsg_alloc
             && *yymsg_alloc <= YYSTACK_ALLOC_MAXIMUM))
        *yymsg_alloc = YYSTACK_ALLOC_MAXIMUM;
      return -1;
    }

  /* Avoid sprintf, as that infringes on the user's name space.
     Don't have undefined behavior even if the translation
     produced a string with the wrong number of "%s"s.  */
  {
    char *yyp = *yymsg;
    int yyi = 0;
    while ((*yyp = *yyformat) != '\0')
      if (*yyp == '%' && yyformat[1] == 's' && yyi < yycount)
        {
          yyp += yytnamerr (yyp, yytname[yyarg[yyi++]]);
          yyformat += 2;
        }
      else
        {
          ++yyp;
          ++yyformat;
        }
  }
  return 0;
}


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep)
{
  YY_USE (yyvaluep);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/* Lookahead token kind.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;
/* Number of syntax errors so far.  */
int yynerrs;




/*----------.
| yyparse.  |
`----------*/

int
yyparse (void)
{
    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;

  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYPTRDIFF_T yymsg_alloc = sizeof yymsgbuf;

#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex ();
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 2: /* start: compilation_units  */
#line 388 "parser.y"
    {
        (yyval.node) = NODE("start", 1, (yyvsp[0].node));
        dt_set_root((yyval.node));
    }
#line 2107 "parser.tab.c"
    break;

  case 3: /* start: free_form  */
#line 393 "parser.y"
    {
        (yyval.node) = NODE("start", 1, (yyvsp[0].node));
        dt_set_root((yyval.node));
    }
#line 2116 "parser.tab.c"
    break;

  case 4: /* compilation_units: compilation_unit  */
#line 400 "parser.y"
    {
        (yyval.node) = NODE("compilation_units", 1, (yyvsp[0].node));
    }
#line 2124 "parser.tab.c"
    break;

  case 5: /* compilation_units: compilation_units compilation_unit  */
#line 404 "parser.y"
    {
        (yyval.node) = NODE("compilation_units", 2, (yyvsp[-1].node), (yyvsp[0].node));
    }
#line 2132 "parser.tab.c"
    break;

  case 6: /* compilation_unit: program_unit  */
#line 410 "parser.y"
    {
        (yyval.node) = NODE("compilation_unit", 1, (yyvsp[0].node));
    }
#line 2140 "parser.tab.c"
    break;

  case 7: /* compilation_unit: module_unit  */
#line 414 "parser.y"
    {
        (yyval.node) = NODE("compilation_unit", 1, (yyvsp[0].node));
    }
#line 2148 "parser.tab.c"
    break;

  case 8: /* free_form: preamble declarations executables  */
#line 420 "parser.y"
    {
        (yyval.node) = NODE("free_form", 3, (yyvsp[-2].node), (yyvsp[-1].node), (yyvsp[0].node));
    }
#line 2156 "parser.tab.c"
    break;

  case 9: /* program_unit: PROGRAM IDENTIFIER program_body END PROGRAM IDENTIFIER  */
#line 426 "parser.y"
    {
        (yyval.node) = NODE("program_unit", 6, LEAF("PROGRAM"), LEAF("IDENTIFIER"), (yyvsp[-3].node), LEAF("END"), LEAF("PROGRAM"), LEAF("IDENTIFIER"));
    }
#line 2164 "parser.tab.c"
    break;

  case 10: /* program_unit: PROGRAM IDENTIFIER program_body END PROGRAM  */
#line 430 "parser.y"
    {
        (yyval.node) = NODE("program_unit", 5, LEAF("PROGRAM"), LEAF("IDENTIFIER"), (yyvsp[-2].node), LEAF("END"), LEAF("PROGRAM"));
    }
#line 2172 "parser.tab.c"
    break;

  case 11: /* module_unit: MODULE IDENTIFIER module_body END MODULE IDENTIFIER  */
#line 436 "parser.y"
    {
        (yyval.node) = NODE("module_unit", 6, LEAF("MODULE"), LEAF("IDENTIFIER"), (yyvsp[-3].node), LEAF("END"), LEAF("MODULE"), LEAF("IDENTIFIER"));
    }
#line 2180 "parser.tab.c"
    break;

  case 12: /* module_unit: MODULE IDENTIFIER module_body END MODULE  */
#line 440 "parser.y"
    {
        (yyval.node) = NODE("module_unit", 5, LEAF("MODULE"), LEAF("IDENTIFIER"), (yyvsp[-2].node), LEAF("END"), LEAF("MODULE"));
    }
#line 2188 "parser.tab.c"
    break;

  case 13: /* program_body: preamble declarations executables contains_block  */
#line 446 "parser.y"
    {
        (yyval.node) = NODE("program_body", 4, (yyvsp[-3].node), (yyvsp[-2].node), (yyvsp[-1].node), (yyvsp[0].node));
    }
#line 2196 "parser.tab.c"
    break;

  case 14: /* module_body: preamble declarations executables contains_block  */
#line 452 "parser.y"
    {
        (yyval.node) = NODE("module_body", 4, (yyvsp[-3].node), (yyvsp[-2].node), (yyvsp[-1].node), (yyvsp[0].node));
    }
#line 2204 "parser.tab.c"
    break;

  case 15: /* $@1: %empty  */
#line 458 "parser.y"
  {
    sdt_emit_push(0);
  }
#line 2212 "parser.tab.c"
    break;

  case 16: /* contains_block: CONTAINS $@1 subprogram_list  */
#line 462 "parser.y"
  {
    sdt_emit_pop();
    (yyval.node) = NODE("contains_block", 2, LEAF("CONTAINS"), (yyvsp[0].node));
  }
#line 2221 "parser.tab.c"
    break;

  case 17: /* contains_block: %empty  */
#line 467 "parser.y"
    {
        (yyval.node) = NODE0("contains_block");
    }
#line 2229 "parser.tab.c"
    break;

  case 18: /* declarations: %empty  */
#line 473 "parser.y"
  {
    (yyval.node) = NODE0("declarations");
  }
#line 2237 "parser.tab.c"
    break;

  case 19: /* declarations: declaration declarations  */
#line 477 "parser.y"
    {
        (yyval.node) = NODE("declarations", 2, (yyvsp[-1].node), (yyvsp[0].node));
    }
#line 2245 "parser.tab.c"
    break;

  case 20: /* preamble: %empty  */
#line 483 "parser.y"
  {
    (yyval.node) = NODE0("preamble");
  }
#line 2253 "parser.tab.c"
    break;

  case 21: /* preamble: preamble pp_item  */
#line 487 "parser.y"
    {
        (yyval.node) = NODE("preamble", 2, (yyvsp[-1].node), (yyvsp[0].node));
    }
#line 2261 "parser.tab.c"
    break;

  case 22: /* pp_item: pp_define_undef  */
#line 493 "parser.y"
    {
        (yyval.node) = NODE("pp_item", 1, (yyvsp[0].node));
    }
#line 2269 "parser.tab.c"
    break;

  case 23: /* pp_item: pp_if_block  */
#line 497 "parser.y"
    {
        (yyval.node) = NODE("pp_item", 1, (yyvsp[0].node));
    }
#line 2277 "parser.tab.c"
    break;

  case 24: /* declaration: type_spec declaration_attributes DECL_SEP declarator_list  */
#line 503 "parser.y"
    {
        (yyval.node) = NODE("declaration", 4, (yyvsp[-3].node), (yyvsp[-2].node), LEAF("DECL_SEP"), (yyvsp[0].node));
    }
#line 2285 "parser.tab.c"
    break;

  case 25: /* declaration: IMPLICIT NONE  */
#line 507 "parser.y"
    {
        (yyval.node) = NODE("declaration", 2, LEAF("IMPLICIT"), LEAF("NONE"));
    }
#line 2293 "parser.tab.c"
    break;

  case 26: /* declaration: USE identifier  */
#line 511 "parser.y"
    {
        (yyval.node) = NODE("declaration", 2, LEAF("USE"), LEAF("IDENTIFIER"));
    }
#line 2301 "parser.tab.c"
    break;

  case 27: /* declaration: type_def  */
#line 515 "parser.y"
    {
        (yyval.node) = NODE("declaration", 1, (yyvsp[0].node));
    }
#line 2309 "parser.tab.c"
    break;

  case 28: /* type_spec: INTEGER  */
#line 521 "parser.y"
    {
        (yyval.node) = NODE("type_spec", 1, LEAF("INTEGER"));
    }
#line 2317 "parser.tab.c"
    break;

  case 29: /* type_spec: REAL  */
#line 525 "parser.y"
    {
        (yyval.node) = NODE("type_spec", 1, LEAF("REAL"));
    }
#line 2325 "parser.tab.c"
    break;

  case 30: /* type_spec: LOGICAL  */
#line 529 "parser.y"
    {
        (yyval.node) = NODE("type_spec", 1, LEAF("LOGICAL"));
    }
#line 2333 "parser.tab.c"
    break;

  case 31: /* type_spec: char_type_spec  */
#line 533 "parser.y"
    {
        (yyval.node) = NODE("type_spec", 1, (yyvsp[0].node));
    }
#line 2341 "parser.tab.c"
    break;

  case 32: /* type_spec: TYPE LPAREN identifier RPAREN  */
#line 537 "parser.y"
    {
        (yyval.node) = NODE("type_spec", 4, LEAF("TYPE"), LEAF("LPAREN"), LEAF("IDENTIFIER"), LEAF("RPAREN"));
    }
#line 2349 "parser.tab.c"
    break;

  case 33: /* type_spec: CLASS identifier  */
#line 541 "parser.y"
    {
        (yyval.node) = NODE("type_spec", 2, LEAF("CLASS"), LEAF("IDENTIFIER"));
    }
#line 2357 "parser.tab.c"
    break;

  case 34: /* type_spec: COMPLEX  */
#line 545 "parser.y"
    {
        (yyval.node) = NODE("type_spec", 1, LEAF("COMPLEX"));
    }
#line 2365 "parser.tab.c"
    break;

  case 35: /* char_type_spec: CHARACTER char_len_opt  */
#line 551 "parser.y"
    {
        (yyval.node) = NODE("char_type_spec", 2, LEAF("CHARACTER"), (yyvsp[0].node));
    }
#line 2373 "parser.tab.c"
    break;

  case 36: /* char_len_opt: %empty  */
#line 557 "parser.y"
  {
    (yyval.node) = NODE0("char_len_opt");
  }
#line 2381 "parser.tab.c"
    break;

  case 37: /* char_len_opt: LPAREN LENGTH_SPECIFIER ASSIGN char_len_value RPAREN  */
#line 561 "parser.y"
    {
        (yyval.node) = NODE("char_len_opt", 5, LEAF("LPAREN"), LEAF("LENGTH_SPECIFIER"), LEAF("ASSIGN"), (yyvsp[-1].node), LEAF("RPAREN"));
    }
#line 2389 "parser.tab.c"
    break;

  case 38: /* char_len_value: COLON  */
#line 567 "parser.y"
    {
        (yyval.node) = NODE("char_len_value", 1, LEAF("COLON"));
    }
#line 2397 "parser.tab.c"
    break;

  case 39: /* char_len_value: INT_CONST  */
#line 571 "parser.y"
    {
        (yyval.node) = NODE("char_len_value", 1, LEAF("INT_CONST"));
    }
#line 2405 "parser.tab.c"
    break;

  case 40: /* char_len_value: identifier  */
#line 575 "parser.y"
    {
        (yyval.node) = NODE("char_len_value", 1, LEAF("IDENTIFIER"));
    }
#line 2413 "parser.tab.c"
    break;

  case 41: /* attributes: attribute  */
#line 581 "parser.y"
    {
        (yyval.node) = NODE("attributes", 1, (yyvsp[0].node));
    }
#line 2421 "parser.tab.c"
    break;

  case 42: /* attributes: attribute COMMA attributes  */
#line 585 "parser.y"
    {
        (yyval.node) = NODE("attributes", 3, (yyvsp[-2].node), LEAF("COMMA"), (yyvsp[0].node));
    }
#line 2429 "parser.tab.c"
    break;

  case 43: /* attribute: ALLOCATABLE  */
#line 591 "parser.y"
    {
        (yyval.node) = NODE("attribute", 1, LEAF("ALLOCATABLE"));
    }
#line 2437 "parser.tab.c"
    break;

  case 44: /* attribute: POINTER  */
#line 595 "parser.y"
    {
        (yyval.node) = NODE("attribute", 1, LEAF("POINTER"));
    }
#line 2445 "parser.tab.c"
    break;

  case 45: /* attribute: TARGET  */
#line 599 "parser.y"
    {
        (yyval.node) = NODE("attribute", 1, LEAF("TARGET"));
    }
#line 2453 "parser.tab.c"
    break;

  case 46: /* attribute: INTENT LPAREN IN RPAREN  */
#line 603 "parser.y"
    {
        (yyval.node) = NODE("attribute", 4, LEAF("INTENT"), LEAF("LPAREN"), LEAF("IN"), LEAF("RPAREN"));
    }
#line 2461 "parser.tab.c"
    break;

  case 47: /* attribute: INTENT LPAREN OUT RPAREN  */
#line 607 "parser.y"
    {
        (yyval.node) = NODE("attribute", 4, LEAF("INTENT"), LEAF("LPAREN"), LEAF("OUT"), LEAF("RPAREN"));
    }
#line 2469 "parser.tab.c"
    break;

  case 48: /* attribute: INTENT LPAREN INOUT RPAREN  */
#line 611 "parser.y"
    {
        (yyval.node) = NODE("attribute", 4, LEAF("INTENT"), LEAF("LPAREN"), LEAF("INOUT"), LEAF("RPAREN"));
    }
#line 2477 "parser.tab.c"
    break;

  case 49: /* declaration_attributes: %empty  */
#line 617 "parser.y"
  {
    (yyval.node) = NODE0("declaration_attributes");
  }
#line 2485 "parser.tab.c"
    break;

  case 50: /* declaration_attributes: COMMA attributes  */
#line 621 "parser.y"
    {
        (yyval.node) = NODE("declaration_attributes", 2, LEAF("COMMA"), (yyvsp[0].node));
    }
#line 2493 "parser.tab.c"
    break;

  case 51: /* identifier_list: identifier  */
#line 627 "parser.y"
    {
    (yyval.node) = NODE("identifier_list", 1, LEAF("IDENTIFIER"));
    }
#line 2501 "parser.tab.c"
    break;

  case 52: /* identifier_list: identifier COMMA identifier_list  */
#line 631 "parser.y"
    {
    (yyval.node) = NODE("identifier_list", 3, LEAF("IDENTIFIER"), LEAF("COMMA"), (yyvsp[0].node));
    }
#line 2509 "parser.tab.c"
    break;

  case 53: /* declarator_list: declarator  */
#line 637 "parser.y"
    {
        (yyval.node) = NODE("declarator_list", 1, (yyvsp[0].node));
    }
#line 2517 "parser.tab.c"
    break;

  case 54: /* declarator_list: declarator COMMA declarator_list  */
#line 641 "parser.y"
    {
        (yyval.node) = NODE("declarator_list", 3, (yyvsp[-2].node), LEAF("COMMA"), (yyvsp[0].node));
    }
#line 2525 "parser.tab.c"
    break;

  case 55: /* $@2: %empty  */
#line 647 "parser.y"
    {
    g_decl_name = (yyvsp[-1].text);
    }
#line 2533 "parser.tab.c"
    break;

  case 56: /* declarator: identifier array_spec_opt $@2 init_opt  */
#line 651 "parser.y"
    {
    if (g_decl_name && g_decl_init && g_decl_init->place) {
      tac_emit_assign(g_decl_name, g_decl_init->place);
    }
    if (g_decl_name && g_decl_has_array) {
      sdt_register_array(g_decl_name);
    }
    g_decl_init = NULL;
    (yyval.node) = NODE("declarator", 3, LEAF("IDENTIFIER"), (yyvsp[-2].node), (yyvsp[0].node));
    }
#line 2548 "parser.tab.c"
    break;

  case 57: /* array_spec_opt: %empty  */
#line 664 "parser.y"
  {
    g_decl_has_array = 0;
    (yyval.node) = NODE0("array_spec_opt");
  }
#line 2557 "parser.tab.c"
    break;

  case 58: /* array_spec_opt: array_spec  */
#line 669 "parser.y"
    {
        g_decl_has_array = 1;
        (yyval.node) = NODE("array_spec_opt", 1, (yyvsp[0].node));
    }
#line 2566 "parser.tab.c"
    break;

  case 59: /* array_spec: LPAREN array_spec_list RPAREN  */
#line 676 "parser.y"
    {
        (yyval.node) = NODE("array_spec", 3, LEAF("LPAREN"), (yyvsp[-1].node), LEAF("RPAREN"));
    }
#line 2574 "parser.tab.c"
    break;

  case 60: /* array_spec_list: array_spec_item  */
#line 682 "parser.y"
    {
        (yyval.node) = NODE("array_spec_list", 1, (yyvsp[0].node));
    }
#line 2582 "parser.tab.c"
    break;

  case 61: /* array_spec_list: array_spec_list COMMA array_spec_item  */
#line 686 "parser.y"
    {
        (yyval.node) = NODE("array_spec_list", 3, (yyvsp[-2].node), LEAF("COMMA"), (yyvsp[0].node));
    }
#line 2590 "parser.tab.c"
    break;

  case 62: /* array_spec_item: ASSUMED_RANK_SPECIFIER  */
#line 692 "parser.y"
    {
        (yyval.node) = NODE("array_spec_item", 1, LEAF("ASSUMED_RANK_SPECIFIER"));
    }
#line 2598 "parser.tab.c"
    break;

  case 63: /* array_spec_item: COLON  */
#line 696 "parser.y"
    {
        (yyval.node) = NODE("array_spec_item", 1, LEAF("COLON"));
    }
#line 2606 "parser.tab.c"
    break;

  case 64: /* array_spec_item: expression  */
#line 700 "parser.y"
    {
        (yyval.node) = NODE("array_spec_item", 1, LEAF("expression"));
    }
#line 2614 "parser.tab.c"
    break;

  case 65: /* array_spec_item: expression COLON  */
#line 704 "parser.y"
    {
        (yyval.node) = NODE("array_spec_item", 2, LEAF("expression"), LEAF("COLON"));
    }
#line 2622 "parser.tab.c"
    break;

  case 66: /* array_spec_item: COLON expression  */
#line 708 "parser.y"
    {
        (yyval.node) = NODE("array_spec_item", 2, LEAF("COLON"), LEAF("expression"));
    }
#line 2630 "parser.tab.c"
    break;

  case 67: /* array_spec_item: expression COLON expression  */
#line 712 "parser.y"
    {
        (yyval.node) = NODE("array_spec_item", 3, LEAF("expression"), LEAF("COLON"), LEAF("expression"));
    }
#line 2638 "parser.tab.c"
    break;

  case 68: /* init_opt: %empty  */
#line 718 "parser.y"
  {
    g_decl_init = NULL;
    (yyval.node) = NODE0("init_opt");
  }
#line 2647 "parser.tab.c"
    break;

  case 69: /* init_opt: ASSIGN expression  */
#line 723 "parser.y"
    {
        g_decl_init = (yyvsp[0].tac);
        (yyval.node) = NODE("init_opt", 2, LEAF("ASSIGN"), LEAF("expression"));
    }
#line 2656 "parser.tab.c"
    break;

  case 70: /* executables: %empty  */
#line 730 "parser.y"
  {
    (yyval.node) = NODE0("executables");
  }
#line 2664 "parser.tab.c"
    break;

  case 71: /* executables: executables executable  */
#line 734 "parser.y"
    {
        (yyval.node) = NODE("executables", 2, (yyvsp[-1].node), (yyvsp[0].node));
    }
#line 2672 "parser.tab.c"
    break;

  case 72: /* executable: assignment_stmt  */
#line 740 "parser.y"
    {
    (yyval.node) = NODE0("executable");
    }
#line 2680 "parser.tab.c"
    break;

  case 73: /* executable: if_stmt  */
#line 744 "parser.y"
    {
        (yyval.node) = NODE("executable", 1, (yyvsp[0].node));
    }
#line 2688 "parser.tab.c"
    break;

  case 74: /* executable: print_stmt  */
#line 748 "parser.y"
    {
        (yyval.node) = NODE("executable", 1, (yyvsp[0].node));
    }
#line 2696 "parser.tab.c"
    break;

  case 75: /* executable: allocate_stmt  */
#line 752 "parser.y"
    {
        (yyval.node) = NODE("executable", 1, (yyvsp[0].node));
    }
#line 2704 "parser.tab.c"
    break;

  case 76: /* executable: deallocate_stmt  */
#line 756 "parser.y"
    {
        (yyval.node) = NODE("executable", 1, (yyvsp[0].node));
    }
#line 2712 "parser.tab.c"
    break;

  case 77: /* executable: do_stmt  */
#line 760 "parser.y"
    {
        (yyval.node) = NODE("executable", 1, (yyvsp[0].node));
    }
#line 2720 "parser.tab.c"
    break;

  case 78: /* executable: dowhile_stmt  */
#line 764 "parser.y"
    {
        (yyval.node) = NODE("executable", 1, (yyvsp[0].node));
    }
#line 2728 "parser.tab.c"
    break;

  case 79: /* executable: select_rank_stmt  */
#line 768 "parser.y"
    {
        (yyval.node) = NODE("executable", 1, (yyvsp[0].node));
    }
#line 2736 "parser.tab.c"
    break;

  case 80: /* executable: select_stmt  */
#line 772 "parser.y"
    {
        (yyval.node) = NODE("executable", 1, (yyvsp[0].node));
    }
#line 2744 "parser.tab.c"
    break;

  case 81: /* executable: call_stmt  */
#line 776 "parser.y"
    {
        (yyval.node) = NODE("executable", 1, (yyvsp[0].node));
    }
#line 2752 "parser.tab.c"
    break;

  case 82: /* executable: return_stmt  */
#line 780 "parser.y"
    {
        (yyval.node) = NODE("executable", 1, (yyvsp[0].node));
    }
#line 2760 "parser.tab.c"
    break;

  case 83: /* executable: stop_stmt  */
#line 784 "parser.y"
    {
        (yyval.node) = NODE("executable", 1, (yyvsp[0].node));
    }
#line 2768 "parser.tab.c"
    break;

  case 84: /* executable: pointer_stmt  */
#line 788 "parser.y"
    {
        (yyval.node) = NODE("executable", 1, (yyvsp[0].node));
    }
#line 2776 "parser.tab.c"
    break;

  case 85: /* assignment_stmt: variable_ref ASSIGN expression  */
#line 794 "parser.y"
    {
    if ((yyvsp[-2].tac) && (yyvsp[0].tac)) {
      tac_emit_assign((yyvsp[-2].tac)->place, (yyvsp[0].tac)->place);
    }
    (yyval.tac) = tac_make_value(NULL);
    }
#line 2787 "parser.tab.c"
    break;

  case 86: /* $@3: %empty  */
#line 803 "parser.y"
  {
    SdtIfCtx ctx = sdt_if_push();
    if ((yyvsp[-2].tac)) {
      tac_emit_if_false_goto((yyvsp[-2].tac)->place, ctx.else_label);
    }
  }
#line 2798 "parser.tab.c"
    break;

  case 87: /* $@4: %empty  */
#line 810 "parser.y"
  {
    SdtIfCtx ctx = sdt_if_peek();
    tac_emit_goto(ctx.end_label);
    tac_emit_label(ctx.else_label);
  }
#line 2808 "parser.tab.c"
    break;

  case 88: /* if_stmt: IF LPAREN expression RPAREN THEN $@3 executables ELSE $@4 executables ENDIF  */
#line 816 "parser.y"
  {
    SdtIfCtx ctx = sdt_if_pop();
    tac_emit_label(ctx.end_label);
    (yyval.node) = NODE("if_stmt", 9, LEAF("IF"), LEAF("LPAREN"), LEAF("expression"), LEAF("RPAREN"), LEAF("THEN"), (yyvsp[-4].node), LEAF("ELSE"), (yyvsp[-1].node), LEAF("ENDIF"));
  }
#line 2818 "parser.tab.c"
    break;

  case 89: /* $@5: %empty  */
#line 824 "parser.y"
  {
    SdtForCtx ctx = sdt_for_push((yyvsp[-5].text), (yyvsp[0].tac) ? (yyvsp[0].tac)->place : NULL);
    if ((yyvsp[-3].tac)) {
      tac_emit_assign((yyvsp[-5].text), (yyvsp[-3].tac)->place);
    }
    tac_emit_label(ctx.start_label);
    {
      char *cmp = tac_new_temp();
      tac_emit_binary(cmp, (yyvsp[-5].text), "<=", (yyvsp[-1].tac) ? (yyvsp[-1].tac)->place : "0");
      tac_emit_if_false_goto(cmp, ctx.end_label);
    }
  }
#line 2835 "parser.tab.c"
    break;

  case 90: /* do_stmt: DO IDENTIFIER ASSIGN expression COMMA expression step_opt $@5 executables END DO  */
#line 837 "parser.y"
    {
    SdtForCtx ctx = sdt_for_pop();
    const char *step = (ctx.step_value && ctx.step_value[0] != '\0') ? ctx.step_value : "1";
    char *next = tac_new_temp();
    tac_emit_binary(next, ctx.var_name, "+", step);
    tac_emit_assign(ctx.var_name, next);
    tac_emit_goto(ctx.start_label);
    tac_emit_label(ctx.end_label);
    (yyval.node) = NODE("do_stmt", 10, LEAF("DO"), LEAF("IDENTIFIER"), LEAF("ASSIGN"), LEAF("expression"), LEAF("COMMA"), LEAF("expression"), LEAF("step_opt"), (yyvsp[-2].node), LEAF("END"), LEAF("DO"));
    }
#line 2850 "parser.tab.c"
    break;

  case 91: /* $@6: %empty  */
#line 850 "parser.y"
  {
    SdtLoopCtx ctx = sdt_loop_push();
    tac_emit_label(ctx.start_label);
  }
#line 2859 "parser.tab.c"
    break;

  case 92: /* $@7: %empty  */
#line 855 "parser.y"
  {
    SdtLoopCtx ctx = sdt_loop_peek();
    if ((yyvsp[-1].tac)) {
      tac_emit_if_false_goto((yyvsp[-1].tac)->place, ctx.end_label);
    }
  }
#line 2870 "parser.tab.c"
    break;

  case 93: /* dowhile_stmt: DO WHILE LPAREN $@6 expression RPAREN $@7 executables END DO  */
#line 862 "parser.y"
  {
    SdtLoopCtx ctx = sdt_loop_pop();
    tac_emit_goto(ctx.start_label);
    tac_emit_label(ctx.end_label);
    (yyval.node) = NODE("dowhile_stmt", 8, LEAF("DO"), LEAF("WHILE"), LEAF("LPAREN"), LEAF("expression"), LEAF("RPAREN"), (yyvsp[-2].node), LEAF("END"), LEAF("DO"));
  }
#line 2881 "parser.tab.c"
    break;

  case 94: /* $@8: %empty  */
#line 871 "parser.y"
  {
    tac_emit_raw("select %s", (yyvsp[-1].tac) ? (yyvsp[-1].tac)->place : "");
  }
#line 2889 "parser.tab.c"
    break;

  case 95: /* select_stmt: SELECT CASE LPAREN expression RPAREN $@8 case_blocks END SELECT  */
#line 875 "parser.y"
  {
    tac_emit_raw("end_select");
    (yyval.node) = NODE("select_stmt", 8, LEAF("SELECT"), LEAF("CASE"), LEAF("LPAREN"), LEAF("expression"), LEAF("RPAREN"), (yyvsp[-2].node), LEAF("END"), LEAF("SELECT"));
  }
#line 2898 "parser.tab.c"
    break;

  case 96: /* $@9: %empty  */
#line 882 "parser.y"
  {
    tac_emit_raw("select_rank %s", (yyvsp[-1].text) ? (yyvsp[-1].text) : "");
  }
#line 2906 "parser.tab.c"
    break;

  case 97: /* select_rank_stmt: SELECT RANK LPAREN identifier RPAREN $@9 rank_blocks END SELECT  */
#line 886 "parser.y"
  {
    tac_emit_raw("end_select_rank");
    (yyval.node) = NODE("select_rank_stmt", 8, LEAF("SELECT"), LEAF("RANK"), LEAF("LPAREN"), LEAF("IDENTIFIER"), LEAF("RPAREN"), (yyvsp[-2].node), LEAF("END"), LEAF("SELECT"));
  }
#line 2915 "parser.tab.c"
    break;

  case 98: /* rank_blocks: rank_block  */
#line 893 "parser.y"
    {
        (yyval.node) = NODE("rank_blocks", 1, (yyvsp[0].node));
    }
#line 2923 "parser.tab.c"
    break;

  case 99: /* rank_blocks: rank_blocks rank_block  */
#line 897 "parser.y"
    {
        (yyval.node) = NODE("rank_blocks", 2, (yyvsp[-1].node), (yyvsp[0].node));
    }
#line 2931 "parser.tab.c"
    break;

  case 100: /* $@10: %empty  */
#line 903 "parser.y"
    {
        tac_emit_raw("rank_case");
    }
#line 2939 "parser.tab.c"
    break;

  case 101: /* rank_block: RANK LPAREN rank_selector RPAREN $@10 executables  */
#line 907 "parser.y"
    {
        (yyval.node) = NODE("rank_block", 5, LEAF("RANK"), LEAF("LPAREN"), (yyvsp[-3].node), LEAF("RPAREN"), (yyvsp[0].node));
    }
#line 2947 "parser.tab.c"
    break;

  case 102: /* $@11: %empty  */
#line 911 "parser.y"
    {
        tac_emit_raw("rank_default");
    }
#line 2955 "parser.tab.c"
    break;

  case 103: /* rank_block: RANK DEFAULT $@11 executables  */
#line 915 "parser.y"
    {
        (yyval.node) = NODE("rank_block", 3, LEAF("RANK"), LEAF("DEFAULT"), (yyvsp[0].node));
    }
#line 2963 "parser.tab.c"
    break;

  case 104: /* rank_selector: INT_CONST  */
#line 921 "parser.y"
    {
        (yyval.node) = NODE("rank_selector", 1, LEAF("INT_CONST"));
    }
#line 2971 "parser.tab.c"
    break;

  case 105: /* rank_selector: MUL_OP  */
#line 925 "parser.y"
    {
        (yyval.node) = NODE("rank_selector", 1, LEAF("MUL_OP"));
    }
#line 2979 "parser.tab.c"
    break;

  case 106: /* case_blocks: case_block  */
#line 931 "parser.y"
    {
        (yyval.node) = NODE("case_blocks", 1, (yyvsp[0].node));
    }
#line 2987 "parser.tab.c"
    break;

  case 107: /* case_blocks: case_blocks case_block  */
#line 935 "parser.y"
    {
        (yyval.node) = NODE("case_blocks", 2, (yyvsp[-1].node), (yyvsp[0].node));
    }
#line 2995 "parser.tab.c"
    break;

  case 108: /* $@12: %empty  */
#line 941 "parser.y"
    {
    tac_emit_raw("case %s", (yyvsp[-1].tac) ? (yyvsp[-1].tac)->place : "");
    }
#line 3003 "parser.tab.c"
    break;

  case 109: /* case_block: CASE LPAREN expression RPAREN $@12 executables  */
#line 945 "parser.y"
    {
    (yyval.node) = NODE("case_block", 5, LEAF("CASE"), LEAF("LPAREN"), LEAF("expression"), LEAF("RPAREN"), (yyvsp[0].node));
    }
#line 3011 "parser.tab.c"
    break;

  case 110: /* $@13: %empty  */
#line 949 "parser.y"
    {
        tac_emit_raw("case_default");
    }
#line 3019 "parser.tab.c"
    break;

  case 111: /* case_block: CASE DEFAULT $@13 executables  */
#line 953 "parser.y"
    {
        (yyval.node) = NODE("case_block", 3, LEAF("CASE"), LEAF("DEFAULT"), (yyvsp[0].node));
    }
#line 3027 "parser.tab.c"
    break;

  case 112: /* call_stmt: CALL callable_name LPAREN argument_values RPAREN  */
#line 959 "parser.y"
    {
        if ((yyvsp[-1].args)) {
            SdtArgNode *arg = (yyvsp[-1].args)->head;
            while (arg) {
                tac_emit_raw("param %s", arg->place ? arg->place : "");
                arg = arg->next;
            }
            tac_emit_raw("call %s, %d", (yyvsp[-3].text) ? (yyvsp[-3].text) : "", (yyvsp[-1].args)->count);
        } else {
            tac_emit_raw("call %s, 0", (yyvsp[-3].text) ? (yyvsp[-3].text) : "");
        }
        (yyval.node) = NODE("call_stmt", 5, LEAF("CALL"), LEAF("callable_name"), LEAF("LPAREN"), LEAF("argument_values"), LEAF("RPAREN"));
    }
#line 3045 "parser.tab.c"
    break;

  case 113: /* callable_name: identifier  */
#line 975 "parser.y"
    {
    (yyval.text) = (yyvsp[0].text);
    }
#line 3053 "parser.tab.c"
    break;

  case 114: /* callable_name: INTRINSIC  */
#line 979 "parser.y"
    {
        (yyval.text) = (yyvsp[0].text);
    }
#line 3061 "parser.tab.c"
    break;

  case 115: /* return_stmt: RETURN  */
#line 985 "parser.y"
    {
        tac_emit_raw("return");
        (yyval.node) = NODE("return_stmt", 1, LEAF("RETURN"));
    }
#line 3070 "parser.tab.c"
    break;

  case 116: /* stop_stmt: STOP  */
#line 992 "parser.y"
    {
        tac_emit_raw("stop");
        (yyval.node) = NODE("stop_stmt", 1, LEAF("STOP"));
    }
#line 3079 "parser.tab.c"
    break;

  case 117: /* stop_stmt: STOP INT_CONST  */
#line 997 "parser.y"
    {
        tac_emit_raw("stop %s", (yyvsp[0].text) ? (yyvsp[0].text) : "");
        (yyval.node) = NODE("stop_stmt", 2, LEAF("STOP"), LEAF("INT_CONST"));
    }
#line 3088 "parser.tab.c"
    break;

  case 118: /* stop_stmt: STOP STRING  */
#line 1002 "parser.y"
    {
        tac_emit_raw("stop %s", (yyvsp[0].text) ? (yyvsp[0].text) : "");
        (yyval.node) = NODE("stop_stmt", 2, LEAF("STOP"), LEAF("STRING"));
    }
#line 3097 "parser.tab.c"
    break;

  case 119: /* pointer_stmt: variable_ref PTR_ASSIGN variable_ref  */
#line 1009 "parser.y"
    {
    if ((yyvsp[-2].tac) && (yyvsp[0].tac)) {
      tac_emit_raw("%s => %s", (yyvsp[-2].tac)->place, (yyvsp[0].tac)->place);
    }
    (yyval.node) = NODE("pointer_stmt", 3, LEAF("variable_ref"), LEAF("PTR_ASSIGN"), LEAF("variable_ref"));
    }
#line 3108 "parser.tab.c"
    break;

  case 120: /* step_opt: %empty  */
#line 1018 "parser.y"
  {
    (yyval.tac) = tac_make_value(strdup("1"));
  }
#line 3116 "parser.tab.c"
    break;

  case 121: /* step_opt: COMMA expression  */
#line 1022 "parser.y"
    {
        (yyval.tac) = (yyvsp[0].tac);
    }
#line 3124 "parser.tab.c"
    break;

  case 122: /* print_stmt: PRINT MUL_OP COMMA print_args  */
#line 1028 "parser.y"
    {
        if ((yyvsp[0].args)) {
            SdtArgNode *arg = (yyvsp[0].args)->head;
            while (arg) {
                tac_emit_raw("print %s", arg->place ? arg->place : "");
                arg = arg->next;
            }
        }
    (yyval.node) = NODE("print_stmt", 4, LEAF("PRINT"), LEAF("MUL_OP"), LEAF("COMMA"), LEAF("print_args"));
    }
#line 3139 "parser.tab.c"
    break;

  case 123: /* print_args: expression  */
#line 1041 "parser.y"
    {
    (yyval.args) = sdt_arg_list_prepend((yyvsp[0].tac) ? (yyvsp[0].tac)->place : "", sdt_arg_list_empty());
    }
#line 3147 "parser.tab.c"
    break;

  case 124: /* print_args: print_args COMMA expression  */
#line 1045 "parser.y"
    {
    (yyval.args) = sdt_arg_list_append((yyvsp[-2].args), (yyvsp[0].tac) ? (yyvsp[0].tac)->place : "");
    }
#line 3155 "parser.tab.c"
    break;

  case 125: /* allocate_stmt: ALLOCATE LPAREN argument_values RPAREN  */
#line 1051 "parser.y"
    {
        if ((yyvsp[-1].args)) {
            SdtArgNode *arg = (yyvsp[-1].args)->head;
            while (arg) {
                tac_emit_raw("allocate %s", arg->place ? arg->place : "");
                arg = arg->next;
            }
        }
        (yyval.node) = NODE("allocate_stmt", 4, LEAF("ALLOCATE"), LEAF("LPAREN"), LEAF("argument_values"), LEAF("RPAREN"));
    }
#line 3170 "parser.tab.c"
    break;

  case 126: /* deallocate_stmt: DEALLOCATE LPAREN argument_values RPAREN  */
#line 1064 "parser.y"
    {
        if ((yyvsp[-1].args)) {
            SdtArgNode *arg = (yyvsp[-1].args)->head;
            while (arg) {
                tac_emit_raw("deallocate %s", arg->place ? arg->place : "");
                arg = arg->next;
            }
        }
        (yyval.node) = NODE("deallocate_stmt", 4, LEAF("DEALLOCATE"), LEAF("LPAREN"), LEAF("argument_values"), LEAF("RPAREN"));
    }
#line 3185 "parser.tab.c"
    break;

  case 127: /* expression: expression ADD_OP expression  */
#line 1077 "parser.y"
    {
    char *op = (yyvsp[-1].text);
    char *temp = tac_new_temp();
    if ((yyvsp[-2].tac) && (yyvsp[0].tac)) {
      tac_emit_binary(temp, (yyvsp[-2].tac)->place, op, (yyvsp[0].tac)->place);
    }
    (yyval.tac) = tac_make_value(temp);
    free(op);
    }
#line 3199 "parser.tab.c"
    break;

  case 128: /* expression: expression MUL_OP expression  */
#line 1087 "parser.y"
    {
    char *op = (yyvsp[-1].text);
    char *temp = tac_new_temp();
    if ((yyvsp[-2].tac) && (yyvsp[0].tac)) {
      tac_emit_binary(temp, (yyvsp[-2].tac)->place, op, (yyvsp[0].tac)->place);
    }
    (yyval.tac) = tac_make_value(temp);
    free(op);
    }
#line 3213 "parser.tab.c"
    break;

  case 129: /* expression: expression EXPONENT expression  */
#line 1097 "parser.y"
    {
    char *op = (yyvsp[-1].text);
    char *temp = tac_new_temp();
    if ((yyvsp[-2].tac) && (yyvsp[0].tac)) {
      tac_emit_binary(temp, (yyvsp[-2].tac)->place, op, (yyvsp[0].tac)->place);
    }
    (yyval.tac) = tac_make_value(temp);
    free(op);
    }
#line 3227 "parser.tab.c"
    break;

  case 130: /* expression: expression REL_OP expression  */
#line 1107 "parser.y"
    {
    char *op = (yyvsp[-1].text);
    char *temp = tac_new_temp();
    if ((yyvsp[-2].tac) && (yyvsp[0].tac)) {
      tac_emit_binary(temp, (yyvsp[-2].tac)->place, op, (yyvsp[0].tac)->place);
    }
    (yyval.tac) = tac_make_value(temp);
    free(op);
    }
#line 3241 "parser.tab.c"
    break;

  case 131: /* expression: expression LOGICAL_OP expression  */
#line 1117 "parser.y"
    {
    char *op = (yyvsp[-1].text);
    char *temp = tac_new_temp();
    if ((yyvsp[-2].tac) && (yyvsp[0].tac)) {
      tac_emit_binary(temp, (yyvsp[-2].tac)->place, op, (yyvsp[0].tac)->place);
    }
    (yyval.tac) = tac_make_value(temp);
    free(op);
    }
#line 3255 "parser.tab.c"
    break;

  case 132: /* expression: factor  */
#line 1127 "parser.y"
    {
    (yyval.tac) = (yyvsp[0].tac);
    }
#line 3263 "parser.tab.c"
    break;

  case 133: /* expression: ADD_OP expression  */
#line 1131 "parser.y"
    {
    char *op = (yyvsp[-1].text);
    char *temp = tac_new_temp();
    if ((yyvsp[0].tac)) {
      tac_emit_unary(temp, op, (yyvsp[0].tac)->place);
    }
    (yyval.tac) = tac_make_value(temp);
    free(op);
    }
#line 3277 "parser.tab.c"
    break;

  case 134: /* expression: LOGICAL_OP expression  */
#line 1141 "parser.y"
    {
    char *op = (yyvsp[-1].text);
    char *temp = tac_new_temp();
    if ((yyvsp[0].tac)) {
      tac_emit_unary(temp, op, (yyvsp[0].tac)->place);
    }
    (yyval.tac) = tac_make_value(temp);
    free(op);
    }
#line 3291 "parser.tab.c"
    break;

  case 135: /* factor: primary  */
#line 1153 "parser.y"
    {
    (yyval.tac) = (yyvsp[0].tac);
    }
#line 3299 "parser.tab.c"
    break;

  case 136: /* primary: INT_CONST  */
#line 1159 "parser.y"
    {
        (yyval.tac) = tac_make_value((yyvsp[0].text));
    }
#line 3307 "parser.tab.c"
    break;

  case 137: /* primary: REAL_CONST  */
#line 1163 "parser.y"
    {
        (yyval.tac) = tac_make_value((yyvsp[0].text));
    }
#line 3315 "parser.tab.c"
    break;

  case 138: /* primary: LOGICAL_CONST  */
#line 1167 "parser.y"
    {
        (yyval.tac) = tac_make_value((yyvsp[0].text));
    }
#line 3323 "parser.tab.c"
    break;

  case 139: /* primary: STRING  */
#line 1171 "parser.y"
    {
        (yyval.tac) = tac_make_value((yyvsp[0].text));
    }
#line 3331 "parser.tab.c"
    break;

  case 140: /* primary: complex_literal  */
#line 1175 "parser.y"
    {
        (yyval.tac) = (yyvsp[0].tac);
    }
#line 3339 "parser.tab.c"
    break;

  case 141: /* primary: LPAREN expression RPAREN  */
#line 1179 "parser.y"
    {
        (yyval.tac) = (yyvsp[-1].tac);
    }
#line 3347 "parser.tab.c"
    break;

  case 142: /* primary: variable_ref primary_suffix_opt  */
#line 1183 "parser.y"
    {
      if ((yyvsp[0].args)) {
        if (sdt_is_array((yyvsp[-1].tac) ? (yyvsp[-1].tac)->place : NULL)) {
          char *indexed = sdt_format_index((yyvsp[-1].tac) ? (yyvsp[-1].tac)->place : NULL, (yyvsp[0].args));
          (yyval.tac) = tac_make_value(indexed);
        } else {
          int argc = 0;
          SdtArgNode *arg = (yyvsp[0].args)->head;
          while (arg) {
            tac_emit_raw("param %s", arg->place ? arg->place : "");
            arg = arg->next;
          }
          argc = (yyvsp[0].args)->count;
          char *temp = tac_new_temp();
          tac_emit_raw("%s = call %s, %d", temp, (yyvsp[-1].tac) ? (yyvsp[-1].tac)->place : "", argc);
          (yyval.tac) = tac_make_value(temp);
        }
      } else {
        (yyval.tac) = (yyvsp[-1].tac);
      }
    }
#line 3373 "parser.tab.c"
    break;

  case 143: /* complex_literal: LPAREN expression COMMA expression RPAREN  */
#line 1207 "parser.y"
  {
  char *text = sdt_format_complex((yyvsp[-3].tac) ? (yyvsp[-3].tac)->place : NULL, (yyvsp[-1].tac) ? (yyvsp[-1].tac)->place : NULL);
  (yyval.tac) = tac_make_value(text);
  }
#line 3382 "parser.tab.c"
    break;

  case 144: /* primary_suffix_opt: %empty  */
#line 1214 "parser.y"
  {
    (yyval.args) = NULL;
  }
#line 3390 "parser.tab.c"
    break;

  case 145: /* primary_suffix_opt: LPAREN argument_values RPAREN  */
#line 1218 "parser.y"
    {
        (yyval.args) = (yyvsp[-1].args);
    }
#line 3398 "parser.tab.c"
    break;

  case 146: /* variable_ref: identifier  */
#line 1224 "parser.y"
    {
    (yyval.tac) = tac_make_value((yyvsp[0].text));
    }
#line 3406 "parser.tab.c"
    break;

  case 147: /* variable_ref: variable_ref DERIVED_TYPE_COMPONENT identifier  */
#line 1228 "parser.y"
    {
    char *combined = sdt_append_derived((yyvsp[-2].tac) ? (yyvsp[-2].tac)->place : NULL, (yyvsp[0].text));
    (yyval.tac) = tac_make_value(combined);
    }
#line 3415 "parser.tab.c"
    break;

  case 148: /* subprogram_list: %empty  */
#line 1235 "parser.y"
  {
    (yyval.node) = NODE0("subprogram_list");
  }
#line 3423 "parser.tab.c"
    break;

  case 149: /* subprogram_list: subprogram_list subprogram  */
#line 1239 "parser.y"
    {
        (yyval.node) = NODE("subprogram_list", 2, (yyvsp[-1].node), (yyvsp[0].node));
    }
#line 3431 "parser.tab.c"
    break;

  case 150: /* subprogram: SUBROUTINE identifier LPAREN identifier_list_opt RPAREN program_body END SUBROUTINE  */
#line 1245 "parser.y"
    {
        (yyval.node) = NODE("subprogram", 8, LEAF("SUBROUTINE"), LEAF("IDENTIFIER"), LEAF("LPAREN"), (yyvsp[-4].node), LEAF("RPAREN"), (yyvsp[-2].node), LEAF("END"), LEAF("SUBROUTINE"));
    }
#line 3439 "parser.tab.c"
    break;

  case 151: /* subprogram: SUBROUTINE identifier LPAREN identifier_list_opt RPAREN program_body END SUBROUTINE identifier  */
#line 1249 "parser.y"
    {
        (yyval.node) = NODE("subprogram", 9, LEAF("SUBROUTINE"), LEAF("IDENTIFIER"), LEAF("LPAREN"), (yyvsp[-5].node), LEAF("RPAREN"), (yyvsp[-3].node), LEAF("END"), LEAF("SUBROUTINE"), LEAF("IDENTIFIER"));
    }
#line 3447 "parser.tab.c"
    break;

  case 152: /* subprogram: FUNCTION identifier LPAREN identifier_list_opt RPAREN program_body END FUNCTION  */
#line 1253 "parser.y"
    {
        (yyval.node) = NODE("subprogram", 8, LEAF("FUNCTION"), LEAF("IDENTIFIER"), LEAF("LPAREN"), (yyvsp[-4].node), LEAF("RPAREN"), (yyvsp[-2].node), LEAF("END"), LEAF("FUNCTION"));
    }
#line 3455 "parser.tab.c"
    break;

  case 153: /* subprogram: FUNCTION identifier LPAREN identifier_list_opt RPAREN program_body END FUNCTION identifier  */
#line 1257 "parser.y"
    {
        (yyval.node) = NODE("subprogram", 9, LEAF("FUNCTION"), LEAF("IDENTIFIER"), LEAF("LPAREN"), (yyvsp[-5].node), LEAF("RPAREN"), (yyvsp[-3].node), LEAF("END"), LEAF("FUNCTION"), LEAF("IDENTIFIER"));
    }
#line 3463 "parser.tab.c"
    break;

  case 154: /* subprogram: RECURSIVE FUNCTION identifier LPAREN identifier_list_opt RPAREN RESULT LPAREN identifier RPAREN program_body END FUNCTION  */
#line 1261 "parser.y"
    {
        (yyval.node) = NODE("subprogram", 13, LEAF("RECURSIVE"), LEAF("FUNCTION"), LEAF("IDENTIFIER"), LEAF("LPAREN"), (yyvsp[-8].node), LEAF("RPAREN"), LEAF("RESULT"), LEAF("LPAREN"), LEAF("IDENTIFIER"), LEAF("RPAREN"), (yyvsp[-2].node), LEAF("END"), LEAF("FUNCTION"));
    }
#line 3471 "parser.tab.c"
    break;

  case 155: /* subprogram: RECURSIVE FUNCTION identifier LPAREN identifier_list_opt RPAREN RESULT LPAREN identifier RPAREN program_body END FUNCTION identifier  */
#line 1265 "parser.y"
    {
        (yyval.node) = NODE("subprogram", 14, LEAF("RECURSIVE"), LEAF("FUNCTION"), LEAF("IDENTIFIER"), LEAF("LPAREN"), (yyvsp[-9].node), LEAF("RPAREN"), LEAF("RESULT"), LEAF("LPAREN"), LEAF("IDENTIFIER"), LEAF("RPAREN"), (yyvsp[-3].node), LEAF("END"), LEAF("FUNCTION"), LEAF("IDENTIFIER"));
    }
#line 3479 "parser.tab.c"
    break;

  case 156: /* argument_values: %empty  */
#line 1271 "parser.y"
  {
    (yyval.args) = sdt_arg_list_empty();
  }
#line 3487 "parser.tab.c"
    break;

  case 157: /* argument_values: expression  */
#line 1275 "parser.y"
    {
      (yyval.args) = sdt_arg_list_prepend((yyvsp[0].tac) ? (yyvsp[0].tac)->place : "", sdt_arg_list_empty());
    }
#line 3495 "parser.tab.c"
    break;

  case 158: /* argument_values: expression COMMA argument_values  */
#line 1279 "parser.y"
    {
      (yyval.args) = sdt_arg_list_prepend((yyvsp[-2].tac) ? (yyvsp[-2].tac)->place : "", (yyvsp[0].args));
    }
#line 3503 "parser.tab.c"
    break;

  case 159: /* identifier_list_opt: %empty  */
#line 1285 "parser.y"
  {
    (yyval.node) = NODE0("identifier_list_opt");
  }
#line 3511 "parser.tab.c"
    break;

  case 160: /* identifier_list_opt: identifier_list  */
#line 1289 "parser.y"
    {
        (yyval.node) = NODE("identifier_list_opt", 1, (yyvsp[0].node));
    }
#line 3519 "parser.tab.c"
    break;

  case 161: /* identifier: IDENTIFIER  */
#line 1295 "parser.y"
    {
        (yyval.text) = (yyvsp[0].text);
    }
#line 3527 "parser.tab.c"
    break;

  case 162: /* identifier: RESULT  */
#line 1299 "parser.y"
    {
        (yyval.text) = strdup("result");
    }
#line 3535 "parser.tab.c"
    break;

  case 163: /* type_def: TYPE DECL_SEP identifier type_def_body END_TYPE identifier  */
#line 1305 "parser.y"
    {
    (yyval.node) = NODE("type_def", 6, LEAF("TYPE"), LEAF("DECL_SEP"), LEAF("IDENTIFIER"), (yyvsp[-2].node), LEAF("END_TYPE"), LEAF("IDENTIFIER"));
    }
#line 3543 "parser.tab.c"
    break;

  case 164: /* type_def_body: %empty  */
#line 1311 "parser.y"
  {
    (yyval.node) = NODE0("type_def_body");
  }
#line 3551 "parser.tab.c"
    break;

  case 165: /* type_def_body: type_def_declarations  */
#line 1315 "parser.y"
    {
        (yyval.node) = NODE("type_def_body", 1, (yyvsp[0].node));
    }
#line 3559 "parser.tab.c"
    break;

  case 166: /* type_def_declarations: type_def_declaration  */
#line 1321 "parser.y"
    {
        (yyval.node) = NODE("type_def_declarations", 1, (yyvsp[0].node));
    }
#line 3567 "parser.tab.c"
    break;

  case 167: /* type_def_declarations: type_def_declarations type_def_declaration  */
#line 1325 "parser.y"
    {
        (yyval.node) = NODE("type_def_declarations", 2, (yyvsp[-1].node), (yyvsp[0].node));
    }
#line 3575 "parser.tab.c"
    break;

  case 168: /* type_def_declaration: type_spec declaration_attributes DECL_SEP declarator_list  */
#line 1331 "parser.y"
    {
        (yyval.node) = NODE("type_def_declaration", 4, (yyvsp[-3].node), (yyvsp[-2].node), LEAF("DECL_SEP"), (yyvsp[0].node));
    }
#line 3583 "parser.tab.c"
    break;

  case 169: /* pp_define_undef: PP_DEFINE identifier  */
#line 1337 "parser.y"
    {
        (yyval.node) = NODE("pp_define_undef", 2, LEAF("PP_DEFINE"), LEAF("IDENTIFIER"));
    }
#line 3591 "parser.tab.c"
    break;

  case 170: /* pp_define_undef: PP_DEFINE identifier INT_CONST  */
#line 1341 "parser.y"
    {
        (yyval.node) = NODE("pp_define_undef", 3, LEAF("PP_DEFINE"), LEAF("IDENTIFIER"), LEAF("INT_CONST"));
    }
#line 3599 "parser.tab.c"
    break;

  case 171: /* pp_define_undef: PP_UNDEF identifier  */
#line 1345 "parser.y"
    {
        (yyval.node) = NODE("pp_define_undef", 2, LEAF("PP_UNDEF"), LEAF("IDENTIFIER"));
    }
#line 3607 "parser.tab.c"
    break;

  case 172: /* pp_if_block: PP_IFDEF identifier declarations pp_else_opt PP_ENDIF  */
#line 1351 "parser.y"
    {
        (yyval.node) = NODE("pp_if_block", 5, LEAF("PP_IFDEF"), LEAF("IDENTIFIER"), (yyvsp[-2].node), (yyvsp[-1].node), LEAF("PP_ENDIF"));
    }
#line 3615 "parser.tab.c"
    break;

  case 173: /* pp_if_block: PP_IFNDEF identifier declarations pp_else_opt PP_ENDIF  */
#line 1355 "parser.y"
    {
        (yyval.node) = NODE("pp_if_block", 5, LEAF("PP_IFNDEF"), LEAF("IDENTIFIER"), (yyvsp[-2].node), (yyvsp[-1].node), LEAF("PP_ENDIF"));
    }
#line 3623 "parser.tab.c"
    break;

  case 174: /* pp_if_block: PP_IF identifier declarations pp_else_opt PP_ENDIF  */
#line 1359 "parser.y"
    {
        (yyval.node) = NODE("pp_if_block", 5, LEAF("PP_IF"), LEAF("IDENTIFIER"), (yyvsp[-2].node), (yyvsp[-1].node), LEAF("PP_ENDIF"));
    }
#line 3631 "parser.tab.c"
    break;

  case 175: /* pp_if_block: PP_IF INT_CONST declarations pp_else_opt PP_ENDIF  */
#line 1363 "parser.y"
    {
        (yyval.node) = NODE("pp_if_block", 5, LEAF("PP_IF"), LEAF("INT_CONST"), (yyvsp[-2].node), (yyvsp[-1].node), LEAF("PP_ENDIF"));
    }
#line 3639 "parser.tab.c"
    break;

  case 176: /* pp_else_opt: %empty  */
#line 1369 "parser.y"
  {
    (yyval.node) = NODE0("pp_else_opt");
  }
#line 3647 "parser.tab.c"
    break;

  case 177: /* pp_else_opt: PP_ELSE declarations  */
#line 1373 "parser.y"
    {
        (yyval.node) = NODE("pp_else_opt", 2, LEAF("PP_ELSE"), (yyvsp[0].node));
    }
#line 3655 "parser.tab.c"
    break;


#line 3659 "parser.tab.c"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      {
        yypcontext_t yyctx
          = {yyssp, yytoken};
        char const *yymsgp = YY_("syntax error");
        int yysyntax_error_status;
        yysyntax_error_status = yysyntax_error (&yymsg_alloc, &yymsg, &yyctx);
        if (yysyntax_error_status == 0)
          yymsgp = yymsg;
        else if (yysyntax_error_status == -1)
          {
            if (yymsg != yymsgbuf)
              YYSTACK_FREE (yymsg);
            yymsg = YY_CAST (char *,
                             YYSTACK_ALLOC (YY_CAST (YYSIZE_T, yymsg_alloc)));
            if (yymsg)
              {
                yysyntax_error_status
                  = yysyntax_error (&yymsg_alloc, &yymsg, &yyctx);
                yymsgp = yymsg;
              }
            else
              {
                yymsg = yymsgbuf;
                yymsg_alloc = sizeof yymsgbuf;
                yysyntax_error_status = YYENOMEM;
              }
          }
        yyerror (yymsgp);
        if (yysyntax_error_status == YYENOMEM)
          YYNOMEM;
      }
    }

  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;


      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
  return yyresult;
}

#line 1378 "parser.y"


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
        printf("Parsing done!\n");
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
