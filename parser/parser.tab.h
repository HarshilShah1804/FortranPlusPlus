/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

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

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_PARSER_TAB_H_INCLUDED
# define YY_YY_PARSER_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif
/* "%code requires" blocks.  */
#line 331 "parser.y"

#include "../ir/tac.h"
typedef struct SdtArgList SdtArgList;

#line 54 "parser.tab.h"

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    PROGRAM = 258,                 /* PROGRAM  */
    MODULE = 259,                  /* MODULE  */
    END = 260,                     /* END  */
    CONTAINS = 261,                /* CONTAINS  */
    USE = 262,                     /* USE  */
    NONE = 263,                    /* NONE  */
    IMPLICIT = 264,                /* IMPLICIT  */
    INTEGER = 265,                 /* INTEGER  */
    REAL = 266,                    /* REAL  */
    LOGICAL = 267,                 /* LOGICAL  */
    CHARACTER = 268,               /* CHARACTER  */
    TYPE = 269,                    /* TYPE  */
    CLASS = 270,                   /* CLASS  */
    END_TYPE = 271,                /* END_TYPE  */
    COMPLEX = 272,                 /* COMPLEX  */
    IF = 273,                      /* IF  */
    THEN = 274,                    /* THEN  */
    ELSE = 275,                    /* ELSE  */
    DO = 276,                      /* DO  */
    ENDIF = 277,                   /* ENDIF  */
    LEN = 278,                     /* LEN  */
    WHILE = 279,                   /* WHILE  */
    SELECT = 280,                  /* SELECT  */
    CASE = 281,                    /* CASE  */
    DEFAULT = 282,                 /* DEFAULT  */
    RANK = 283,                    /* RANK  */
    STOP = 284,                    /* STOP  */
    PRINT = 285,                   /* PRINT  */
    CALL = 286,                    /* CALL  */
    SUBROUTINE = 287,              /* SUBROUTINE  */
    FUNCTION = 288,                /* FUNCTION  */
    RETURN = 289,                  /* RETURN  */
    RECURSIVE = 290,               /* RECURSIVE  */
    RESULT = 291,                  /* RESULT  */
    ALLOCATE = 292,                /* ALLOCATE  */
    DEALLOCATE = 293,              /* DEALLOCATE  */
    ALLOCATED = 294,               /* ALLOCATED  */
    POINTER = 295,                 /* POINTER  */
    TARGET = 296,                  /* TARGET  */
    ALLOCATABLE = 297,             /* ALLOCATABLE  */
    INTENT = 298,                  /* INTENT  */
    IN = 299,                      /* IN  */
    OUT = 300,                     /* OUT  */
    INOUT = 301,                   /* INOUT  */
    OPEN = 302,                    /* OPEN  */
    CLOSE = 303,                   /* CLOSE  */
    INQUIRE = 304,                 /* INQUIRE  */
    WRITE = 305,                   /* WRITE  */
    READ = 306,                    /* READ  */
    ERROR = 307,                   /* ERROR  */
    LPAREN = 308,                  /* LPAREN  */
    RPAREN = 309,                  /* RPAREN  */
    COMMA = 310,                   /* COMMA  */
    COLON = 311,                   /* COLON  */
    ASSUMED_RANK_SPECIFIER = 312,  /* ASSUMED_RANK_SPECIFIER  */
    CONCAT = 313,                  /* CONCAT  */
    PTR_ASSIGN = 314,              /* PTR_ASSIGN  */
    PP_DEFINE = 315,               /* PP_DEFINE  */
    PP_UNDEF = 316,                /* PP_UNDEF  */
    PP_IFDEF = 317,                /* PP_IFDEF  */
    PP_IFNDEF = 318,               /* PP_IFNDEF  */
    PP_IF = 319,                   /* PP_IF  */
    PP_ELIF = 320,                 /* PP_ELIF  */
    PP_ELSE = 321,                 /* PP_ELSE  */
    PP_ENDIF = 322,                /* PP_ENDIF  */
    LENGTH_SPECIFIER = 323,        /* LENGTH_SPECIFIER  */
    IDENTIFIER = 324,              /* IDENTIFIER  */
    INT_CONST = 325,               /* INT_CONST  */
    REAL_CONST = 326,              /* REAL_CONST  */
    STRING = 327,                  /* STRING  */
    LOGICAL_CONST = 328,           /* LOGICAL_CONST  */
    INTRINSIC = 329,               /* INTRINSIC  */
    ADD_OP = 330,                  /* ADD_OP  */
    MUL_OP = 331,                  /* MUL_OP  */
    REL_OP = 332,                  /* REL_OP  */
    LOGICAL_OP = 333,              /* LOGICAL_OP  */
    EXPONENT = 334,                /* EXPONENT  */
    ASSIGN = 335,                  /* ASSIGN  */
    DECL_SEP = 336,                /* DECL_SEP  */
    DERIVED_TYPE_COMPONENT = 337,  /* DERIVED_TYPE_COMPONENT  */
    UNARY = 338,                   /* UNARY  */
    LOWER_THAN_ELSE = 339          /* LOWER_THAN_ELSE  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 336 "parser.y"

  struct DerivationNode *node;
  char *text;
  TacValue *tac;
  SdtArgList *args;

#line 162 "parser.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_PARSER_TAB_H_INCLUDED  */
