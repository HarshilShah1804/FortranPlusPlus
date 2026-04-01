%option noyywrap
%option yylineno
%option case-insensitive

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../parser/y.tab.h"

int lexical_errors = 0;

void print_token(const char *type) {
    if (strcmp(type, "INT_CONST") == 0 ||
        strcmp(type, "REAL_CONST") == 0 ||
        strcmp(type, "LOGICAL_CONST") == 0) {

        printf("[Line %-3d]  %-18s  Value: %s\n",
               yylineno,
               type,
               yytext);
    }
    else {
        printf("[Line %-3d]  %-18s  Lexeme: \"%s\"\n",
               yylineno,
               type,
               yytext);
    }
}

%}

/* ---------- Definitions ---------- */
%x BLOCK_COMMENT
LETTER      [A-Za-z]
DIGIT       [0-9]
ID          {LETTER}({LETTER}|{DIGIT}|_)*
INT         {DIGIT}+

EXP     [Ee][+-]?{DIGIT}+
REAL        ({DIGIT}+\.{DIGIT}*|{DIGIT}*\.{DIGIT}+)([EeDd][+-]?{DIGIT}+)?
STRING      \"([^"]|\"\")*\"|\'([^']|\'\')*\'
WS          [ \t\r]+
PP_ID      [A-Za-z_][A-Za-z0-9_]*
PP_EXPR    [^\n]+

/* ---------- Rules ---------- */
%%

"!*"                    { BEGIN(BLOCK_COMMENT); }
<BLOCK_COMMENT>"*!"     { BEGIN(INITIAL); }
<BLOCK_COMMENT>\n       { /* yylineno auto-increments */ }
<BLOCK_COMMENT>.        { /* ignore all other characters inside the comment */ }
<BLOCK_COMMENT><<EOF>>  { 
    lexical_errors++;
    printf("[Line %-3d]  ERROR: Unclosed block comment\n", yylineno); 
    exit(1);
}

!([^*].*)?   {}

"program"       { print_token("PROGRAM"); return PROGRAM; }
"end"           { print_token("END"); return END; }
"integer"       { print_token("INTEGER"); return INTEGER; }
"real"          { print_token("REAL"); return REAL; }
"logical"       { print_token("LOGICAL"); return LOGICAL; }
"character"     { print_token("CHARACTER"); return CHARACTER; }
"if"            { print_token("IF"); return IF; }
"endif"         { print_token("ENDIF"); return ENDIF; }
"then"          { print_token("THEN"); return THEN; }
"else"          { print_token("ELSE"); return ELSE; }
"do"            { print_token("DO"); return DO; }
"stop"          { print_token("STOP"); return STOP; }
"print"         { print_token("PRINT"); return PRINT; }
"call"          { print_token("CALL"); return CALL; }
"subroutine"    { print_token("SUBROUTINE"); return SUBROUTINE; }
"function"      { print_token("FUNCTION"); return FUNCTION; }
"return"        { print_token("RETURN"); return RETURN; }
"implicit"      { print_token("IMPLICIT"); return IMPLICIT; }
"none"          { print_token("NONE"); return NONE; }
"module"        { print_token("MODULE"); return MODULE; }
"contains"      { print_token("CONTAINS"); return CONTAINS; }
"use"           { print_token("USE"); return USE; }
"end"{WS}+"type"    { print_token("END_TYPE"); return END_TYPE; } 
"type"          { print_token("TYPE"); return TYPE; }  
"len"        { print_token("LENGTH_SPECIFIER"); return LENGTH_SPECIFIER; }
"."("true"|"false"|"t"|"f")"."  { print_token("LOGICAL_CONST"); yylval.str = strdup(yytext); return LOGICAL_CONST; }
"random_seed"   {print_token("INTRINSIC"); return INTRINSIC;}
"random_number"   {print_token("INTRINSIC"); return INTRINSIC;}

"recursive"     { print_token("RECURSIVE"); return RECURSIVE; }
"result"        { print_token("RESULT"); return RESULT; }


"while"         { print_token("WHILE"); return WHILE; }
"select"        { print_token("SELECT"); return SELECT; }
"case"          { print_token("CASE"); return CASE; }
"default"       { print_token("DEFAULT"); return DEFAULT; }
"rank"          { print_token("RANK"); return RANK; }

"class"         { print_token("CLASS"); return CLASS; }
"complex"       { print_token("COMPLEX"); return COMPLEX; }

