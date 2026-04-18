# CS 327: Compilers
## Group 7

### Members
- Chaitanya Sharma (23110072)
- Harshil Shah (23110132)
- Jeet Joshi (23110148)
- Akshat Shah (23110293)

---

## 1. Project Goal and Scope

This repository contains the complete compiler pipeline implementation up to the **Intermediate Representation (IR) / Three Address Code (TAC)** generation stage.

The implementation demonstrates:
- lexical analysis,
- syntax analysis,
- semantic checks,
- and syntax-directed IR generation,

as an integrated, end-to-end compiler workflow.

The concrete grammar used in this repository is a structured imperative language subset used in the course testbench (with declarations, expressions, conditionals, loops, calls, and memory-related statements). The compiler architecture and all major translation conventions align with lecture concepts for C-like compiler design up to IR generation.

---

## 2. End-to-End Pipeline (Implemented)

The compiler is implemented as an integrated front-end pipeline where each phase produces artifacts consumed by the next phase. This section documents each stage in detail, including interfaces, internal state, and failure behavior.

### 2.1 Pipeline

Execution starts in `main` inside `parser/parser.y` (C epilogue section after grammar rules).

At runtime, the driver performs the following sequence:

1. Opens the input source file.
2. Initializes TAC state (`tac_init`).
3. Initializes semantic state (`sdt_semantic_reset`).
4. Invokes `yyparse()`.
5. If parse succeeds and semantic error count is zero:
   - prints `Parsing done!`
   - prints TAC table via `tac_print`.
6. If parse fails:
   - emits parser diagnostic and exits non-zero.
7. If parse succeeds but semantic errors were collected:
   - emits semantic failure summary and exits non-zero.

This design cleanly separates syntax failure and semantic failure while still allowing semantic checks to run during SDT.

### 2.2 Phase 1: Lexical Analysis (Scanner)

Implemented in:
- `lexer/lexer.l`
- generated scanner: `lexer/lex.yy.c`

Responsibilities:
- Convert source characters into parser tokens (`IDENTIFIER`, constants, operators, keywords, punctuation).
- Preserve token-level context used by parser diagnostics (`yytext`, line/column tracking hooks used in `yyerror`).
- Recognize keywords and operators needed by grammar (including relational/logical operators and loop/control tokens).

Output contract:
- Scanner yields token stream and semantic token values (`yylval`) to parser.

Failure behavior:
- Lexical irregularities propagate to parser error paths or tokenization diagnostics depending on lexer rule handling.

### 2.3 Phase 2: Syntax Analysis (Yacc Parser)

Implemented in:
- `parser/parser.y`

Responsibilities:
- Validate source program against grammar productions.
- Enforce precedence/associativity for expression parsing via `%left`, `%right`, `%nonassoc` declarations.
- Build derivation-tree nodes for grammar non-terminals.
- Trigger SDT actions on reductions.

Key grammar clusters:
- declarations (`type_spec`, declarators, attributes)
- expressions and factors
- assignments
- control flow (`if`, `else`, `do`, `do while`)
- calls/print/allocate/deallocate/select/select rank

Output contract:
- On successful parse, reductions have already produced semantic checks and TAC side effects.

Failure behavior:
- `yyerror` prints detailed diagnostics:
  - message, line, column, near-token,
  - source line with caret,
  - specific hints for unclosed parentheses / missing endif.

### 2.4 Phase 3: Syntax-Directed Translation (SDT) During Reductions

SDT actions are embedded directly in parser rules (`parser/parser.y`).

Core design:
- Grammar reductions are not only structural; each reduction may also:
  - evaluate type rules,
  - allocate temporary names,
  - emit TAC instructions,
  - push/pop control-flow context.

Representative behavior:
- Arithmetic expression reduction:
  - create temp (`tN`),
  - type-check operands,
  - emit TAC binary op.
- Assignment reduction:
  - verify assignment compatibility,
  - emit assignment TAC.
- IF/ELSE and loop reductions:
  - allocate labels,
  - emit branch/jump/label instructions,
  - preserve correct control-flow edges.

Why this is important:
- IR is generated in a single pass over parse reductions, avoiding a separate AST-walk backend at this project stage.

### 2.5 Phase 4: Semantic Analysis Utilities

Implemented in:
- `semantic/sdt_semantic.c`
- `semantic/sdt_semantic.h`

Internal state:
- linked-list symbol table (`SdtSymbol`) storing:
  - identifier name,
  - semantic type,
  - array metadata.
- implicit-none mode flag.
- global semantic error counter.

Utility categories:
- symbol management:
  - declare, lookup.
- type compatibility:
  - assignment compatibility,
  - unary/binary expression type validation.
- diagnostics:
  - centralized semantic error reporting with consistent prefix.

Semantic checks executed through parser SDT include:
- duplicate declarations,
- undeclared identifiers under `implicit none`,
- assignment mismatches,
- invalid logical/arithmetic/comparison combinations,
- non-logical conditions in `if` / `do while`,
- invalid DO loop variable/bounds/step constraints,
- invalid indexed use of non-array identifiers.

