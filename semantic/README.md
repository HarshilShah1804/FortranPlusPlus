# Semantic Error Handling Utilities

This document explains the utilities used for semantic checking and semantic error reporting in this project.

## Core State

The semantic module keeps parser-wide state in static globals:

- `g_symbols`: Head of linked-list symbol table (`SdtSymbol`).
- `g_implicit_none`: Tracks whether `IMPLICIT NONE` is active.
- `g_semantic_errors`: Count of semantic errors found in current parse.

The `SdtSymbol` record stores:

- `name`: Identifier name.
- `type`: Declared semantic type (`SdtType`).
- `is_array`: Array flag for validating indexed usage.
- `next`: Link to next symbol.

## Utility Groups

### 1) Lifecycle and Mode Control

- `void sdt_semantic_reset(void)`
  - Clears symbol table memory.
  - Resets implicit-none mode and error counter.
  - Called before each parse run.

- `void sdt_semantic_set_implicit_none(int enabled)`
  - Enables/disables strict declaration mode.

- `int sdt_semantic_is_implicit_none(void)`
  - Returns current implicit-none status.

### 2) Symbol Table Utilities

- `int sdt_semantic_declare(const char *name, SdtType type, int is_array)`
  - Inserts a new symbol.
  - Returns `0` on invalid input, duplicate declaration, or allocation failure.

- `int sdt_semantic_lookup(const char *name, SdtType *type_out, int *is_array_out)`
  - Finds symbol by name.
  - Optionally returns declared type and array flag.
  - Returns `1` if found, `0` otherwise.

These are used to detect undeclared identifiers, duplicate declarations, and invalid array-style usage.

### 3) Type Compatibility Helpers

- `int sdt_semantic_assignment_compatible(SdtType dst, SdtType src)`
  - Checks assignment legality.
  - Supports exact match and widening rules currently implemented:
    - `INTEGER -> REAL`
    - `INTEGER/REAL -> COMPLEX`
  - Allows unknown types to pass (prevents cascaded false errors).

- `SdtType sdt_semantic_eval_binary(const char *op, SdtType lhs, SdtType rhs, int *ok_out)`
  - Validates operands for binary operators.
  - Infers output type.
  - Distinguishes logical, comparison, and arithmetic classes.

- `SdtType sdt_semantic_eval_unary(const char *op, SdtType operand, int *ok_out)`
  - Validates unary operator usage (`.not.` vs numeric unary operators).
  - Infers output type.

- `const char *sdt_semantic_type_name(SdtType type)`
  - Converts type enum to readable text for diagnostics.

### 4) Error Reporting Utilities

- `void sdt_semantic_error(const char *fmt, ...)`
  - Increments semantic error count.
  - Prints a normalized message prefix: `SEMANTIC ERROR:`.
  - Supports formatted, context-rich diagnostics.

- `int sdt_semantic_error_count(void)`
  - Returns the total semantic errors raised in the current parse.
  - Parser uses this to fail compilation after syntax succeeds.

## Internal Helper Functions (Implementation Details)

These helpers support utility behavior but are not exported:

- `sdt_strdup`: Safe local duplicate helper.
- `sdt_ieq`: Case-insensitive token comparison.
- `sdt_is_numeric`: Numeric type predicate.
- `sdt_is_logical_op`: Logical operator classification.
- `sdt_is_comparison_op`: Comparison operator classification.
- `sdt_is_not_op`: Unary not classifier.

## Semantic Error Flow In Parsing

1. Parser starts and calls `sdt_semantic_reset()`.
2. Declarations call `sdt_semantic_declare()`.
3. Variable references use `sdt_semantic_lookup()`.
4. Expression rules call `sdt_semantic_eval_binary()` / `sdt_semantic_eval_unary()`.
5. Assignment and control statements call compatibility checks.
6. Any violation calls `sdt_semantic_error(...)`.
7. At parse end, parser checks `sdt_semantic_error_count()`.
8. If count > 0, parser reports semantic failure and exits with non-zero status.

## Typical Errors Covered By These Utilities

- Duplicate declaration.
- Undeclared identifier use under `IMPLICIT NONE`.
- Assignment type mismatch.
- Invalid binary/unary operator operands.
- Non-logical IF/DO WHILE condition.
- Invalid DO loop bounds/step types and zero step.
- Non-array symbol used with index/call syntax.

## Notes

- The symbol table is currently a linear linked list; lookup is O(n).
- Unknown type permissiveness is intentional to reduce cascading diagnostics.
- Error messages are centralized through one reporting utility for consistent output formatting.
