#ifndef TAC_H
#define TAC_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_QUADS 2048

// Quadruple Structure
typedef struct {
    char *op;
    char *arg1;
    char *arg2;
    char *result;
} Quad;

typedef struct {
    char *place;
} TacValue;

// Core API
void tac_init();
char* tac_new_temp();
char* tac_new_label();
void tac_set_enabled(int enabled);
int tac_get_enabled();

// Quad emitter
void tac_emit_quad(const char *op, const char *arg1, const char *arg2, const char *result);

// Helpers for specific operations
void tac_emit_binary(char *result, const char *arg1, const char *op, const char *arg2);
void tac_emit_unary(char *result, const char *op, const char *arg1);
void tac_emit_assign(const char *result, const char *arg1);
void tac_emit_goto(const char *label);
void tac_emit_if_false_goto(const char *cond, const char *label);
void tac_emit_label(const char *label);

// Tabular Format Printer
void tac_print_quads(FILE *out);

TacValue* tac_make_value(const char *place);

#endif