Failure behavior:
- semantic checks may continue collecting multiple errors,
- final parse success still exits non-zero if semantic error count > 0.

### 2.6 Phase 5: TAC/IR Construction

Implemented in:
- `ir/tac.h`
- `ir/tac.c`

IR model:
- linked list of `TacInstr` records.
- each instruction stores op kind and operands/destination.
- output printed in quadruple-style columns: `op`, `arg1`, `arg2`, `result`.

Instruction families used:
- assignment (`=`)
- unary / binary computations
- conditional jump (`ifFalseGoto`)
- unconditional jump (`goto`)
- labels (`label`)
- `raw` for higher-level statements preserved at this phase.

Naming conventions:
- temporaries: `t1`, `t2`, ... via `tac_new_temp`.
- labels: `L1`, `L2`, ... via `tac_new_label`.

Emission behavior:
- TAC appends in program execution order as reductions occur.
- optional emission gating exists (`tac_set_enabled`) for grammar regions where IR emission is intentionally suppressed (e.g., some structural contexts).

### 2.7 Phase 6: Output Materialization and Test Artifacts

Primary outputs:
- TAC for positive tests in `ir_outputs/`.
- syntax/semantic diagnostics and error references in `ir_outputs/errors/`.

Scripts:
- `compile.sh`: build pipeline.
- `run_parser_tests.sh`: parser-oriented batch verification.
- `run_best_ir_tests_to_outputs.sh`: curated TAC outputs with source and parser output.

This output strategy provides reproducible evidence for evaluator inspection.

### 2.8 Data Flow Summary (Interface View)

Source file -> Lexer tokens -> Parser reductions + SDT -> Semantic utility checks + TAC emission -> Final TAC table / diagnostics.

More concretely:

1. scanner returns token + lexeme metadata.
2. parser consumes token stream and reduces grammar rules.
3. each relevant reduction invokes semantic utility APIs.
4. passing checks allow TAC emission calls.
5. emitted instructions accumulate in TAC list.
6. final driver prints TAC if no semantic failure summary blocks success.

### 2.9 Success and Failure Paths

Success path:
- parse accepted,
- semantic error count = 0,
- TAC table printed,
- process exits 0.

Failure path A (syntax):
- parse rejected,
- parser diagnostic printed,
- no valid TAC completion,
- process exits non-zero.

Failure path B (semantic):
- parse accepted structurally,
- one or more semantic errors collected,
- semantic summary printed,
- process exits non-zero.

This dual-path design follows lecture expectations: syntax and semantics are treated as distinct validation layers.

---

## 3. Member-Wise Contribution Summary

The pipeline was implemented collaboratively, with work split almost equally across four members. Each member owned one primary subsystem and also contributed to integration, debugging, and testing.

### 3.1 Chaitanya Sharma: Lexical Analysis + Token Integration
- Implemented and refined lexical rules in `lexer/lexer.l` for identifiers, literals, keywords, operators, delimiters, and comment forms.
- Ensured token definitions are consistent with parser-side expectations (`%token` declarations in `parser/parser.y`).
- Added/validated scanner behavior for edge cases and malformed inputs to improve downstream parser diagnostics.
- Contributed to integration fixes where scanner output and parser reductions needed synchronization.

### 3.2 Akshat Shah: Grammar Design + Parsing + Syntax Diagnostics
- Designed/updated grammar productions in `parser/parser.y` for declarations, expressions, control flow, and statement-level constructs.
- Defined precedence and associativity declarations for correct expression parsing and ambiguity control.
- Implemented robust syntax error reporting (`yyerror`) with line/column, near-token, source context, and hints.
- Worked with Member 1 and Member 3 to ensure grammar reductions trigger correct semantic checks and SDT actions.

### 3.3 Harshil Shah: Semantic Analysis + Type System Checks
- Implemented semantic utility APIs in `semantic/sdt_semantic.c`/`semantic/sdt_semantic.h`.
- Built symbol table operations for declaration/lookup and array metadata tracking.
- Implemented assignment compatibility, unary/binary evaluation checks, implicit-none enforcement, and centralized semantic error reporting.
- Added and validated semantic-negative tests under `tests/errors/semantic/` to ensure each semantic diagnostic path is covered.

### 3.4 Jeet Joshi: IR/TAC Generation + SDT Lowering + Output Artifacts
- Implemented TAC representation and emit utilities in `ir/tac.h` and `ir/tac.c`.
- Added temporary and label generation (`t1`, `t2`, ... and `L1`, `L2`, ...).
- Integrated SDT-based TAC emission in parser actions for arithmetic, assignment, conditionals, loops, and control-transfer.
- Standardized TAC output formatting and helped generate reference outputs in `ir_outputs/` and `ir_outputs/errors/`.

### 3.5 Shared Integration Work (All Members)
- Cross-module integration of lexer -> parser -> semantic checker -> TAC emitter.
- Creation and maintenance of test programs under `tests/` and error suites under `tests/errors/`.
- Script-level reproducibility support (`compile.sh`, parser/IR test runners).
- Regression debugging and validation of end-to-end behavior before final output generation.

