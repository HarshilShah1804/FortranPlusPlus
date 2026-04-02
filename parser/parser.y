%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char *s);
int yylex();

typedef struct ASTNode {
    char *symbol;
    char *lexeme;
    struct ASTNode **children;
    int num_children;
} ASTNode;

ASTNode *root = NULL;

ASTNode* create_node(const char* symbol, const char* lexeme) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    node->symbol = strdup(symbol);
    node->lexeme = lexeme ? strdup(lexeme) : NULL;
    node->children = NULL;
    node->num_children = 0;
    return node;
}

void add_child(ASTNode* parent, ASTNode* child) {
    if (!child) return;
    parent->num_children++;
    parent->children = (ASTNode**)realloc(parent->children,
                        parent->num_children * sizeof(ASTNode*));
    parent->children[parent->num_children - 1] = child;
}

void print_reverse_tree(ASTNode* node, int depth) {
    if (node == NULL) return;
    for (int i = node->num_children - 1; i >= 0; i--)
        print_reverse_tree(node->children[i], depth + 1);
    for (int i = 0; i < depth; i++) printf("  ");
    if (node->lexeme)
        printf("%s (%s)\n", node->symbol, node->lexeme);
    else
        printf("%s\n", node->symbol);
}

// CLOJURE FORMATTING
void make_sym_clojure_compatible(char *str) {
    if (!str) return;
    for (int i = 0; str[i]; i++) {
        if (str[i] == '@') {
            str[i] = '/';
        }
    }
}

void print_clojure_tree(ASTNode* node, int depth) {
    if (node == NULL) return;

    for (int i = 0; i < depth; i++) printf("  ");

    printf("(:%s", node->symbol); 

    if (node->lexeme) {
        char *lex_copy = strdup(node->lexeme);
        make_sym_clojure_compatible(lex_copy);
        printf(" \"%s\"", lex_copy);
        free(lex_copy);
    }

    if (node->num_children == 0) {
        printf(")\n");
    } else {
        printf("\n");
        for (int i = 0; i < node->num_children; i++) {
            print_clojure_tree(node->children[i], depth + 1);
        }
        for (int i = 0; i < depth; i++) printf("  ");
        printf(")\n");
    }
}
%}

%union {
    char *str;
    struct ASTNode *node;
}

%token PROGRAM MODULE END CONTAINS USE NONE IMPLICIT
%token INTEGER REAL LOGICAL CHARACTER TYPE CLASS END_TYPE COMPLEX
%token IF THEN ELSE DO ENDIF LEN INTRINSIC WHILE SELECT CASE DEFAULT RANK
%token STOP PRINT CALL SUBROUTINE FUNCTION RETURN RECURSIVE RESULT
%token ALLOCATE DEALLOCATE ALLOCATED POINTER TARGET ALLOCATABLE INTENT IN OUT INOUT
%token OPEN CLOSE INQUIRE WRITE READ ERROR
%token LPAREN RPAREN COMMA COLON ASSUMED_RANK_SPECIFIER CONCAT
%token PP_DEFINE PP_UNDEF PP_IFDEF PP_IFNDEF PP_IF PP_ELIF PP_ELSE PP_ENDIF
%token LENGTH_SPECIFIER

%token <str> IDENTIFIER INT_CONST REAL_CONST STRING LOGICAL_CONST
%token <str> ARITH_OP REL_OP LOGICAL_OP ASSIGN EXPONENT DECL_SEP DERIVED_TYPE_COMPONENT

%type <node> start program_unit module_unit program_body module_body
%type <node> contains_block declarations type_spec attributes declaration_attributes
%type <node> identifier_list declarator_list declarator
%type <node> executables executable assignment_stmt if_stmt else_block
%type <node> do_stmt dowhile_stmt select_stmt case_blocks case_block
%type <node> call_stmt return_stmt stop_stmt print_stmt allocate_stmt deallocate_stmt
%type <node> expression factor array_access function_call variable_ref
%type <node> subprogram_list subprogram argument_list

