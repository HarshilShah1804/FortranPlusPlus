#include "derivation_tree.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static DerivationNode *g_root = NULL;

static DerivationNode *dt_alloc_node(const char *symbol, size_t child_count) {
    DerivationNode *node = (DerivationNode *)calloc(1, sizeof(DerivationNode));
    if (!node) {
        return NULL;
    }

    node->symbol = strdup(symbol ? symbol : "");
    node->child_count = child_count;

    if (child_count > 0) {
        node->children = (DerivationNode **)calloc(child_count, sizeof(DerivationNode *));
        if (!node->children) {
            free(node->symbol);
            free(node);
            return NULL;
        }
    }

    return node;
}

DerivationNode *dt_make_leaf(const char *symbol) {
    return dt_alloc_node(symbol, 0);
}

DerivationNode *dt_make_node(const char *symbol, size_t child_count, ...) {
    DerivationNode *node = dt_alloc_node(symbol, child_count);
    if (!node) {
        return NULL;
    }

    if (child_count == 0) {
        return node;
    }

    va_list args;
    va_start(args, child_count);
    for (size_t i = 0; i < child_count; ++i) {
        node->children[i] = va_arg(args, DerivationNode *);
    }
    va_end(args);

    return node;
}

void dt_set_root(DerivationNode *root) {
    g_root = root;
}

DerivationNode *dt_get_root(void) {
    return g_root;
}

static void dt_print_postorder_impl(const DerivationNode *node, int depth) {
    if (!node) {
        return;
    }

    for (size_t i = 0; i < node->child_count; ++i) {
        dt_print_postorder_impl(node->children[i], depth + 1);
    }

    for (int i = 0; i < depth; ++i) {
        printf("  ");
    }
    printf("%s\n", node->symbol ? node->symbol : "");
}

void dt_print_postorder(const DerivationNode *node) {
    dt_print_postorder_impl(node, 0);
}

static void dt_print_tree_impl(const DerivationNode *node, int depth) {
    if (!node) return;

    // print current node
    for (int i = 0; i < depth; ++i) {
        printf("  ");
    }
    printf("%s\n", node->symbol ? node->symbol : "");

    // then print children
    for (size_t i = 0; i < node->child_count; ++i) {
        dt_print_tree_impl(node->children[i], depth + 1);
    }
}

void dt_print_tree(const DerivationNode *node) {
    dt_print_tree_impl(node, 0);
}

void dt_print(const DerivationNode *node, DTPrintMode mode) {
    if (mode == DT_TREE)
        dt_print_tree(node);
    else
        dt_print_postorder(node);
}

void dt_free(DerivationNode *node) {
    if (!node) {
        return;
    }

    for (size_t i = 0; i < node->child_count; ++i) {
        dt_free(node->children[i]);
    }

    free(node->children);
    free(node->symbol);
    free(node);
}
