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

void tac_set_enabled(int enabled) { g_enabled = enabled; }
int tac_get_enabled() { return g_enabled; }

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

// Core Quad Builder with Expression Generator
void tac_emit_quad(const char *op, const char *arg1, const char *arg2, const char *result) {
    if (!g_enabled) return; 
    
    if (quad_count >= MAX_QUADS) {
        fprintf(stderr, "Error: Maximum quadruple count exceeded.\n");
        return;
    }
    
    const char *safe_op   = op ? op : "-";
    const char *safe_arg1 = arg1 ? arg1 : "-";
    const char *safe_arg2 = arg2 ? arg2 : "-";
    const char *safe_res  = result ? result : "-";

    // Auto-generate the expression string for the table format
    char expr_buf[128] = "";
    if (strcmp(safe_op, "=") == 0) {
        snprintf(expr_buf, sizeof(expr_buf), "%s = %s", safe_res, safe_arg1);
    } else if (strcmp(safe_op, "ifFalse") == 0) {
        snprintf(expr_buf, sizeof(expr_buf), "ifFalse %s goto %s", safe_arg1, safe_res);
    } else if (strcmp(safe_op, "goto") == 0) {
        snprintf(expr_buf, sizeof(expr_buf), "goto %s", safe_res);
    } else if (strcmp(safe_op, "label") == 0) {
        snprintf(expr_buf, sizeof(expr_buf), "%s:", safe_res);
    } else if (strcmp(safe_op, "param") == 0) {
        snprintf(expr_buf, sizeof(expr_buf), "param %s", safe_arg1);
    } else if (strcmp(safe_op, "call") == 0) {
        if (strcmp(safe_res, "-") != 0)
            snprintf(expr_buf, sizeof(expr_buf), "%s = call %s, %s", safe_res, safe_arg1, safe_arg2);
        else
            snprintf(expr_buf, sizeof(expr_buf), "call %s, %s", safe_arg1, safe_arg2);
    } else if (strcmp(safe_op, "program") == 0 || strcmp(safe_op, "func") == 0) {
        snprintf(expr_buf, sizeof(expr_buf), "%s %s", safe_op, safe_arg1);
    } else if (strcmp(safe_op, "print") == 0 || strcmp(safe_op, "allocate") == 0 || strcmp(safe_op, "deallocate") == 0) {
        snprintf(expr_buf, sizeof(expr_buf), "%s %s", safe_op, safe_arg1);
    } else if (strcmp(safe_op, "end_prog") == 0 || strcmp(safe_op, "endfunc") == 0 || strcmp(safe_op, "return") == 0) {
        snprintf(expr_buf, sizeof(expr_buf), "%s", safe_op);
    } else {
        if (strcmp(safe_arg2, "-") == 0) {
            snprintf(expr_buf, sizeof(expr_buf), "%s = %s %s", safe_res, safe_op, safe_arg1); // Unary
        } else {
            snprintf(expr_buf, sizeof(expr_buf), "%s = %s %s %s", safe_res, safe_arg1, safe_op, safe_arg2); // Binary
        }
    }

    quad_list[quad_count].expr = strdup(expr_buf);
    quad_list[quad_count].op = strdup(safe_op);
    quad_list[quad_count].arg1 = strdup(safe_arg1);
    quad_list[quad_count].arg2 = strdup(safe_arg2);
    quad_list[quad_count].result = strdup(safe_res);
    quad_count++;
}

void tac_emit_binary(char *result, const char *arg1, const char *op, const char *arg2) { tac_emit_quad(op, arg1, arg2, result); }
void tac_emit_unary(char *result, const char *op, const char *arg1) { tac_emit_quad(op, arg1, "-", result); }
void tac_emit_assign(const char *result, const char *arg1) { tac_emit_quad("=", arg1, "-", result); }
void tac_emit_goto(const char *label) { tac_emit_quad("goto", "-", "-", label); }
void tac_emit_if_false_goto(const char *cond, const char *label) { tac_emit_quad("ifFalse", cond, "-", label); }
void tac_emit_label(const char *label) { tac_emit_quad("label", "-", "-", label); }

// Tabular Format (with Expression column) Printer
void tac_print_quads(FILE *out) {
    fprintf(out, "%-25s %-15s %-15s %-15s %-15s\n", "EXPRESSION", "OP", "ARG1", "ARG2", "RESULT");
    fprintf(out, "----------------------------------------------------------------------------------------\n");
    for (int i = 0; i < quad_count; i++) {
        Quad q = quad_list[i];
        if (strcmp(q.op, "label") == 0) {
            fprintf(out, "%-25s\n", q.expr);
        } else {
            fprintf(out, "%-25s %-15s %-15s %-15s %-15s\n", q.expr, q.op, q.arg1, q.arg2, q.result);
        }
    }
}

TacValue* tac_make_value(const char *place) {
    TacValue *val = malloc(sizeof(TacValue));
    val->place = place ? strdup(place) : NULL;
    return val;
}