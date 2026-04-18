#include "sdt_semantic.h"

#include <ctype.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct SdtSymbol {
    char *name;
    SdtType type;
    int is_array;
    struct SdtSymbol *next;
} SdtSymbol;

static SdtSymbol *g_symbols = NULL;
static int g_implicit_none = 0;
static int g_semantic_errors = 0;

static char *sdt_strdup(const char *text)
{
    if (!text) {
        return NULL;
    }

    size_t len = strlen(text);
    char *out = (char *)malloc(len + 1);
    if (!out) {
        return NULL;
    }
    memcpy(out, text, len + 1);
    return out;
}

static int sdt_ieq(const char *lhs, const char *rhs)
{
    if (!lhs || !rhs) {
        return 0;
    }

    while (*lhs && *rhs) {
        if (tolower((unsigned char)*lhs) != tolower((unsigned char)*rhs)) {
            return 0;
        }
        lhs++;
        rhs++;
    }

    return *lhs == '\0' && *rhs == '\0';
}

static int sdt_is_numeric(SdtType type)
{
    return type == SDT_TYPE_INTEGER || type == SDT_TYPE_REAL || type == SDT_TYPE_COMPLEX;
}

static int sdt_is_logical_op(const char *op)
{
    return sdt_ieq(op, ".and.") || sdt_ieq(op, ".or.") || sdt_ieq(op, "and") || sdt_ieq(op, "or");
}

static int sdt_is_comparison_op(const char *op)
{
    return sdt_ieq(op, "==") || sdt_ieq(op, "/=") || sdt_ieq(op, "!=") ||
           sdt_ieq(op, "<") || sdt_ieq(op, "<=") || sdt_ieq(op, ">") || sdt_ieq(op, ">=") ||
           sdt_ieq(op, ".eq.") || sdt_ieq(op, ".ne.") || sdt_ieq(op, ".lt.") ||
           sdt_ieq(op, ".le.") || sdt_ieq(op, ".gt.") || sdt_ieq(op, ".ge.");
}

static int sdt_is_not_op(const char *op)
{
    return sdt_ieq(op, ".not.") || sdt_ieq(op, "not");
}

void sdt_semantic_reset(void)
{
    SdtSymbol *cur = g_symbols;
    while (cur) {
        SdtSymbol *next = cur->next;
        free(cur->name);
        free(cur);
        cur = next;
    }

    g_symbols = NULL;
    g_implicit_none = 0;
    g_semantic_errors = 0;
}

void sdt_semantic_set_implicit_none(int enabled)
{
    g_implicit_none = enabled ? 1 : 0;
}

int sdt_semantic_is_implicit_none(void)
{
    return g_implicit_none;
}

int sdt_semantic_declare(const char *name, SdtType type, int is_array)
{
    if (!name || name[0] == '\0') {
        return 0;
    }

    SdtSymbol *cur = g_symbols;
    while (cur) {
        if (strcmp(cur->name, name) == 0) {
            return 0;
        }
        cur = cur->next;
    }

    SdtSymbol *sym = (SdtSymbol *)malloc(sizeof(SdtSymbol));
    if (!sym) {
        return 0;
    }

    sym->name = sdt_strdup(name);
    if (!sym->name) {
        free(sym);
        return 0;
    }

    sym->type = type;
    sym->is_array = is_array ? 1 : 0;
    sym->next = g_symbols;
    g_symbols = sym;
    return 1;
}

int sdt_semantic_lookup(const char *name, SdtType *type_out, int *is_array_out)
{
    if (!name || name[0] == '\0') {
        return 0;
    }

    SdtSymbol *cur = g_symbols;
    while (cur) {
        if (strcmp(cur->name, name) == 0) {
            if (type_out) {
                *type_out = cur->type;
            }
            if (is_array_out) {
                *is_array_out = cur->is_array;
            }
            return 1;
        }
        cur = cur->next;
    }

    return 0;
}

