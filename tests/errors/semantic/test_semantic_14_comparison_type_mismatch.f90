program test_semantic_14_comparison_type_mismatch
  implicit none
  integer :: a
  character(len=3) :: s
  logical :: b
  a = 1
  s = 'abc'
  b = (a == s)
end program test_semantic_14_comparison_type_mismatch
