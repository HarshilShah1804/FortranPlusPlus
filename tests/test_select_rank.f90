program test_select_rank
  implicit none
  integer, allocatable :: arr(:)

  allocate(arr(5))

  select rank(arr)
  rank(0)
    print *, "scalar"
  rank(1)
    print *, "1D array"
  rank(*)
    print *, "assumed rank"
  rank default
    print *, "other"
  end select

end program test_select_rank
