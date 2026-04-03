#include "ast_utils.h"

#include <stddef.h>

static ASTNode *g_ast_root = NULL;

void ast_set_root(ASTNode *root)
{
    g_ast_root = root;
}

ASTNode *ast_get_root(void)
{
    return g_ast_root;
}
