program test_semantic_09_do_end_not_integer
  implicit none
  integer :: i
  real :: e
  e = 5.5
  do i = 1, e
    i = i + 1
  end do
end program test_semantic_09_do_end_not_integer
