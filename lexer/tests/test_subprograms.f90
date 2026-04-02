PROGRAM test_subprograms
  IMPLICIT NONE
  INTEGER :: result
  result = add(3, 4)
  PRINT *, result
CONTAINS
  FUNCTION add(a, b)
    INTEGER :: a, b, add
    add = a + b
  END FUNCTION add

  SUBROUTINE greet(x)
    INTEGER :: x
    PRINT *, x
  END SUBROUTINE greet

  RECURSIVE FUNCTION fact(n) RESULT(res)
    INTEGER :: n, res
    IF (n == 1) THEN
      res = 1
    ELSE
      res = n * fact(n - 1)
    END IF
  END FUNCTION fact
END PROGRAM test_subprograms