%option noyywrap
%option yylineno
%option case-insensitive

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../ast/ast.h"
#include "../parser/y.tab.h"

int lexical_errors = 0;
int paren_balance = 0;
int if_balance = 0;

#define MAX_LINE_LENGTH 4096

char current_line[MAX_LINE_LENGTH];
size_t current_line_len = 0;
int column = 1;
int token_column = 1;

static void reset_line(void) {
    current_line_len = 0;
    current_line[0] = '\0';
    column = 1;
}

static void append_text(const char *text, int len) {
    if (!text || len <= 0) {
        return;
    }
    size_t avail = (MAX_LINE_LENGTH - 1) - current_line_len;
    if ((size_t)len > avail) {
        len = (int)avail;
    }
    if (len > 0) {
        memcpy(current_line + current_line_len, text, (size_t)len);
        current_line_len += (size_t)len;
        current_line[current_line_len] = '\0';
    }
    column += len;
}

static void append_text_strip_newline(const char *text, int len) {
    while (len > 0 && (text[len - 1] == '\n' || text[len - 1] == '\r')) {
        len--;
    }
    append_text(text, len);
}

#define SET_TOKEN() do { token_column = column; append_text(yytext, yyleng); } while (0)
#define APPEND_TEXT() do { append_text(yytext, yyleng); } while (0)

%}

/* ---------- Definitions ---------- */
%x BLOCK_COMMENT
LETTER      [A-Za-z]
DIGIT       [0-9]
ID          {LETTER}({LETTER}|{DIGIT}|_)*
INT         {DIGIT}+

EXP     [Ee][+-]?{DIGIT}+
REAL        (({DIGIT}+\.{DIGIT}*|{DIGIT}*\.{DIGIT}+)([EeDd][+-]?{DIGIT}+)?|{DIGIT}+[EeDd][+-]?{DIGIT}+)
STRING      \"([^"]|\"\")*\"|\'([^']|\'\')*\'
WS          [ \t\r]+
PP_ID      [A-Za-z_][A-Za-z0-9_]*
PP_EXPR    [^\n]+

/* ---------- Rules ---------- */
%%

"!*"                    { APPEND_TEXT(); BEGIN(BLOCK_COMMENT); }
<BLOCK_COMMENT>"*!"     { APPEND_TEXT(); BEGIN(INITIAL); }
<BLOCK_COMMENT>\n       { reset_line(); }
<BLOCK_COMMENT>.        { APPEND_TEXT(); }
<BLOCK_COMMENT><<EOF>>  { 
    lexical_errors++;
    printf("[Line %-3d]  ERROR: Unclosed block comment\n", yylineno); 
    exit(1);
}

!([^*].*)?   { APPEND_TEXT(); }

"program"       { SET_TOKEN(); return PROGRAM; }
"end"           { SET_TOKEN(); return END; }
"integer"       { SET_TOKEN(); return INTEGER; }
"real"          { SET_TOKEN(); return REAL; }
"logical"       { SET_TOKEN(); return LOGICAL; }
"character"     { SET_TOKEN(); return CHARACTER; }
"if"            { SET_TOKEN(); if_balance++; return IF; }
"endif" | "end if"         { SET_TOKEN(); if_balance--; return ENDIF; }
"then"          { SET_TOKEN(); return THEN; }
"else"          { SET_TOKEN(); return ELSE; }
"do"            { SET_TOKEN(); return DO; }
"stop"          { SET_TOKEN(); return STOP; }
"print"         { SET_TOKEN(); return PRINT; }
"call"          { SET_TOKEN(); return CALL; }
"subroutine"    { SET_TOKEN(); return SUBROUTINE; }
"function"      { SET_TOKEN(); return FUNCTION; }
"return"        { SET_TOKEN(); return RETURN; }
"implicit"      { SET_TOKEN(); return IMPLICIT; }
"none"          { SET_TOKEN(); return NONE; }
"module"        { SET_TOKEN(); return MODULE; }
"contains"      { SET_TOKEN(); return CONTAINS; }
"use"           { SET_TOKEN(); return USE; }
"end"{WS}+"type"    { SET_TOKEN(); return END_TYPE; } 
"type"          { SET_TOKEN(); return TYPE; }  
"len"        { SET_TOKEN(); return LENGTH_SPECIFIER; }
"."("true"|"false"|"t"|"f")"."  { SET_TOKEN(); return LOGICAL_CONST; }
"random_seed"   { SET_TOKEN(); return INTRINSIC; }
"random_number"   { SET_TOKEN(); return INTRINSIC; }

