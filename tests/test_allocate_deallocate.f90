program test_allocate_deallocate
  implicit none
  integer, allocatable :: a(:)

  allocate(a(10))
  deallocate(a)
end program test_allocate_deallocate
