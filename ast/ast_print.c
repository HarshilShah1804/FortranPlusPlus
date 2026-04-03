#include "ast_print.h"

#include <stdio.h>

static const char *ast_node_type_name(NodeType type)
{
    switch (type) {
        case NODE_PROGRAM: return "PROGRAM";
        case NODE_MODULE: return "MODULE";
        case NODE_BLOCK: return "BLOCK";
        case NODE_ARG_LIST: return "ARG_LIST";
        case NODE_DECL: return "DECL";
        case NODE_ASSIGN: return "ASSIGN";
        case NODE_IF: return "IF";
        case NODE_DO: return "DO";
        case NODE_CALL: return "CALL";
        case NODE_RETURN: return "RETURN";
        case NODE_STOP: return "STOP";
        case NODE_BINARY_OP: return "BINARY_OP";
        case NODE_UNARY_OP: return "UNARY_OP";
        case NODE_LITERAL_INT: return "LITERAL_INT";
        case NODE_LITERAL_REAL: return "LITERAL_REAL";
        case NODE_LITERAL_LOGICAL: return "LITERAL_LOGICAL";
        case NODE_LITERAL_STRING: return "LITERAL_STRING";
        case NODE_IDENTIFIER: return "IDENTIFIER";
        case NODE_VAR: return "VAR";
        case NODE_CALL_OR_INDEX: return "CALL_OR_INDEX";
        default: return "UNKNOWN";
    }
}

static void ast_indent(int depth)
{
    for (int i = 0; i < depth; ++i) {
        printf("  ");
    }
}

static void ast_print_impl(const ASTNode *node, int depth)
{
    if (!node) {
        return;
    }

    ast_indent(depth);
    printf("%s", ast_node_type_name(node->type));

    switch (node->type) {
        case NODE_LITERAL_INT:
        case NODE_LITERAL_REAL:
        case NODE_LITERAL_LOGICAL:
        case NODE_LITERAL_STRING:
            if (node->data.literal.value) {
                printf(": %s", node->data.literal.value);
            }
            printf("\n");
            return;
        case NODE_IDENTIFIER:
            if (node->data.identifier.name) {
                printf(": %s", node->data.identifier.name);
            }
            printf("\n");
            return;
        case NODE_BINARY_OP:
            if (node->data.binary_op.op) {
                printf(": %s", node->data.binary_op.op);
            }
            printf("\n");
            ast_print_impl(node->data.binary_op.lhs, depth + 1);
            ast_print_impl(node->data.binary_op.rhs, depth + 1);
            return;
        case NODE_UNARY_OP:
            if (node->data.unary_op.op) {
                printf(": %s", node->data.unary_op.op);
            }
            printf("\n");
            ast_print_impl(node->data.unary_op.expr, depth + 1);
            return;
        case NODE_ASSIGN:
            printf("\n");
            ast_print_impl(node->data.assign.lhs, depth + 1);
            ast_print_impl(node->data.assign.rhs, depth + 1);
            return;
        case NODE_IF:
            printf("\n");
            ast_print_impl(node->data.if_stmt.cond, depth + 1);
            ast_print_impl(node->data.if_stmt.then_b, depth + 1);
            ast_print_impl(node->data.if_stmt.else_b, depth + 1);
            return;
        case NODE_CALL:
            printf("\n");
            ast_print_impl(node->data.call.func, depth + 1);
            ast_print_impl(node->data.call.args, depth + 1);
            return;
        case NODE_CALL_OR_INDEX:
            printf("\n");
            ast_print_impl(node->data.call_or_index.base, depth + 1);
            ast_print_impl(node->data.call_or_index.args, depth + 1);
            return;
        case NODE_VAR:
            printf("\n");
            ast_print_impl(node->data.var.id, depth + 1);
            return;
        case NODE_DO:
        case NODE_PROGRAM:
        case NODE_MODULE:
        case NODE_BLOCK:
        case NODE_ARG_LIST:
        case NODE_DECL:
        case NODE_RETURN:
        case NODE_STOP:
        default:
            printf("\n");
            break;
    }

    if (node->data.generic.children) {
        for (int i = 0; i < node->data.generic.num_children; ++i) {
            ast_print_impl(node->data.generic.children[i], depth + 1);
        }
    }
}

void ast_print(const ASTNode *node)
{
    ast_print_impl(node, 0);
}
