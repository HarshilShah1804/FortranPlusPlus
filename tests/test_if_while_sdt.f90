program if_while_sdt
  integer :: i, sum
  i = 0
  sum = 0
  do while (i < 5)
    if (i == 2) then
      sum = sum + 10
    else
      sum = sum + i
    end if
    i = i + 1
  end do
end program if_while_sdt
