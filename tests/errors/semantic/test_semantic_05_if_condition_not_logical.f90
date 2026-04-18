program test_semantic_05_if_condition_not_logical
  implicit none
  integer :: a
  a = 1
  if (a) then
    a = a + 1
  end if
end program test_semantic_05_if_condition_not_logical
