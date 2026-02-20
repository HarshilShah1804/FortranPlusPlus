program stray_chars
    real :: price
    price = 100.50 @ 5  ! '@' is an invalid operator
    if (price > 50 $) then
        print *, "Too expensive!"
    end if
end program