%option noyywrap
%option yylineno
%option case-insensitive

%{
#include <stdio.h>
#include <stdlib.h>

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
"len"        { print_token("LENGTH_SPECIFIER"); }
"."("true"|"false"|"t"|"f")"."  { print_token("LOGICAL_CONST"); }
"random_seed"   {print_token("INTRINSIC");}
"random_number"   {print_token("INTRINSIC");}

"recursive"     { print_token("RECURSIVE"); }
"result"        { print_token("RESULT"); }


"while"         { print_token("WHILE"); }
"select"        { print_token("SELECT"); }
"case"          { print_token("CASE"); }
"default"       { print_token("DEFAULT"); }
"rank"          { print_token("RANK"); }

"class"         { print_token("CLASS"); }
"complex"       { print_token("COMPLEX"); }

"allocate"      { print_token("ALLOCATE"); }
"deallocate"    { print_token("DEALLOCATE"); }
"allocated"     { print_token("ALLOCATED"); }
"pointer"       { print_token("POINTER"); }
"target"        { print_token("TARGET"); }
"allocatable"   { print_token("ALLOCATABLE"); }
"intent"        { print_token("INTENT"); }
"inout"         { print_token("INOUT"); }
"in"            { print_token("IN"); }
"out"           { print_token("OUT"); }

"open"          { print_token("OPEN"); }
"close"         { print_token("CLOSE"); }
"inquire"       { print_token("INQUIRE"); }
"write"         { print_token("WRITE"); }
"read"          { print_token("READ"); }
"error"         { print_token("ERROR"); }

"=="|"/="|"<="|">="|"<"|">"   { print_token("REL_OP"); }
"=>"                           { print_token("PTR_ASSIGN"); }
"="                            { print_token("ASSIGN"); }
"+"|"-"|"*"|"/"               { print_token("ARITH_OP"); }
"("                            { print_token("LPAREN"); }
")"                            { print_token("RPAREN"); }
","                            { print_token("COMMA"); }
"::"                           { print_token("DECL_SEP"); }
":"                            { print_token("COLON"); }
".."                          { print_token("ASSUMED_RANK_SPECIFIER"); }
"**"                       { print_token("EXPONENT"); }
"//"                       { print_token("CONCAT"); }
"%"                      { print_token("DERIVED_TYPE_COMPONENT"); }


"#define"      { print_token("PP_DEFINE"); }
"#undef"       { print_token("PP_UNDEF"); }
"#ifdef"       { print_token("PP_IFDEF"); }
"#ifndef"      { print_token("PP_IFNDEF"); }
"#if"          { print_token("PP_IF"); }
"#elif"        { print_token("PP_ELIF"); }
"#else"        { print_token("PP_ELSE"); }
"#endif"       { print_token("PP_ENDIF"); }

"."("and"|"or"|"not")"."  { print_token("LOGICAL_OP"); }


{REAL}         { print_token("REAL_CONST"); }
{INT}          { print_token("INT_CONST"); }
{STRING}       { print_token("STRING"); }

{ID}           { 
    if (yyleng > 63) {
        printf("[Line %-3d]  ERROR: Identifier exceeds 63 chars\n", yylineno);
        lexical_errors++;
    } else {
        print_token("IDENTIFIER"); 
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
^[ \t]*"&"     { /* ignore leading continuation */ }

\n             { /* yylineno auto-increments */ }

.              { 
    printf("[Line %-3d]  ERROR: Stray character: '%s'\n", yylineno, yytext);
    lexical_errors++;
}

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
    printf("\n------------------------------------------------\n");
    if (lexical_errors == 0) {
        printf("***Lexing successful***\n");
        printf("Lexical Errors = 0\n");
    } else {
        printf("***Lexing failed***\n");
        printf("Lexical Errors = %d\n", lexical_errors);
    }
    printf("------------------------------------------------\n");
    return 0;
}
