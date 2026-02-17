%option noyywrap
%option yylineno
%option case-insensitive

%{
#include <stdio.h>
#include <stdlib.h>

void print_token(const char *type) {
    printf("Line %-3d  %-15s  %s\n", yylineno, type, yytext);
}

%}

/* ---------- Definitions ---------- */

LETTER      [A-Za-z]
DIGIT       [0-9]
ID          {LETTER}({LETTER}|{DIGIT}|_)*
INT         {DIGIT}+
REAL        {DIGIT}+\.{DIGIT}*([Ee][+-]?{DIGIT}+)?
STRING      \"[^\"]*\"|\'([^']|\'\')*\'

WS          [ \t\r]+

/* ---------- Rules ---------- */
%%

"!*" {
    int c;
    while ((c = input()) != 0) {
        if (c == '*') {
            if ((c = input()) == '!') break;
            else unput(c);
        }
    }
}

!([^*].*)?   {}

"("{REAL}","[ ]*{REAL}")"  { print_token("COMPLEX_CONST"); }

"program"       { print_token("PROGRAM"); }
"end"           { print_token("END"); }
"integer"       { print_token("INTEGER"); }
"real"          { print_token("REAL"); }
"logical"       { print_token("LOGICAL"); }
"character"     { print_token("CHARACTER"); }
"if"            { print_token("IF"); }
"then"          { print_token("THEN"); }
"else"          { print_token("ELSE"); }
"do"            { print_token("DO"); }
"stop"          { print_token("STOP"); }
"print"         { print_token("PRINT"); }
"call"          { print_token("CALL"); }
"subroutine"    { print_token("SUBROUTINE"); }
"function"      { print_token("FUNCTION"); }
"return"        { print_token("RETURN"); }
"implicit"      { print_token("IMPLICIT"); }
"none"          { print_token("NONE"); }
"module"        { print_token("MODULE"); }
"contains"      { print_token("CONTAINS"); }
"use"           { print_token("USE"); }
"end"{WS}+"type"    { print_token("END_TYPE"); } 
"type"          { print_token("TYPE"); }  
"."("true"|"false"|"t"|"f")"."  { print_token("LOGICAL_CONST"); }

"=="|"/="|"<="|">="|"<"|">"   { print_token("REL_OP"); }
"="                            { print_token("ASSIGN"); }
"+"|"-"|"*"|"/"               { print_token("ARITH_OP"); }
"("                            { print_token("LPAREN"); }
")"                            { print_token("RPAREN"); }
","                            { print_token("COMMA"); }
"::"                           { print_token("DECL_SEP"); }

{REAL}         { print_token("REAL_CONST"); }
{INT}          { print_token("INT_CONST"); }
{STRING}       { print_token("STRING"); }

{ID}           { print_token("IDENTIFIER"); }

{WS}           { /* ignore */ }

\n             { /* yylineno auto-increments */ }

.              { print_token("UNKNOWN"); }

%%

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *fp = fopen(argv[1], "r");
        if (!fp) {
            perror("File open failed");
            return 1;
        }
        yyin = fp;
    }
    yylex();

    return 0;
}
