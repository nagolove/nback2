
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

function pointInRect(px, py, x, y, w, h)
    return px > x and py > y and px < x + w and py < y + h
end
