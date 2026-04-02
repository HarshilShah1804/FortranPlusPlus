PROGRAM test_derived_component
  IMPLICIT NONE
  INTEGER :: x
  x = obj%field
  x = obj%inner%value
  obj%field = 42
  obj%inner%value = x + 1
  PRINT *, obj%field
END PROGRAM test_derived_component