"recursive"     { SET_TOKEN(); return RECURSIVE; }
"result"        { SET_TOKEN(); return RESULT; }


"while"         { SET_TOKEN(); return WHILE; }
"select"        { SET_TOKEN(); return SELECT; }
"case"          { SET_TOKEN(); return CASE; }
"default"       { SET_TOKEN(); return DEFAULT; }
"rank"          { SET_TOKEN(); return RANK; }

"class"         { SET_TOKEN(); return CLASS; }
"complex"       { SET_TOKEN(); return COMPLEX; }

"allocate"      { SET_TOKEN(); return ALLOCATE; }
"deallocate"    { SET_TOKEN(); return DEALLOCATE; }
"allocated"     { SET_TOKEN(); return ALLOCATED; }
"pointer"       { SET_TOKEN(); return POINTER; }
"target"        { SET_TOKEN(); return TARGET; }
"allocatable"   { SET_TOKEN(); return ALLOCATABLE; }
"intent"        { SET_TOKEN(); return INTENT; }
"inout"         { SET_TOKEN(); return INOUT; }
"in"            { SET_TOKEN(); return IN; }
"out"           { SET_TOKEN(); return OUT; }

"open"          { SET_TOKEN(); return OPEN; }
"close"         { SET_TOKEN(); return CLOSE; }
"inquire"       { SET_TOKEN(); return INQUIRE; }
"write"         { SET_TOKEN(); return WRITE; }
"read"          { SET_TOKEN(); return READ; }
"error"         { SET_TOKEN(); return ERROR; }

"=="|"/="|"<="|">="|"<"|">"   { SET_TOKEN(); return REL_OP; }
"=>"  { SET_TOKEN(); return PTR_ASSIGN; }
"="                            { SET_TOKEN(); return ASSIGN; }
"+"|"-"|"*"|"/"               { SET_TOKEN(); return ARITH_OP; }
"("                            { SET_TOKEN(); paren_balance++; return LPAREN; }
")"                            { SET_TOKEN(); paren_balance--; return RPAREN; }
","                            { SET_TOKEN(); return COMMA; }
"::"                           { SET_TOKEN(); return DECL_SEP; }
":"                            { SET_TOKEN(); return COLON; }
".."                          { SET_TOKEN(); return ASSUMED_RANK_SPECIFIER; }
"**"                           { SET_TOKEN(); return EXPONENT; }
"//"                           { SET_TOKEN(); return CONCAT; }
"%"   { SET_TOKEN(); return DERIVED_TYPE_COMPONENT; }


"#define"      { SET_TOKEN(); return PP_DEFINE; }
"#undef"       { SET_TOKEN(); return PP_UNDEF; }
"#ifdef"       { SET_TOKEN(); return PP_IFDEF; }
"#ifndef"      { SET_TOKEN(); return PP_IFNDEF; }
"#if"          { SET_TOKEN(); return PP_IF; }
"#elif"        { SET_TOKEN(); return PP_ELIF; }
"#else"        { SET_TOKEN(); return PP_ELSE; }
"#endif"       { SET_TOKEN(); return PP_ENDIF; }

"."("and"|"or"|"not")"."  { SET_TOKEN(); return LOGICAL_OP; }


{REAL}         { SET_TOKEN(); return REAL_CONST; }
{INT}          { SET_TOKEN(); return INT_CONST; }
{STRING}       { SET_TOKEN(); return STRING; }

{ID}           { 
    SET_TOKEN();
    if (yyleng > 63) {
        printf("[Line %-3d]  ERROR: Identifier exceeds 63 chars\n", yylineno);
        lexical_errors++;
    } else {
        return IDENTIFIER;
    }
}

{WS}           { APPEND_TEXT(); }

\"([^"\n]|\"\")*\n  { 
    append_text_strip_newline(yytext, yyleng);
    printf("[Line %-3d]  ERROR: Unclosed string literal\n", yylineno - 1); 
    lexical_errors++; 
    reset_line();
}

\'([^'\n]|\'\')*\n  { 
    append_text_strip_newline(yytext, yyleng);
    printf("[Line %-3d]  ERROR: Unclosed string literal\n", yylineno - 1); 
    lexical_errors++; 
    reset_line();
}

"&"[ \t]*\r?\n     { append_text_strip_newline(yytext, yyleng); reset_line(); }
^[ \t]+"&"     { APPEND_TEXT(); }

\n             { reset_line(); }

.              { 
    SET_TOKEN();
    printf("[Line %-3d]  ERROR: Stray character: '%s'\n", yylineno, yytext);
    lexical_errors++;
}

%%
