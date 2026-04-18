program test_semantic_07_do_loop_var_not_integer
  implicit none
  real :: i
  integer :: n
  n = 3
  do i = 1, n
    n = n + 1
  end do
end program test_semantic_07_do_loop_var_not_integer
