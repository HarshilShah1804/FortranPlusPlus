program test_string
    character :: c1
    character(len=:), allocatable :: c2
    character(len=5) :: c3
    character(len=10) :: c4

    character :: c5 = 'a'
    c2 = "'hello'"
end program test_string