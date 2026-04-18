program test_semantic_08_do_start_not_integer
  implicit none
  integer :: i
  real :: s
  s = 1.5
  do i = s, 5
    i = i + 1
  end do
end program test_semantic_08_do_start_not_integer
