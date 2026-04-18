# Semantic Error Test References

Each entry below maps a semantic error handled by the parser to:
- a dedicated test file in `tests/errors/semantic/`
- its captured parser output in `ir_outputs/errors/`

1. Duplicate declaration
   - Test: `tests/errors/semantic/test_semantic_01_duplicate_declaration.f90`
   - Output: `ir_outputs/errors/test_semantic_01_duplicate_declaration.txt`

2. Type mismatch in declaration initialization
   - Test: `tests/errors/semantic/test_semantic_02_decl_init_mismatch.f90`
   - Output: `ir_outputs/errors/test_semantic_02_decl_init_mismatch.txt`

3. Undeclared identifier with IMPLICIT NONE
   - Test: `tests/errors/semantic/test_semantic_03_undeclared_identifier.f90`
   - Output: `ir_outputs/errors/test_semantic_03_undeclared_identifier.txt`

4. Type mismatch in assignment
   - Test: `tests/errors/semantic/test_semantic_04_assignment_mismatch.f90`
   - Output: `ir_outputs/errors/test_semantic_04_assignment_mismatch.txt`

5. IF condition must be LOGICAL
   - Test: `tests/errors/semantic/test_semantic_05_if_condition_not_logical.f90`
   - Output: `ir_outputs/errors/test_semantic_05_if_condition_not_logical.txt`

6. Undeclared DO loop variable with IMPLICIT NONE
   - Test: `tests/errors/semantic/test_semantic_06_undeclared_loop_variable.f90`
   - Output: `ir_outputs/errors/test_semantic_06_undeclared_loop_variable.txt`

7. DO loop variable must be INTEGER
   - Test: `tests/errors/semantic/test_semantic_07_do_loop_var_not_integer.f90`
   - Output: `ir_outputs/errors/test_semantic_07_do_loop_var_not_integer.txt`

8. DO start bound must be INTEGER
   - Test: `tests/errors/semantic/test_semantic_08_do_start_not_integer.f90`
   - Output: `ir_outputs/errors/test_semantic_08_do_start_not_integer.txt`

9. DO end bound must be INTEGER
   - Test: `tests/errors/semantic/test_semantic_09_do_end_not_integer.f90`
   - Output: `ir_outputs/errors/test_semantic_09_do_end_not_integer.txt`

10. DO step must be INTEGER
   - Test: `tests/errors/semantic/test_semantic_10_do_step_not_integer.f90`
   - Output: `ir_outputs/errors/test_semantic_10_do_step_not_integer.txt`

11. DO step value cannot be zero
   - Test: `tests/errors/semantic/test_semantic_11_do_step_zero.f90`
   - Output: `ir_outputs/errors/test_semantic_11_do_step_zero.txt`

12. DO WHILE condition must be LOGICAL
   - Test: `tests/errors/semantic/test_semantic_12_do_while_condition_not_logical.f90`
   - Output: `ir_outputs/errors/test_semantic_12_do_while_condition_not_logical.txt`

13. Invalid operands for arithmetic operator
   - Test: `tests/errors/semantic/test_semantic_13_invalid_arithmetic_operands.f90`
   - Output: `ir_outputs/errors/test_semantic_13_invalid_arithmetic_operands.txt`

14. Type mismatch in comparison
   - Test: `tests/errors/semantic/test_semantic_14_comparison_type_mismatch.f90`
   - Output: `ir_outputs/errors/test_semantic_14_comparison_type_mismatch.txt`

15. Invalid operands for logical operator
   - Test: `tests/errors/semantic/test_semantic_15_invalid_logical_operands.f90`
   - Output: `ir_outputs/errors/test_semantic_15_invalid_logical_operands.txt`

16. Invalid unary operand
   - Test: `tests/errors/semantic/test_semantic_16_invalid_unary_operand.f90`
   - Output: `ir_outputs/errors/test_semantic_16_invalid_unary_operand.txt`

17. Non-array/procedure identifier used with ()
   - Test: `tests/errors/semantic/test_semantic_17_non_array_used_with_parens.f90`
   - Output: `ir_outputs/errors/test_semantic_17_non_array_used_with_parens.txt`
