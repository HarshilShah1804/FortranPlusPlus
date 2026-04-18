program test_semantic_11_do_step_zero
  implicit none
  integer :: i
  do i = 1, 5, 0
    i = i + 1
  end do
end program test_semantic_11_do_step_zero
