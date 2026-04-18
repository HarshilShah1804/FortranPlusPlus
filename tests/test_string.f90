program test_string
    character :: c1
    character(len=:), allocatable :: c2
    character(len=5) :: c3
    character(len=10) :: c4
    logical :: eq_check, neq_check

    character :: c5 = 'a'
    c1 = 'z'
    c2 = "'hello'"

    c3 = 'abcde'

    c3 = 'aQQQe'

    eq_check = (c3 == 'aQQQe')
    neq_check = (c4 /= 'zzzzz')
    
end program test_string