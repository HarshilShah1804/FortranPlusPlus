program test_basic_control
  integer :: a, b, c, i, total

  a = 4
  b = 6
  c = a + b * 2

  total = 0
  do i = 1, 5
    total = total + i
  end do

  if (c > total) then
    c = c - total
  else
    c = c + total
  endif

  print *, a, b, c, total
end program test_basic_control
