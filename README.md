# CS 327: Compilers
## Lab Assignment 4: Intermediate Code Generation (Quadruples)

### Group 7
- **Chaitanya Sharma** (23110072)
- **Harshil Shah** (23110132)
- **Jeet Joshi** (23110148)
- **Akshat Saurin Shah**

---

This repository contains the end-to-end implementation of the Intermediate Code Generation (IR) phase for our custom Fortran-like compiler. The pipeline seamlessly translates high-level Abstract Syntax Tree (AST) representations and syntax rules into low-level **Three Address Code (TAC)**, formatted strictly as Quadruples.

## Build & Run

### 1. Compile the Pipeline
To build the Lexer, Parser, AST, and TAC modules:
```bash
./compile.sh
```

### 2. Run a Single Test
Parse a file and generate its IR table:
```bash
./parser_out tests/test_multi_decl.f90
```

### 3. Run all Test Cases
Run our automated script to execute all standard and error test cases, print their source code, and append the generated Quadruple tables into an output file (`output.txt`):
```bash
./run_all_tests.sh
```

---

## Implementation Details & Features

### Part 1: SDT-Based TAC Generation
- **Strict Quadruple Format:** Output is rigorously formatted as `OP | ARG1 | ARG2 | RESULT`.
- **Syntax Directed Translation:** IR is generated via SDT rules embedded directly in the Yacc grammar. 
- **Context-Aware Execution:** Implemented a state-machine context manager (`g_ctx`). Declarative blocks (like `MODULE` or `SUBROUTINE` definitions) are cleanly isolated from executable code, preventing rogue IR generation during the definition phase.
- **Dynamic Temporaries:** Automated generation of variables (`t1`, `t2`, `t3`) for nested arithmetic and complex expressions.

### Part 2: Extended Control Flow Support
- **Decision Making:** Fully supports `IF`, `IF-ELSE`, and `SELECT CASE` statements, dynamically generating `ifFalse` evaluation and `goto` branch labels (e.g., `L1`, `L2`).
- **Iterative Constructs:** Supports `DO` loops (with custom step values) and `DO WHILE` loops. The TAC accurately reflects initialization, bounds-checking, increments, and back-jumping.
- **Function/Subroutine Calls:** Maps arguments to sequential `param` instructions followed by a `call [name], [argc]` quadruple.

### Part 3: Clean Tabular Output
The internal representation utilizes a decoupled `Quad` memory array (`ir/tac.c`). During parsing, operations are pushed to this struct array. Upon a successful parse, the entire array is printed top-to-bottom in a highly readable, aligned tabular format. Additionally, an extended implementation (`ir/tac_quad_with_exp.c`) is included in the repository, which dynamically reconstructs the high-level expressions into a 5-column table (First column for expression) for enhanced debugging and readability.

### Part 4: Robust Diagnostics & Error Handling (3 Marks)
To demonstrate the resilience of the compiler pipeline, we ran a comprehensive suite of intentional error files (`tests/errors/`). The compiler successfully intercepted unsupported constructs and syntax violations without crashing or dumping core memory:
- **Detecting Unsupported Constructs (Lexical Limits):** The Lexer (Flex) tracks character lengths and detects invalid symbols before they corrupt the AST. As seen in `test_error_invalid_symbols.f90` and `test_err_lex_limits.f90`, the lexer logs the exact line of the stray character (`@`) or oversized identifier but continues processing safely.
- **Meaningful Error Messages & Visual Localization:** When an invalid expression is detected, the Yacc parser halts and triggers our custom `yyerror` routine. This routine prints the exact `Line` and `Column` of the failure, extracts the raw source code string, and places a visual caret (`^`) directly under the bad token.
- **State-Aware Hints:** The Lexer tracks nesting states (`paren_balance`, `if_balance`) in real-time. If the parser crashes due to an unclosed block, the compiler leverages these states to output human-readable hints:
  - *Missing Parentheses:* `test_error_no_closing_bracker.f90` outputs `Hint : Missing closing ')'`
  - *Unclosed Blocks:* `test_error_no_endif.f90` outputs `Hint : Missing ENDIF for an IF block`
  - *Unclosed Comments:* `test_error_multi_line_comment.f90` identifies an `Unclosed block comment`.
- **Crash Prevention:** In every single test case, memory is managed safely. TAC generation is aborted, and the program exits gracefully with `Parsing failed.` instead of causing a segmentation fault.

---

## Test Suite
We have provided comprehensive `.f90` test files in the `tests/` directory to prove compiler capabilities across various constructs:
1. `test_multi_decl.f90` (Basic arithmetic and assignment)
2. `test_subprograms.f90` (Functions, recursion, parameters)
3. `test_do_loop_with_steps.f90` (Iterative constructs)
4. `test_logical_literals.f90` (Boolean logic)
5. `test_module_use.f90` (Context isolation)
6. *...and 9 others covering pointers, arrays, preprocessor directives, and complex literals.*

All test outputs (including graceful error handling) are documented in the final `output.txt` submission file.