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

function compareDates(now, date)
    local ranges = {
        {0, 6, "today"},
        {7, 24, "yesterday"},
        {25, 48, "two days ago"},
        {49, 72, "three days ago"},
        {73, 96, "four days ago"},
        {97, 24 * 7, "last week"},
        {24 * 7 + 1, 24 * 14, "last two week"},
        {24 * 14 + 1, 24 * 30, "last month"},
        {24 * 30 + 1, 24 * 365, "last year"},
    }
    local result = "more year ago"
    --print("now", inspect(os.date("*t")))
    --print("date", inspect(date))
    local t1, t2, diff = now.yday * 24 + now.hour, date.yday * 24 + date.hour, 0
    if date.year == now.year then
        diff = t1 - t2
    else
        diff = (now.year - date.year) * 365 * 24 - (t1 - t2)
    end
    for k, v in pairs(ranges) do
        local v1, v2 = v[1], v[2]
        if diff >= v1 and diff <= v2 then
            result = v[3]
            break
        end
    end
    --print(result)
    return result
end