%left LOGICAL_OP
%left REL_OP
%left ARITH_OP
%right EXPONENT
%right UNARY

%%

start: program_unit { $$ = create_node("start", NULL); add_child($$, $1); root = $$; }
     | module_unit  { $$ = create_node("start", NULL); add_child($$, $1); root = $$; }
     ;

program_unit: PROGRAM IDENTIFIER program_body END PROGRAM IDENTIFIER {
                $$ = create_node("program_unit", NULL);
                add_child($$, create_node("IDENTIFIER", $2));
                add_child($$, $3);
            }
            | PROGRAM IDENTIFIER program_body END PROGRAM {
                $$ = create_node("program_unit", NULL);
                add_child($$, create_node("IDENTIFIER", $2));
                add_child($$, $3);
            }
            ;

module_unit: MODULE IDENTIFIER module_body END MODULE IDENTIFIER {
                $$ = create_node("module_unit", NULL);
                add_child($$, create_node("IDENTIFIER", $2));
                add_child($$, $3);
           }
           | MODULE IDENTIFIER module_body END MODULE {
                $$ = create_node("module_unit", NULL);
                add_child($$, create_node("IDENTIFIER", $2));
                add_child($$, $3);
           }
           ;

program_body: declarations executables {
                $$ = create_node("program_body", NULL);
                add_child($$, $1); add_child($$, $2);
            }
            | declarations executables contains_block {
                $$ = create_node("program_body", NULL);
                add_child($$, $1); add_child($$, $2); add_child($$, $3);
            }
            ;

module_body: declarations {
                $$ = create_node("module_body", NULL);
                add_child($$, $1);
           }
           | declarations contains_block {
                $$ = create_node("module_body", NULL);
                add_child($$, $1); add_child($$, $2);
           }
           ;

contains_block: CONTAINS subprogram_list {
                $$ = create_node("contains_block", NULL);
                add_child($$, $2);
              }
              ;

declarations: /* empty */ { $$ = create_node("declarations", "empty"); }
            | declarations type_spec declaration_attributes DECL_SEP declarator_list {
                $$ = create_node("declarations", NULL);
                add_child($$, $1); add_child($$, $2);
                add_child($$, $3); add_child($$, $5);
            }
            | declarations IMPLICIT NONE {
                $$ = create_node("declarations", "IMPLICIT NONE");
                add_child($$, $1);
            }
            | declarations USE IDENTIFIER {
                $$ = create_node("declarations", "USE");
                add_child($$, $1);
                add_child($$, create_node("IDENTIFIER", $3));
            }
            ;

type_spec: INTEGER   { $$ = create_node("type_spec", "INTEGER"); }
         | REAL      { $$ = create_node("type_spec", "REAL"); }
         | LOGICAL   { $$ = create_node("type_spec", "LOGICAL"); }
         | CHARACTER { $$ = create_node("type_spec", "CHARACTER"); }
         | TYPE LPAREN IDENTIFIER RPAREN {
                $$ = create_node("type_spec", "TYPE");
                add_child($$, create_node("IDENTIFIER", $3));
           }
         | CLASS IDENTIFIER {
                $$ = create_node("type_spec", "CLASS");
                add_child($$, create_node("IDENTIFIER", $2));
           }
         | COMPLEX { $$ = create_node("type_spec", "COMPLEX"); }
         ;

attributes: /* empty */ { $$ = create_node("attributes", "empty"); }
          | attributes ALLOCATABLE { $$ = create_node("attributes", "ALLOCATABLE"); add_child($$, $1); }
          | attributes POINTER     { $$ = create_node("attributes", "POINTER");     add_child($$, $1); }
          | attributes TARGET      { $$ = create_node("attributes", "TARGET");      add_child($$, $1); }
          | attributes INTENT LPAREN IN    RPAREN { $$ = create_node("attributes", "INTENT IN");    add_child($$, $1); }
          | attributes INTENT LPAREN OUT   RPAREN { $$ = create_node("attributes", "INTENT OUT");   add_child($$, $1); }
          | attributes INTENT LPAREN INOUT RPAREN { $$ = create_node("attributes", "INTENT INOUT"); add_child($$, $1); }
          ;

