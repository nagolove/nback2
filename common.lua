
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

-- source http://lua-users.org/wiki/CopyTable 
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
