program test6
  complex :: val
  val = (1.0, 2.0)
  val = (1, 2.0)
  val = (1.0, 2)
  val = (1, 2)
  print *, (val)
end program test6