declaration_attributes: /* empty */ { $$ = create_node("declaration_attributes", "empty"); }
                      | COMMA attributes { $$ = create_node("declaration_attributes", NULL); add_child($$, $2); }
                      ;

identifier_list: /* empty */  { $$ = create_node("identifier_list", "empty"); }
               | IDENTIFIER   {
                    $$ = create_node("identifier_list", NULL);
                    add_child($$, create_node("IDENTIFIER", $1));
               }
               | identifier_list COMMA IDENTIFIER {
                    $$ = create_node("identifier_list", NULL);
                    add_child($$, $1);
                    add_child($$, create_node("IDENTIFIER", $3));
               }
               ;

declarator_list: declarator {
                $$ = create_node("declarator_list", NULL);
                add_child($$, $1);
            }
            | declarator_list COMMA declarator {
                $$ = create_node("declarator_list", NULL);
                add_child($$, $1);
                add_child($$, $3);
            }
            ;

declarator: IDENTIFIER {
             $$ = create_node("declarator", NULL);
             add_child($$, create_node("IDENTIFIER", $1));
        }
        | IDENTIFIER LPAREN COLON RPAREN {
             $$ = create_node("declarator", "deferred_shape");
             add_child($$, create_node("IDENTIFIER", $1));
        }
        ;

executables: executable {
                $$ = create_node("executables", NULL);
                add_child($$, $1);
           }
           | executables executable {
                $$ = create_node("executables", NULL);
                add_child($$, $1); add_child($$, $2);
           }
           ;

executable: assignment_stmt { $$ = create_node("executable", NULL); add_child($$, $1); }
          | if_stmt          { $$ = create_node("executable", NULL); add_child($$, $1); }
          | print_stmt       { $$ = create_node("executable", NULL); add_child($$, $1); }
          | allocate_stmt    { $$ = create_node("executable", NULL); add_child($$, $1); }
          | deallocate_stmt  { $$ = create_node("executable", NULL); add_child($$, $1); }
          | do_stmt          { $$ = create_node("executable", NULL); add_child($$, $1); }
          | dowhile_stmt     { $$ = create_node("executable", NULL); add_child($$, $1); }
          | select_stmt      { $$ = create_node("executable", NULL); add_child($$, $1); }
          | call_stmt        { $$ = create_node("executable", NULL); add_child($$, $1); }
          | return_stmt      { $$ = create_node("executable", NULL); add_child($$, $1); }
          | stop_stmt        { $$ = create_node("executable", NULL); add_child($$, $1); }
          ;

assignment_stmt: variable_ref ASSIGN expression {
                    $$ = create_node("assignment_stmt", NULL);
                    add_child($$, $1);
                    add_child($$, create_node("ASSIGN", $2));
                    add_child($$, $3);
               }
               ;

if_stmt: IF LPAREN expression RPAREN THEN executables else_block ENDIF {
            $$ = create_node("if_stmt", NULL);
            add_child($$, $3); add_child($$, $6); add_child($$, $7);
       }
       ;

else_block: /* empty */ { $$ = create_node("else_block", "empty"); }
          | ELSE executables {
                $$ = create_node("else_block", NULL);
                add_child($$, $2);
          }
          ;

do_stmt: DO IDENTIFIER ASSIGN expression COMMA expression executables END DO {
            $$ = create_node("do_stmt", NULL);
            add_child($$, create_node("IDENTIFIER", $2));
            add_child($$, create_node("ASSIGN", $3));
            add_child($$, $4); add_child($$, $6); add_child($$, $7);
       }
       ;

dowhile_stmt: DO WHILE LPAREN expression RPAREN executables END DO {
                $$ = create_node("dowhile_stmt", NULL);
                add_child($$, $4); add_child($$, $6);
            }
            ;

select_stmt: SELECT CASE LPAREN expression RPAREN case_blocks END SELECT {
                $$ = create_node("select_stmt", NULL);
                add_child($$, $4); add_child($$, $6);
           }
           ;

