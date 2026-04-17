#include "tac.h"

static Quad quad_list[MAX_QUADS];
static int quad_count = 0;
static int temp_counter = 1;
static int label_counter = 1;
static int g_enabled = 1;

void tac_init() {
    quad_count = 0;
    temp_counter = 1;
    label_counter = 1;
    g_enabled = 1;
}

void tac_set_enabled(int enabled) {
    g_enabled = enabled;
}

int tac_get_enabled() {
    return g_enabled;
}

char* tac_new_temp() {
    char buf[16];
    snprintf(buf, sizeof(buf), "t%d", temp_counter++);
    return strdup(buf);
}

char* tac_new_label() {
    char buf[16];
    snprintf(buf, sizeof(buf), "L%d", label_counter++);
    return strdup(buf);
}

// Core Quad Builder
void tac_emit_quad(const char *op, const char *arg1, const char *arg2, const char *result) {
    if (!g_enabled) return; // Respect the parser's emit suppression
    
    if (quad_count >= MAX_QUADS) {
        fprintf(stderr, "Error: Maximum quadruple count exceeded.\n");
        return;
    }
    quad_list[quad_count].op = op ? strdup(op) : strdup("-");
    quad_list[quad_count].arg1 = arg1 ? strdup(arg1) : strdup("-");
    quad_list[quad_count].arg2 = arg2 ? strdup(arg2) : strdup("-");
    quad_list[quad_count].result = result ? strdup(result) : strdup("-");
    quad_count++;
}

// Helper wrappers
void tac_emit_binary(char *result, const char *arg1, const char *op, const char *arg2) {
    tac_emit_quad(op, arg1, arg2, result);
}

void tac_emit_unary(char *result, const char *op, const char *arg1) {
    tac_emit_quad(op, arg1, "-", result);
}

void tac_emit_assign(const char *result, const char *arg1) {
    tac_emit_quad("=", arg1, "-", result);
}

void tac_emit_goto(const char *label) {
    tac_emit_quad("goto", "-", "-", label);
}

void tac_emit_if_false_goto(const char *cond, const char *label) {
    tac_emit_quad("ifFalse", cond, "-", label);
}

void tac_emit_label(const char *label) {
    tac_emit_quad("label", "-", "-", label);
}

// Tabular Format
void tac_print_quads(FILE *out) {
    fprintf(out, "%-15s %-15s %-15s %-15s\n", "OP", "ARG1", "ARG2", "RESULT");
    fprintf(out, "------------------------------------------------------------\n");
    for (int i = 0; i < quad_count; i++) {
        Quad q = quad_list[i];
        
        // Formatting labels cleanly
        if (strcmp(q.op, "label") == 0) {
            fprintf(out, "%-15s\n", q.result);
        } else {
            fprintf(out, "%-15s %-15s %-15s %-15s\n", q.op, q.arg1, q.arg2, q.result);
        }
    }
}

TacValue* tac_make_value(const char *place) {
    TacValue *val = malloc(sizeof(TacValue));
    val->place = place ? strdup(place) : NULL;
    return val;
}