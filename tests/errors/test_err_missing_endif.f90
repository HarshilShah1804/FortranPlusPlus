program endif_test
  integer :: x
  x = 10
  if (x > 5) then
    print *, "Greater"
  ! Missing the ENDIF here!
end program endif_test