This split keeps ownership clear while maintaining near-equal overall effort through shared integration and testing responsibilities.

---

## 4. Why This Demonstrates a Compiler up to IR

To convince evaluation that the implementation is a compiler up to intermediate code generation, the repository provides all required compiler phases with working handoff:

- **Scanner produces tokens** consumed by parser.
- **Parser enforces grammar** and builds semantic context.
- **Semantic checks validate types/symbol use** before accepting constructs.
- **IR is emitted for accepted programs** in canonical TAC form.
- **Errors are reported with actionable diagnostics** for syntax and semantic violations.

Thus, this is not only a parser; it is a complete front-end + IR generator pipeline.

---

# Assignment-4 Specific Documentation

## 5. IR Design and Conventions

### 5.1 TAC Shape
IR is represented as TAC quadruple rows with columns:
- `op`
- `arg1`
- `arg2`
- `result`

### 5.2 Emitted Instruction Categories
- Assignment (`=`)
- Binary ops (`+`, `-`, `*`, `/`, relational, logical, etc.)
- Unary ops
- Conditional jump (`ifFalseGoto`)
- Unconditional jump (`goto`)
- Labels (`label`)
- Raw rows for high-level operations that are intentionally not lowered further in this stage

### 5.3 Naming Conventions
- Temporaries: `t1`, `t2`, `t3`, ...
- Labels: `L1`, `L2`, `L3`, ...

### 5.4 Translation Convention
- Bottom-up SDT actions create and chain TAC in execution order.
- Expression reductions produce typed intermediate values.
- Control flow constructs are lowered using labels and jumps.

These conventions are consistent with standard lecture treatment for quadruple-style intermediate code.

---

## 6. Supported Language Constructs

### 6.1 Expressions and Assignments
- Numeric and logical expressions
- Unary operators
- Binary operators with precedence and associativity
- Assignment statements with compatibility checks

### 6.2 Control Flow
- `if (...) then ... endif`
- `if (...) then ... else ... endif`
- Counted `do` loops (with optional step)
- `do while (...) ... end do`

### 6.3 Additional Statements (IR-compatible)
- `print`
- `call`
- `allocate`, `deallocate`
- `select case`, `select rank`
- pointer association and related constructs present in the grammar/tests

Some statements are emitted as TAC `raw` rows at this phase to preserve execution-order IR without introducing a later lowering pass.

---

## 7. Semantic Error Handling

Semantic handling includes:
- duplicate declaration detection,
- undeclared identifier detection (especially with `implicit none` mode),
- assignment type mismatch detection,
- invalid unary/binary/logical/comparison operand detection,
- invalid control-condition type detection,
- invalid loop variable/bound/step checks,
- and non-array indexed usage checks.

Diagnostics are emitted through centralized semantic utility functions and counted globally; non-zero semantic error count results in non-zero process exit.

Detailed semantic utility documentation is available in:
- `semantic/README.md`

---

## 8. Parsing Error Handling

Parser error reporting includes:
- explicit parse error banner,
- error message from parser,
- source line and column,
- near-token display,
- inline source context with caret marker,
- contextual hints for unbalanced parentheses and IF/ENDIF imbalance.

This format is designed to follow lecture-style diagnostic clarity and evaluator readability.

---

## 9. Scripts, Execution, and Reproducibility

### 9.1 Build
- `./compile.sh`

### 9.2 Run a Single Test
- `./parser_out tests/test_program.f90`

### 9.3 Batch Test Scripts
- `./run_parser_tests.sh`
- `./run_best_ir_tests_to_outputs.sh`

### 9.4 Outputs
- Per-test TAC outputs: `ir_outputs/`
- Error-reference outputs: `ir_outputs/errors/`
- Semantic error mapping/reference file: `ir_outputs/errors/semantic_error_references.md`

---

## 10. Example of End-to-End Lowering

Given source containing assignment + arithmetic + control flow, the pipeline performs:

1. tokenization,
2. parse reductions,
3. semantic validation,
4. TAC emission with temporaries and labels,
5. final tabular print.

Example TAC pattern:
- expression temp creation (`t1 = b * 4`),
- composed expression (`t2 = a + t1`),
- assignment (`c = t2`),
- branch lowering (`ifFalseGoto tCond Lelse`),
- join labels and loop back edges.

This demonstrates canonical IR generation strategy taught in compiler design lectures.

---

## 12. Repository Structure

- `lexer/` -> lexical rules and scanner artifacts
- `parser/` -> grammar, parser actions, parse diagnostics
- `semantic/` -> semantic utilities, type checks, symbol table
- `ir/` -> TAC instruction utilities and print logic
- `tests/` -> positive and feature tests
- `tests/errors/` -> syntax and semantic negative tests
- `ir_outputs/` -> generated TAC outputs and error references

---

## 13. Current Status

The repository currently provides a functioning compiler front-end and intermediate code generator, with comprehensive tests and error references. It is suitable for evaluator demonstration of design and implementation up to the IR phase.