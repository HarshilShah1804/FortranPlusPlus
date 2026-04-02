PROGRAM test_contains_block
  IMPLICIT NONE
  INTEGER :: x
  x = 10
  CALL double(x)
  PRINT *, x
CONTAINS
  SUBROUTINE double(n)
    INTEGER :: n
    n = n * 2
  END SUBROUTINE double
END PROGRAM test_contains_block