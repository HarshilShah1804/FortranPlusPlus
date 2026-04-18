#include "tac.h"

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

static TacInstr *g_head = NULL;
static TacInstr *g_tail = NULL;
static int g_temp_counter = 0;
static int g_label_counter = 0;
static int g_emit_enabled = 1;

static char *tac_strdup(const char *s)
{
    if (!s) {
        return NULL;
    }

    size_t len = strlen(s);
    char *out = (char *)malloc(len + 1);
    if (!out) {
        return NULL;
    }
    memcpy(out, s, len + 1);
    return out;
}

static void tac_append(TacInstr *ins)
{
    if (!ins) {
        return;
    }

    ins->next = NULL;
    if (!g_head) {
        g_head = ins;
        g_tail = ins;
        return;
    }

    g_tail->next = ins;
    g_tail = ins;
}

static TacInstr *tac_make_instr(TacOp op, const char *result, const char *arg1, const char *arg2, const char *op_text)
{
    TacInstr *ins = (TacInstr *)malloc(sizeof(TacInstr));
    if (!ins) {
        return NULL;
    }

    ins->op = op;
    ins->result = tac_strdup(result);
    ins->arg1 = tac_strdup(arg1);
    ins->arg2 = tac_strdup(arg2);
    ins->op_text = tac_strdup(op_text);
    ins->next = NULL;
    return ins;
}

void tac_init(void)
{
    g_head = NULL;
    g_tail = NULL;
    g_temp_counter = 0;
    g_label_counter = 0;
    g_emit_enabled = 1;
}

void tac_set_enabled(int enabled)
{
    g_emit_enabled = enabled ? 1 : 0;
}

int tac_get_enabled(void)
{
    return g_emit_enabled;
}

void tac_emit_raw(const char *fmt, ...)
{
    if (!g_emit_enabled) {
        return;
    }
    if (!fmt) {
        return;
    }

    char buffer[512];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);

    tac_append(tac_make_instr(TAC_RAW, NULL, NULL, NULL, buffer));
}

void tac_emit_assign(const char *dst, const char *src)
{
    if (!g_emit_enabled) {
        return;
    }
    tac_append(tac_make_instr(TAC_ASSIGN, dst, src, NULL, NULL));
}

void tac_emit_binary(const char *dst, const char *lhs, const char *op, const char *rhs)
{
    if (!g_emit_enabled) {
        return;
    }
    tac_append(tac_make_instr(TAC_BINARY, dst, lhs, rhs, op));
}

void tac_emit_unary(const char *dst, const char *op, const char *operand)
{
    if (!g_emit_enabled) {
        return;
    }
    tac_append(tac_make_instr(TAC_UNARY, dst, operand, NULL, op));
}

void tac_emit_if_false_goto(const char *cond, const char *label)
{
    if (!g_emit_enabled) {
        return;
    }
    tac_append(tac_make_instr(TAC_IF_FALSE_GOTO, label, cond, NULL, NULL));
}

void tac_emit_goto(const char *label)
{
    if (!g_emit_enabled) {
        return;
    }
    tac_append(tac_make_instr(TAC_GOTO, label, NULL, NULL, NULL));
}

void tac_emit_label(const char *label)
{
    if (!g_emit_enabled) {
        return;
    }
    tac_append(tac_make_instr(TAC_LABEL, label, NULL, NULL, NULL));
}

void tac_print(FILE *out)
{
    if (!out) {
        out = stdout;
    }

    fprintf(out, "%-16s %-24s %-24s %-24s\n", "op", "arg1", "arg2", "result");
    fprintf(out, "%-16s %-24s %-24s %-24s\n", "----------------", "------------------------", "------------------------", "------------------------");

    for (TacInstr *cur = g_head; cur; cur = cur->next) {
        const char *op = "";
        const char *arg1 = "";
        const char *arg2 = "";
        const char *result = "";

        switch (cur->op) {
            case TAC_ASSIGN:
                op = "=";
                arg1 = cur->arg1 ? cur->arg1 : "";
                result = cur->result ? cur->result : "";
                break;
            case TAC_BINARY:
                op = cur->op_text ? cur->op_text : "binary";
                arg1 = cur->arg1 ? cur->arg1 : "";
                arg2 = cur->arg2 ? cur->arg2 : "";
                result = cur->result ? cur->result : "";
                break;
            case TAC_UNARY:
                op = cur->op_text ? cur->op_text : "unary";
                arg1 = cur->arg1 ? cur->arg1 : "";
                result = cur->result ? cur->result : "";
                break;
            case TAC_IF_FALSE_GOTO:
                op = "ifFalseGoto";
                arg1 = cur->arg1 ? cur->arg1 : "";
                arg2 = cur->result ? cur->result : "";
                break;
            case TAC_GOTO:
                op = "goto";
                arg1 = cur->result ? cur->result : "";
                break;
            case TAC_LABEL:
                op = "label";
                result = cur->result ? cur->result : "";
                break;
            case TAC_RAW:
            default:
                op = "raw";
                result = cur->op_text ? cur->op_text : "";
                break;
        }

        fprintf(out, "%-16s %-24s %-24s %-24s\n", op, arg1, arg2, result);
    }
}

char *tac_new_temp(void)
{
    char buffer[32];
    snprintf(buffer, sizeof(buffer), "t%d", ++g_temp_counter);
    return tac_strdup(buffer);
}

char *tac_new_label(void)
{
    char buffer[32];
    snprintf(buffer, sizeof(buffer), "L%d", ++g_label_counter);
    return tac_strdup(buffer);
}

TacValue *tac_make_value(char *place)
{
    return tac_make_typed_value(place, SDT_TYPE_UNKNOWN);
}

TacValue *tac_make_typed_value(char *place, SdtType type)
{
    TacValue *val = (TacValue *)malloc(sizeof(TacValue));
    if (!val) {
        return NULL;
    }
    val->place = place;
    val->type = type;
    return val;
}
