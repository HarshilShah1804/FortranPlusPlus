%option noyywrap
%option yylineno
%option case-insensitive

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../parser/y.tab.h"

int lexical_errors = 0;

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

"program"       {  return PROGRAM; }
"end"           {  return END; }
"integer"       {  return INTEGER; }
"real"          {  return REAL; }
"logical"       {  return LOGICAL; }
"character"     {  return CHARACTER; }
"if"            {  return IF; }
"endif"         {  return ENDIF; }
"then"          {  return THEN; }
"else"          {  return ELSE; }
"do"            {  return DO; }
"stop"          {  return STOP; }
"print"         {  return PRINT; }
"call"          {  return CALL; }
"subroutine"    {  return SUBROUTINE; }
"function"      {  return FUNCTION; }
"return"        {  return RETURN; }
"implicit"      {  return IMPLICIT; }
"none"          {  return NONE; }
"module"        {  return MODULE; }
"contains"      {  return CONTAINS; }
"use"           {  return USE; }
"end"{WS}+"type"    {  return END_TYPE; } 
"type"          {  return TYPE; }  
"len"        {  return LENGTH_SPECIFIER; }
"."("true"|"false"|"t"|"f")"."  {  return LOGICAL_CONST; }
"random_seed"   { return INTRINSIC;}
"random_number"   { return INTRINSIC;}

"recursive"     {  return RECURSIVE; }
"result"        {  return RESULT; }


"while"         {  return WHILE; }
"select"        {  return SELECT; }
"case"          {  return CASE; }
"default"       {  return DEFAULT; }
"rank"          {  return RANK; }

"class"         {  return CLASS; }
"complex"       {  return COMPLEX; }

"allocate"      {  return ALLOCATE; }
"deallocate"    {  return DEALLOCATE; }
"allocated"     {  return ALLOCATED; }
"pointer"       {  return POINTER; }
"target"        {  return TARGET; }
"allocatable"   {  return ALLOCATABLE; }
"intent"        {  return INTENT; }
"inout"         {  return INOUT; }
"in"            {  return IN; }
"out"           {  return OUT; }

"open"          {  return OPEN; }
"close"         {  return CLOSE; }
"inquire"       {  return INQUIRE; }
"write"         {  return WRITE; }
"read"          {  return READ; }
"error"         {  return ERROR; }

"=="|"/="|"<="|">="|"<"|">"   {   return REL_OP; }
"=>"  {  return PTR_ASSIGN; }
"="                            {   return ASSIGN; }
"+"|"-"|"*"|"/"               {   return ARITH_OP; }
"("                            {  return LPAREN; }
")"                            {  return RPAREN; }
","                            {  return COMMA; }
"::"                           {   return DECL_SEP; }
":"                            {  return COLON; }
".."                          {  return ASSUMED_RANK_SPECIFIER; }
"**"                           {   return EXPONENT; }
"//"                           {  return CONCAT; }
"%"   {   return DERIVED_TYPE_COMPONENT; }


"#define"      {  return PP_DEFINE; }
"#undef"       {  return PP_UNDEF; }
"#ifdef"       {  return PP_IFDEF; }
"#ifndef"      {  return PP_IFNDEF; }
"#if"          {  return PP_IF; }
"#elif"        {  return PP_ELIF; }
"#else"        {  return PP_ELSE; }
"#endif"       {  return PP_ENDIF; }

"."("and"|"or"|"not")"."  {   return LOGICAL_OP; }


{REAL}         {   return REAL_CONST; }
{INT}          {   return INT_CONST; }
{STRING}       {   return STRING; }

{ID}           { 
    if (yyleng > 63) {
        printf("[Line %-3d]  ERROR: Identifier exceeds 63 chars\n", yylineno);
        lexical_errors++;
    } else {
         
        
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