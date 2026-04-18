#ifndef TAC_H
#define TAC_H

#include <stdio.h>
#include "../semantic/sdt_types.h"

typedef enum {
    TAC_RAW = 0,
    TAC_ASSIGN,
    TAC_BINARY,
    TAC_UNARY,
    TAC_IF_FALSE_GOTO,
    TAC_GOTO,
    TAC_LABEL
} TacOp;

typedef struct TacInstr {
    TacOp op;
    char *op_text;   /* operator token for TAC_BINARY/TAC_UNARY or raw text */
    char *arg1;
    char *arg2;
    char *result;
    struct TacInstr *next;
} TacInstr;

typedef struct TacValue {
    char *place;
    SdtType type;
} TacValue;

void tac_init(void);
void tac_set_enabled(int enabled);
int tac_get_enabled(void);
void tac_emit_raw(const char *fmt, ...);
void tac_emit_assign(const char *dst, const char *src);
void tac_emit_binary(const char *dst, const char *lhs, const char *op, const char *rhs);
void tac_emit_unary(const char *dst, const char *op, const char *operand);
void tac_emit_if_false_goto(const char *cond, const char *label);
void tac_emit_goto(const char *label);
void tac_emit_label(const char *label);
void tac_print(FILE *out);

char *tac_new_temp(void);
char *tac_new_label(void);
TacValue *tac_make_value(char *place);
TacValue *tac_make_typed_value(char *place, SdtType type);

#endif /* TAC_H */
