program if_only_demo
  implicit none
  integer :: x

  x = 1
  if (x > 0) then
    x = x + 1
  endif

  print *, x
end program if_only_demo