case_blocks: case_block {
                $$ = create_node("case_blocks", NULL);
                add_child($$, $1);
           }
           | case_blocks case_block {
                $$ = create_node("case_blocks", NULL);
                add_child($$, $1); add_child($$, $2);
           }
           ;

case_block: CASE LPAREN expression RPAREN executables {
                $$ = create_node("case_block", NULL);
                add_child($$, $3); add_child($$, $5);
          }
          | CASE DEFAULT executables {
                $$ = create_node("case_block", "DEFAULT");
                add_child($$, $3);
          }
          ;

call_stmt: CALL IDENTIFIER LPAREN argument_list RPAREN {
                $$ = create_node("call_stmt", NULL);
                add_child($$, create_node("IDENTIFIER", $2));
                add_child($$, $4);
         }
         ;

return_stmt: RETURN { $$ = create_node("return_stmt", "RETURN"); } ;
stop_stmt:   STOP   { $$ = create_node("stop_stmt",   "STOP");   } ;

print_stmt: PRINT ARITH_OP COMMA argument_list {
                $$ = create_node("print_stmt", NULL);
                add_child($$, create_node("FORMAT_SPEC", $2));
                add_child($$, $4);
          }
          ;

allocate_stmt: ALLOCATE LPAREN argument_list RPAREN {
                                $$ = create_node("allocate_stmt", NULL);
                                add_child($$, $3);
                            }
                            ;

deallocate_stmt: DEALLOCATE LPAREN argument_list RPAREN {
                                    $$ = create_node("deallocate_stmt", NULL);
                                    add_child($$, $3);
                                }
                                ;

expression: expression ARITH_OP expression {
                $$ = create_node("expression", NULL);
                add_child($$, $1);
                add_child($$, create_node("ARITH_OP", $2));
                add_child($$, $3);
            }
          | expression EXPONENT expression {
                $$ = create_node("expression", NULL);
                add_child($$, $1);
                add_child($$, create_node("EXPONENT", $2));
                add_child($$, $3);
            }
          | expression REL_OP expression {
                $$ = create_node("expression", NULL);
                add_child($$, $1);
                add_child($$, create_node("REL_OP", $2));
                add_child($$, $3);
            }
          | expression LOGICAL_OP expression {
                $$ = create_node("expression", NULL);
                add_child($$, $1);
                add_child($$, create_node("LOGICAL_OP", $2));
                add_child($$, $3);
            }
          | factor { $$ = create_node("expression", NULL); add_child($$, $1); }
          | ARITH_OP expression %prec UNARY {
                $$ = create_node("expression", NULL);
                add_child($$, create_node("UNARY_OP", $1));
                add_child($$, $2);
            }
          | LOGICAL_OP expression %prec UNARY {
                $$ = create_node("expression", NULL);
                add_child($$, create_node("UNARY_OP", $1));
                add_child($$, $2);
            }
          ;

factor: array_access  { $$ = create_node("factor", NULL); add_child($$, $1); }
      | function_call  { $$ = create_node("factor", NULL); add_child($$, $1); }
      | variable_ref   { $$ = create_node("factor", NULL); add_child($$, $1); }
      | INT_CONST      { $$ = create_node("factor", NULL); add_child($$, create_node("INT_CONST",     $1)); }
      | REAL_CONST     { $$ = create_node("factor", NULL); add_child($$, create_node("REAL_CONST",    $1)); }
      | LOGICAL_CONST  { $$ = create_node("factor", NULL); add_child($$, create_node("LOGICAL_CONST", $1)); }
      | STRING         { $$ = create_node("factor", NULL); add_child($$, create_node("STRING",        $1)); }
      | LPAREN expression RPAREN { $$ = create_node("factor", "()"); add_child($$, $2); }
      ;

array_access: variable_ref LPAREN argument_list RPAREN {
                $$ = create_node("array_access", NULL);
                add_child($$, $1); add_child($$, $3);
            }
            ;

