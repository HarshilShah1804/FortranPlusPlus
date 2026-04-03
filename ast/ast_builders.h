#ifndef AST_BUILDERS_H
#define AST_BUILDERS_H

#include "ast.h"

/**
 * AST Builders Module
 * 
 * Semantic constructors for building AST nodes.
 * These functions are used directly by the parser.
 * 
 * All builders depend only on ast.h core functions (new_node, add_child).
 */

/* Expressions */
ASTNode* make_binary(char *op, ASTNode *lhs, ASTNode *rhs);
ASTNode* make_unary(char *op, ASTNode *expr);

/* Literals */
ASTNode* make_int(char *val);
ASTNode* make_real(char *val);
ASTNode* make_logical(char *val);
ASTNode* make_string(char *val);

/* Variables */
ASTNode* make_identifier(char *name);
ASTNode* make_var(ASTNode *id);

/* Statements */
ASTNode* make_assign(ASTNode *lhs, ASTNode *rhs);
ASTNode* make_if(ASTNode *cond, ASTNode *then_b, ASTNode *else_b);

/* Calls */
ASTNode* make_call(ASTNode *func, ASTNode *args);

/* Temporary node (to be refined later) */
ASTNode* make_call_or_index(ASTNode *base, ASTNode *args);

/* Containers */
ASTNode* make_block(void);
void block_add(ASTNode *block, ASTNode *child);
ASTNode* make_arg_list(void);
void arg_list_add(ASTNode *list, ASTNode *arg);
ASTNode* arg_list_prepend(ASTNode *list, ASTNode *arg);

#endif /* AST_BUILDERS_H */
