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

-- подсчет процентов успешности за раунд для данного массива.
-- eq - массив с правильными нажатиями
-- pressed_arr - массив с нажатиями игрока
function calcPercent(eq, pressed_arr)
    if not eq then return 0 end --0% если не было нажатий
    local succ, mistake, count = 0, 0, 0
    for k, v in pairs(eq) do
        if v then
            count = count + 1
        end
        if v and pressed_arr[k] then
            succ = succ + 1
        end
        if not v and pressed_arr[k] then
            mistake = mistake + 1
        end
    end
    print(string.format("calcPercent() count = %d, succ = %d, mistake = %d", count, succ, mistake))
    return succ / count - mistake / count
end

function percentage(signals, pressed)
    local p1, p2, p3, p4 = calcPercent(signals.eq.sound, pressed.sound),
        calcPercent(signals.eq.color, pressed.color),
        calcPercent(signals.eq.form, pressed.form),
        calcPercent(signals.pos.eq, pressed.pos)
    local percent = {
        sound = p1 > 0.0 and p1 or 0.0,
        color = p2 > 0.0 and p2 or 0.0,
        form = p3 > 0.0 and p3 or 0.0,
        pos = p4 > 0.0 and p4 or 0.0,
    }
    percent.common = (percent.sound + percent.color + percent.form + percent.form) / 4
    return percent
end
--require "deepcopy"

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


