
function pack(...)
    return {...}
end

function xassert(a, ...)
    if a then return a, ... end
    local f = ...
    if type(f) == "function" then
        error(f(select(2, ...)), 2)
    else
        error(f or "assertion failed!", 2)
    end
end

function table.copy(t)
    return {unpack(t)}
end

local newunit = require "newunit"

example1()
--example2_local()
print("xx", _G["xx"])
print("yy", _G["yy"])

local var1 = newunit.new()
var1.do_something()
var1.do_something()
var1:do_something2()

newunit.do_something()
newunit:do_something2()
newunit:do_something2()
