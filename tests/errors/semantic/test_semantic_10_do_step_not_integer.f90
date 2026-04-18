program test_semantic_10_do_step_not_integer
  implicit none
  integer :: i
  real :: st
  st = 1.2
  do i = 1, 5, st
    i = i + 1
  end do
end program test_semantic_10_do_step_not_integer