"allocate"      { print_token("ALLOCATE"); return ALLOCATE; }
"deallocate"    { print_token("DEALLOCATE"); return DEALLOCATE; }
"allocated"     { print_token("ALLOCATED"); return ALLOCATED; }
"pointer"       { print_token("POINTER"); return POINTER; }
"target"        { print_token("TARGET"); return TARGET; }
"allocatable"   { print_token("ALLOCATABLE"); return ALLOCATABLE; }
"intent"        { print_token("INTENT"); return INTENT; }
"inout"         { print_token("INOUT"); return INOUT; }
"in"            { print_token("IN"); return IN; }
"out"           { print_token("OUT"); return OUT; }

"open"          { print_token("OPEN"); return OPEN; }
"close"         { print_token("CLOSE"); return CLOSE; }
"inquire"       { print_token("INQUIRE"); return INQUIRE; }
"write"         { print_token("WRITE"); return WRITE; }
"read"          { print_token("READ"); return READ; }
"error"         { print_token("ERROR"); return ERROR; }

"=="|"/="|"<="|">="|"<"|">"   { print_token("REL_OP"); yylval.str = strdup(yytext); return REL_OP; }
"="                            { print_token("ASSIGN"); yylval.str = strdup(yytext); return ASSIGN; }
"+"|"-"|"*"|"/"               { print_token("ARITH_OP"); yylval.str = strdup(yytext); return ARITH_OP; }
"("                            { print_token("LPAREN"); return LPAREN; }
")"                            { print_token("RPAREN"); return RPAREN; }
","                            { print_token("COMMA"); return COMMA; }
"::"                           { print_token("DECL_SEP"); yylval.str = strdup(yytext); return DECL_SEP; }
":"                            { print_token("COLON"); return COLON; }
".."                          { print_token("ASSUMED_RANK_SPECIFIER"); return ASSUMED_RANK_SPECIFIER; }
"**"                           { print_token("EXPONENT"); yylval.str = strdup(yytext); return EXPONENT; }
"//"                           { print_token("CONCAT"); return CONCAT; }
"%"   { print_token("DERIVED_TYPE_COMPONENT"); yylval.str = strdup(yytext); return DERIVED_TYPE_COMPONENT; }


"#define"      { print_token("PP_DEFINE"); return PP_DEFINE; }
"#undef"       { print_token("PP_UNDEF"); return PP_UNDEF; }
"#ifdef"       { print_token("PP_IFDEF"); return PP_IFDEF; }
"#ifndef"      { print_token("PP_IFNDEF"); return PP_IFNDEF; }
"#if"          { print_token("PP_IF"); return PP_IF; }
"#elif"        { print_token("PP_ELIF"); return PP_ELIF; }
"#else"        { print_token("PP_ELSE"); return PP_ELSE; }
"#endif"       { print_token("PP_ENDIF"); return PP_ENDIF; }

"."("and"|"or"|"not")"."  { print_token("LOGICAL_OP"); yylval.str = strdup(yytext); return LOGICAL_OP; }


{REAL}         { print_token("REAL_CONST"); yylval.str = strdup(yytext); return REAL_CONST; }
{INT}          { print_token("INT_CONST"); yylval.str = strdup(yytext); return INT_CONST; }
{STRING}       { print_token("STRING"); yylval.str = strdup(yytext); return STRING; }

{ID}           { 
    if (yyleng > 63) {
        printf("[Line %-3d]  ERROR: Identifier exceeds 63 chars\n", yylineno);
        lexical_errors++;
    } else {
        print_token("IDENTIFIER"); 
        yylval.str = strdup(yytext);
        return IDENTIFIER;
    }
}

{WS}           { /* ignore */ }

\"([^"\n]|\"\")*\n  { 
    printf("[Line %-3d]  ERROR: Unclosed string literal\n", yylineno - 1); 
    lexical_errors++; 
}

\'([^'\n]|\'\')*\n  { 
    printf("[Line %-3d]  ERROR: Unclosed string literal\n", yylineno - 1); 
    lexical_errors++; 
}

"&"[ \t]*\r?\n     { /* line continuation: ignore newline */ }
^[ \t]+"&"     { /* ignore leading continuation */ }

\n             { /* yylineno auto-increments */ }

.              { 
    printf("[Line %-3d]  ERROR: Stray character: '%s'\n", yylineno, yytext);
    lexical_errors++;
}

%%