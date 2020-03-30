require "gooi.gooi"
local inspect = require "libs.inspect"

function pack(...)
    return {...}
end

-- integer division
function div(a, b)
    return (a - a % b) / b
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

function make_screenshot()
    local i = 0
    local fname
    repeat
        i = i + 1
        fname = love.filesystem.getInfo("screenshot" .. i .. ".png")
    until not fname
    love.graphics.captureScreenshot("screenshot" .. i .. ".png")
end

require "deepcopy"

function storeGooi()
    --local g = { components = deepcopy(gooi.components) }
    print("gooi.components", inspect(gooi.components))
    --local g = { components = table.deepcopy(gooi.components) }
    local g = { components = gooi.components }
    gooi.components = {}
    return g
end

function restoreGooi(g)
    if g == nil then
        error("g == nil")
    end
    --assert(g)
    gooi.components = g.components
end


