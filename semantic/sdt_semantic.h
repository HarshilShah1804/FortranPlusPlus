#ifndef SDT_SEMANTIC_H
#define SDT_SEMANTIC_H

#include "sdt_types.h"

void sdt_semantic_reset(void);

void sdt_semantic_set_implicit_none(int enabled);
int sdt_semantic_is_implicit_none(void);

int sdt_semantic_declare(const char *name, SdtType type, int is_array);
int sdt_semantic_lookup(const char *name, SdtType *type_out, int *is_array_out);

int sdt_semantic_assignment_compatible(SdtType dst, SdtType src);
SdtType sdt_semantic_eval_binary(const char *op, SdtType lhs, SdtType rhs, int *ok_out);
SdtType sdt_semantic_eval_unary(const char *op, SdtType operand, int *ok_out);

const char *sdt_semantic_type_name(SdtType type);

void sdt_semantic_error(const char *fmt, ...);
int sdt_semantic_error_count(void);

#endif /* SDT_SEMANTIC_H */