int sdt_semantic_assignment_compatible(SdtType dst, SdtType src)
{
    if (dst == SDT_TYPE_UNKNOWN || src == SDT_TYPE_UNKNOWN) {
        return 1;
    }

    if (dst == src) {
        return 1;
    }

    if (dst == SDT_TYPE_REAL && src == SDT_TYPE_INTEGER) {
        return 1;
    }

    if (dst == SDT_TYPE_COMPLEX && (src == SDT_TYPE_INTEGER || src == SDT_TYPE_REAL)) {
        return 1;
    }

    return 0;
}

SdtType sdt_semantic_eval_binary(const char *op, SdtType lhs, SdtType rhs, int *ok_out)
{
    int ok = 1;
    SdtType out = SDT_TYPE_UNKNOWN;

    if (sdt_is_logical_op(op)) {
        if (lhs != SDT_TYPE_LOGICAL || rhs != SDT_TYPE_LOGICAL) {
            ok = 0;
        }
        out = SDT_TYPE_LOGICAL;
    } else if (sdt_is_comparison_op(op)) {
        int same = lhs == rhs;
        int both_numeric = sdt_is_numeric(lhs) && sdt_is_numeric(rhs);
        if (!(same || both_numeric || lhs == SDT_TYPE_UNKNOWN || rhs == SDT_TYPE_UNKNOWN)) {
            ok = 0;
        }
        out = SDT_TYPE_LOGICAL;
    } else {
        if (!(sdt_is_numeric(lhs) && sdt_is_numeric(rhs)) && !(lhs == SDT_TYPE_UNKNOWN || rhs == SDT_TYPE_UNKNOWN)) {
            ok = 0;
        }

        if (lhs == SDT_TYPE_COMPLEX || rhs == SDT_TYPE_COMPLEX) {
            out = SDT_TYPE_COMPLEX;
        } else if (lhs == SDT_TYPE_REAL || rhs == SDT_TYPE_REAL) {
            out = SDT_TYPE_REAL;
        } else if (lhs == SDT_TYPE_INTEGER && rhs == SDT_TYPE_INTEGER) {
            out = SDT_TYPE_INTEGER;
        } else {
            out = SDT_TYPE_UNKNOWN;
        }
    }

    if (ok_out) {
        *ok_out = ok;
    }
    return out;
}

SdtType sdt_semantic_eval_unary(const char *op, SdtType operand, int *ok_out)
{
    int ok = 1;
    SdtType out = SDT_TYPE_UNKNOWN;

    if (sdt_is_not_op(op)) {
        if (operand != SDT_TYPE_LOGICAL && operand != SDT_TYPE_UNKNOWN) {
            ok = 0;
        }
        out = SDT_TYPE_LOGICAL;
    } else {
        if (!sdt_is_numeric(operand) && operand != SDT_TYPE_UNKNOWN) {
            ok = 0;
        }
        out = operand;
    }

    if (ok_out) {
        *ok_out = ok;
    }
    return out;
}

const char *sdt_semantic_type_name(SdtType type)
{
    switch (type) {
        case SDT_TYPE_INTEGER: return "INTEGER";
        case SDT_TYPE_REAL: return "REAL";
        case SDT_TYPE_LOGICAL: return "LOGICAL";
        case SDT_TYPE_CHARACTER: return "CHARACTER";
        case SDT_TYPE_COMPLEX: return "COMPLEX";
        case SDT_TYPE_UNKNOWN:
        default:
            return "UNKNOWN";
    }
}

void sdt_semantic_error(const char *fmt, ...)
{
    if (!fmt) {
        return;
    }

    g_semantic_errors++;
    fprintf(stderr, "SEMANTIC ERROR: ");

    va_list args;
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);

    fprintf(stderr, "\n");
}

int sdt_semantic_error_count(void)
{
    return g_semantic_errors;
}
