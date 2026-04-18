program test_logical_literals
  logical :: a, b, c, d, e, f, g, h
  a = .true.
  b = .T.
  c = .false.
  d = .F.

  e = a .and. b
  f = c .or. d
  g = .not. c
  h = (a .and. c) .or. (.not. d)

end program test_logical_literals
