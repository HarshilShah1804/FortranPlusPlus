#ifndef AST_H
#define AST_H

/**
 * Core AST data structures and low-level utilities.
 * This layer remains generic and independent of parser logic.
 */

typedef enum {
    NODE_PROGRAM,
    NODE_MODULE,
    NODE_BLOCK,
    NODE_ARG_LIST,

    NODE_DECL,
    NODE_ASSIGN,
    NODE_IF,
    NODE_DO,
    NODE_CALL,
    NODE_RETURN,
    NODE_STOP,

    NODE_BINARY_OP,
    NODE_UNARY_OP,

    NODE_LITERAL_INT,
    NODE_LITERAL_REAL,
    NODE_LITERAL_LOGICAL,
    NODE_LITERAL_STRING,

    NODE_IDENTIFIER,
    NODE_VAR,

    NODE_CALL_OR_INDEX
} NodeType;

/**
 * Abstract Syntax Tree Node
 * 
 * Uses a union-based design where each NodeType has specific,
 * strongly-typed fields for its attributes.
 * 
 * type: Discriminator indicating which union member is active
 * data: Union containing type-specific fields
 */
typedef struct ASTNode {
    NodeType type;
    union {
        /* Binary operations: + - * / == < > etc */
        struct {
            char *op;
            struct ASTNode *lhs;
            struct ASTNode *rhs;
        } binary_op;

        /* Unary operations: - + NOT etc */
        struct {
            char *op;
            struct ASTNode *expr;
        } unary_op;

        /* Literals: 42, 3.14, true, "hello" */
        struct {
            char *value;
        } literal;

        /* Identifier: variable/function names */
        struct {
            char *name;
        } identifier;

        /* Variable: wraps an identifier */
        struct {
            struct ASTNode *id;
        } var;

        /* Assignment: lhs = rhs */
        struct {
            struct ASTNode *lhs;
            struct ASTNode *rhs;
        } assign;

        /* If statement: condition, then branch, optional else branch */
        struct {
            struct ASTNode *cond;
            struct ASTNode *then_b;
            struct ASTNode *else_b;
        } if_stmt;

        /* Call statement: function, arguments */
        struct {
            struct ASTNode *func;
            struct ASTNode *args;
        } call;

        /* Call or Index: base, arguments/indices */
        struct {
            struct ASTNode *base;
            struct ASTNode *args;
        } call_or_index;

        /* Nodes with no specific data (program, module, etc) */
        struct {
            struct ASTNode **children;
            int num_children;
        } generic;
    } data;
} ASTNode;

/**
 * Create a new AST node of the specified type
 * 
 * Use this for generic nodes (PROGRAM, MODULE, etc) that have variable children.
 * For typed nodes, use the specific builder functions in ast_builders.h.
 * 
 * @param type The node type
 * @return Pointer to newly allocated ASTNode
 */
ASTNode* new_node(NodeType type);

/**
 * Add a child to a generic AST node
 * 
 * Only valid for PROGRAM, MODULE, and other container nodes.
 * For typed nodes, use the builders.
 * 
 * @param parent The parent node (must not be NULL)
 * @param child The child node to add (NULL children are ignored)
 */
void add_child(ASTNode *parent, ASTNode *child);


#endif /* AST_H */
