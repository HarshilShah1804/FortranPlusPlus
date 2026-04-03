#include "ast.h"
#include <stdlib.h>
#include <string.h>

/**
 * Create a new AST node
 * 
 * Allocates memory for the node and initializes it with the given type.
 * All union fields are zeroed out.
 */
ASTNode* new_node(NodeType type)
{
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    if (!node) {
        return NULL;
    }

    node->type = type;
    
    /* Zero out the entire union */
    memset(&node->data, 0, sizeof(node->data));

    return node;
}

/**
 * Add a child node to a generic parent node
 * 
 * Reallocates the children array to accommodate the new child.
 * Ignores NULL children. Does nothing if parent is NULL.
 * 
 * Only valid for generic nodes (PROGRAM, MODULE, DO, etc).
 */
void add_child(ASTNode *parent, ASTNode *child)
{
    if (!parent || !child) {
        return;
    }

    parent->data.generic.num_children++;
    
    if (parent->data.generic.children) {
        parent->data.generic.children = (ASTNode **)realloc(parent->data.generic.children, 
                                               parent->data.generic.num_children * sizeof(ASTNode *));
    } else {
        parent->data.generic.children = (ASTNode **)malloc(parent->data.generic.num_children * sizeof(ASTNode *));
    }

    if (parent->data.generic.children) {
        parent->data.generic.children[parent->data.generic.num_children - 1] = child;
    }
}

