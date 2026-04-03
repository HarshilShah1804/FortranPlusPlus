program demo
implicit none

module mathmod
contains

recursive function add(a, b) result(res)
integer :: a, b
integer :: res
res = a + b
end function add

subroutine show()
integer :: x
x = 5
print *, x
end subroutine show

end module mathmod

use mathmod

type :: point
integer :: x, y
end type point

class(point) :: p
allocate(p)

if (p%x > 0) then
print *, "positive"
else
print *, "zero or negative"
end if

select case (p%x)
case (1)
print *, "one"
case default
print *, "other"
end select

do while (p%x < 10)
p%x = p%x + 1
end do

open(10)
write(10,*) p%x
read(10,*) p%x
close(10)

inquire(10)

error stop
end program demo
