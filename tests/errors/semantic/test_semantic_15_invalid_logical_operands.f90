program test_semantic_15_invalid_logical_operands
  implicit none
  logical :: l
  integer :: a
  l = .true.
  a = 1
  l = l .and. a
end program test_semantic_15_invalid_logical_operands