function_call: variable_ref LPAREN argument_list RPAREN {
                $$ = create_node("function_call", NULL);
                add_child($$, $1); add_child($$, $3);
             }
             ;

variable_ref: IDENTIFIER {
                $$ = create_node("variable_ref", NULL);
                add_child($$, create_node("IDENTIFIER", $1));
            }
            | variable_ref DERIVED_TYPE_COMPONENT IDENTIFIER {
                $$ = create_node("variable_ref", NULL);
                add_child($$, $1);
                add_child($$, create_node("IDENTIFIER", $3));
            }
            ;

subprogram_list: subprogram {
                    $$ = create_node("subprogram_list", NULL);
                    add_child($$, $1);
               }
               | subprogram_list subprogram {
                    $$ = create_node("subprogram_list", NULL);
                    add_child($$, $1); add_child($$, $2);
               }
               ;

subprogram: SUBROUTINE IDENTIFIER LPAREN identifier_list RPAREN program_body END SUBROUTINE {
                $$ = create_node("subprogram", "SUBROUTINE");
                add_child($$, create_node("IDENTIFIER", $2));
                add_child($$, $4); add_child($$, $6);
          }
          | SUBROUTINE IDENTIFIER LPAREN identifier_list RPAREN program_body END SUBROUTINE IDENTIFIER {
                $$ = create_node("subprogram", "SUBROUTINE");
                add_child($$, create_node("IDENTIFIER", $2));
                add_child($$, $4); add_child($$, $6);
          }
          | FUNCTION IDENTIFIER LPAREN identifier_list RPAREN program_body END FUNCTION {
                $$ = create_node("subprogram", "FUNCTION");
                add_child($$, create_node("IDENTIFIER", $2));
                add_child($$, $4); add_child($$, $6);
          }
          | FUNCTION IDENTIFIER LPAREN identifier_list RPAREN program_body END FUNCTION IDENTIFIER {
                $$ = create_node("subprogram", "FUNCTION");
                add_child($$, create_node("IDENTIFIER", $2));
                add_child($$, $4); add_child($$, $6);
          }
          | RECURSIVE FUNCTION IDENTIFIER LPAREN identifier_list RPAREN RESULT LPAREN IDENTIFIER RPAREN program_body END FUNCTION {
                $$ = create_node("subprogram", "RECURSIVE FUNCTION");
                add_child($$, create_node("IDENTIFIER", $3));
                add_child($$, $5); add_child($$, $11);
          }
          | RECURSIVE FUNCTION IDENTIFIER LPAREN identifier_list RPAREN RESULT LPAREN IDENTIFIER RPAREN program_body END FUNCTION IDENTIFIER {
                $$ = create_node("subprogram", "RECURSIVE FUNCTION");
                add_child($$, create_node("IDENTIFIER", $3));
                add_child($$, $5); add_child($$, $11);
          }
          ;

argument_list: expression {
                $$ = create_node("argument_list", NULL);
                add_child($$, $1);
             }
             | argument_list COMMA expression {
                $$ = create_node("argument_list", NULL);
                add_child($$, $1); add_child($$, $3);
             }
             ;

%%

extern int yylineno;
extern char *yytext;

void yyerror(const char *s) {
    fprintf(stderr, "PARSE ERROR\n");
    fprintf(stderr, "Message : %s\n", s);
    fprintf(stderr, "Near    : '%s'\n", yytext);
    fprintf(stderr, "Line    : %d\n", yylineno);
}

extern FILE *yyin;

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            perror("Error opening file");
            return 1;
        }
        yyin = file;
    } else {
        printf("Usage: ./compiler <filename.f90>\n");
        return 1;
    }

    printf("Starting parse\n");
    if (yyparse() == 0) {
        printf("Parsing done!\n");

        printf("\nReverse Derivation Tree\n");
        print_reverse_tree(root, 0);

        printf("\nClojure Serialization Format\n");
        print_clojure_tree(root, 0);
        printf("\n\n");

    } else {
        printf("Parsing failed.\n");
    }

    if (yyin != stdin) {
        fclose(yyin);
    }
    return 0;
}