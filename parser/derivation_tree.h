#ifndef DERIVATION_TREE_H
#define DERIVATION_TREE_H

#include <stddef.h>

typedef struct DerivationNode {
    char *symbol;
    struct DerivationNode **children;
    size_t child_count;
} DerivationNode;

typedef enum {
    DT_POSTORDER,
    DT_TREE
} DTPrintMode;

DerivationNode *dt_make_leaf(const char *symbol);
DerivationNode *dt_make_node(const char *symbol, size_t child_count, ...);

void dt_set_root(DerivationNode *root);
DerivationNode *dt_get_root(void);

void dt_print(const DerivationNode *node, DTPrintMode mode);

void dt_print_postorder(const DerivationNode *node);
void dt_free(DerivationNode *node);

#endif
