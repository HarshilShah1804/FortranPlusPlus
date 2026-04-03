#include "ast_builders.h"
#include <stdlib.h>
#include <string.h>
#include <stddef.h>

/**
 * Helper: duplicate a string
 */
static char* strdup_safe(const char *s)
{
    if (!s) return NULL;
    char *dup = (char *)malloc(strlen(s) + 1);
    if (dup) strcpy(dup, s);
    return dup;
}

/**
 * Binary Operation
 * Type: NODE_BINARY_OP
 * Fields: op, lhs, rhs
 */
ASTNode* make_binary(char *op, ASTNode *lhs, ASTNode *rhs)
{
    ASTNode *node = new_node(NODE_BINARY_OP);
    if (!node) return NULL;
    
    node->data.binary_op.op = strdup_safe(op);
    node->data.binary_op.lhs = lhs;
    node->data.binary_op.rhs = rhs;
    
    return node;
}

/**
 * Unary Operation
 * Type: NODE_UNARY_OP
 * Fields: op, expr
 */
ASTNode* make_unary(char *op, ASTNode *expr)
{
    ASTNode *node = new_node(NODE_UNARY_OP);
    if (!node) return NULL;
    
    node->data.unary_op.op = strdup_safe(op);
    node->data.unary_op.expr = expr;
    
    return node;
}

/**
 * Integer Literal
 * Type: NODE_LITERAL_INT
 * Fields: value
 */
ASTNode* make_int(char *val)
{
    ASTNode *node = new_node(NODE_LITERAL_INT);
    if (!node) return NULL;
    
    node->data.literal.value = strdup_safe(val);
    
    return node;
}

/**
 * Real/Float Literal
 * Type: NODE_LITERAL_REAL
 * Fields: value
 */
ASTNode* make_real(char *val)
{
    ASTNode *node = new_node(NODE_LITERAL_REAL);
    if (!node) return NULL;
    
    node->data.literal.value = strdup_safe(val);
    
    return node;
}

/**
 * Logical Literal
 * Type: NODE_LITERAL_LOGICAL
 * Fields: value
 */
ASTNode* make_logical(char *val)
{
    ASTNode *node = new_node(NODE_LITERAL_LOGICAL);
    if (!node) return NULL;
    
    node->data.literal.value = strdup_safe(val);
    
    return node;
}

/**
 * String Literal
 * Type: NODE_LITERAL_STRING
 * Fields: value
 */
ASTNode* make_string(char *val)
{
    ASTNode *node = new_node(NODE_LITERAL_STRING);
    if (!node) return NULL;
    
    node->data.literal.value = strdup_safe(val);
    
    return node;
}

/**
 * Identifier
 * Type: NODE_IDENTIFIER
 * Fields: name
 */
ASTNode* make_identifier(char *name)
{
    ASTNode *node = new_node(NODE_IDENTIFIER);
    if (!node) return NULL;
    
    node->data.identifier.name = strdup_safe(name);
    
    return node;
}

/**
 * Variable
 * Type: NODE_VAR
 * Fields: id (identifier node)
 */
ASTNode* make_var(ASTNode *id)
{
    ASTNode *node = new_node(NODE_VAR);
    if (!node) return NULL;
    
    node->data.var.id = id;
    
    return node;
}

/**
 * Assignment
 * Type: NODE_ASSIGN
 * Fields: lhs, rhs
 */
ASTNode* make_assign(ASTNode *lhs, ASTNode *rhs)
{
    ASTNode *node = new_node(NODE_ASSIGN);
    if (!node) return NULL;
    
    node->data.assign.lhs = lhs;
    node->data.assign.rhs = rhs;
    
    return node;
}

/**
 * If Statement
 * Type: NODE_IF
 * Fields: cond, then_b, else_b (optional)
 */
ASTNode* make_if(ASTNode *cond, ASTNode *then_b, ASTNode *else_b)
{
    ASTNode *node = new_node(NODE_IF);
    if (!node) return NULL;
    
    node->data.if_stmt.cond = cond;
    node->data.if_stmt.then_b = then_b;
    node->data.if_stmt.else_b = else_b;
    
    return node;
}

/**
 * Function Call
 * Type: NODE_CALL
 * Fields: func, args
 */
ASTNode* make_call(ASTNode *func, ASTNode *args)
{
    ASTNode *node = new_node(NODE_CALL);
    if (!node) return NULL;
    
    node->data.call.func = func;
    node->data.call.args = args;
    
    return node;
}

/**
 * Call or Index (Temporary)
 * Type: NODE_CALL_OR_INDEX
 * Fields: base, args
 */
ASTNode* make_call_or_index(ASTNode *base, ASTNode *args)
{
    ASTNode *node = new_node(NODE_CALL_OR_INDEX);
    if (!node) return NULL;
    
    node->data.call_or_index.base = base;
    node->data.call_or_index.args = args;
    
    return node;
}

ASTNode* make_block(void)
{
    return new_node(NODE_BLOCK);
}

void block_add(ASTNode *block, ASTNode *child)
{
    add_child(block, child);
}

ASTNode* make_arg_list(void)
{
    return new_node(NODE_ARG_LIST);
}

void arg_list_add(ASTNode *list, ASTNode *arg)
{
    add_child(list, arg);
}

ASTNode* arg_list_prepend(ASTNode *list, ASTNode *arg)
{
    if (!arg) {
        return list;
    }
    
    ASTNode **new_children = (ASTNode **)malloc((list->data.generic.num_children + 1) * sizeof(ASTNode *));
    if (!new_children) {
        return list;
    }
    new_children[0] = arg;
    for (int i = 0; i < list->data.generic.num_children; ++i) {
        new_children[i + 1] = list->data.generic.children[i];
    }
    free(list->data.generic.children);
    list->data.generic.children = new_children;
    list->data.generic.num_children++;
    return list;
}
