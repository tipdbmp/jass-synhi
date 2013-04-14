// not bar! =)
function foo takes nothing returns integer
    local string s = "this is a // funny integer => 5"

    local real r = 1.1 // rather arbitrary =)
    loop
        exitwhen r>=10.4

        set r = r + 0.1
    endloop

    if (1 <= 2 and 2 <= 3) then
        call Foo()
    elseif (not (1 > 0))
        call Bar()
    elseif ! 1 == 0x0123 then
    elseif 1 != 'ogru' then
    elseif true != false then
    else
        call FooBar()
    endif

    call CreateUnitBJ()
    s = "another string" // comment with "string inside"

    return S2I(s)
endfunction
