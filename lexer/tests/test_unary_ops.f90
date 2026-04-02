PROGRAM test_unary_ops
  IMPLICIT NONE
  INTEGER :: a, b
  LOGICAL :: flag, result
  a = -5
  b = +a
  flag = .NOT. .TRUE.
  result = .NOT. flag
  a = -(b + 3)
  b = -a * 2
  PRINT *, a, b
END PROGRAM test_unary_ops