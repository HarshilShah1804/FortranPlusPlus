program pointer_basic
    integer, target :: x
    integer, pointer :: p

    x = 10
    p => x

    print *, p
end program