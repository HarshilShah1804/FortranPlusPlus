program test_semantic_06_undeclared_loop_variable
  implicit none
  integer :: n
  n = 3
  do i = 1, n
    n = n + 1
  end do
end program test_semantic_06_undeclared_loop_variable
