require "love"
require "nbtypes"
require "constants"

local i18n = require "i18n"
local gooi = require "gooi.gooi"
local serpent = require "serpent"

global settings: Settings
global __DEBUG__ = false
global onAndroid = love.system.getOS() == "Android"
global useKeyboard = true
global preventiveFirstRun = true

function pack(...: any): any
    return {...}
end

-- integer division
function div(a: number, b: number): number
    return (a - a % b) / b
end

--[[
function xassert(a, ...)
    if a then return a, ... end
    local f = ...
    if type(f) == "function" then
        error(f(select(2, ...)), 2)
    else
        error(f or "assertion failed!", 2)
    end
end
--]]

--function table.copy(t)
    --return {unpack(t)}
--end

-- source http://lua-users.org/wiki/CopyTable 
function deepcopy<T>(orig: T): T
    local orig_type = type(orig)
    if orig_type == 'table' then
        local copy = {}
        copy = {}
        for orig_key, orig_value in pairs(orig as {any:any}) do
            copy[deepcopy(orig_key as T)] = deepcopy(orig_value as T)
        end
        return copy as T
        --setmetatable(copy, deepcopy(getmetatable(orig) as T))
    else 
        return orig
    end
end

function make_screenshot()
    local i = 0
    local info: love.filesystem.FileInfo
    repeat
        i = i + 1
        info = love.filesystem.getInfo("screenshot" .. i .. ".png")
    until not info
    love.graphics.captureScreenshot("screenshot" .. i .. ".png")
end

-- подсчет процентов успешности за раунд для данного массива.
-- eq - массив с правильными нажатиями
-- pressed_arr - массив с нажатиями игрока
function calcPercent(eq: {boolean}, pressed_arr: {boolean}): number
    if not eq then return 0 end --0% если не было нажатий
    local succ, mistake, count = 0, 0, 0
    for k, v in ipairs(eq) do
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

function percentage(signals: Signals, pressed: Signals.Eq): Percentage
    local p1, p2, p3, p4: number, number, number, number
    p1 = calcPercent(signals.eq.sound, pressed.sound)
    p2 = calcPercent(signals.eq.color, pressed.color)
    p3 = calcPercent(signals.eq.form, pressed.form)
    p4 = calcPercent(signals.eq.pos, pressed.pos)
    local percent: Percentage = {
        sound = p1 > 0.0 and p1 or 0.0,
        color = p2 > 0.0 and p2 or 0.0,
        form = p3 > 0.0 and p3 or 0.0,
        pos = p4 > 0.0 and p4 or 0.0,
    }
    percent.common = (percent.sound + percent.color + percent.form + percent.form) / 4
    return percent
end
--require "deepcopy"

function storeGooi(): Gooi
    --local g = { components = deepcopy(gooi.components) }
    --print("gooi.components", inspect(gooi.components))
    --local g = { components = table.deepcopy(gooi.components) }
    local g = { components = gooi.components }
    gooi.components = {}
    return g
end

function restoreGooi(g: Gooi)
    if g == nil then
        error("g == nil")
    end
    --assert(g)
    gooi.components = g.components
end

function compareDates(now: Date, date: Date): string
    local ranges = {
        {0, 6, i18n("today")},
        {7, 24, i18n("yesterday")},
        {25, 48, i18n("twoDays")},
        {49, 72, i18n("threeDays")},
        {73, 96, i18n("fourDays")},
        {97, 24 * 7, i18n("lastWeek")},
        {24 * 7 + 1, 24 * 14, i18n("lastTwoWeek")},
        {24 * 14 + 1, 24 * 30, i18n("lastMonth")},
        {24 * 30 + 1, 24 * 365, i18n("lastYear")},
    }
    local result = i18n("moreTime")
    --print("now", inspect(os.date("*t")))
    --print("date", inspect(date))
    local t1, t2, diff = now.yday * 24 + now.hour, date.yday * 24 + date.hour, 0
    if date.year == now.year then
        diff = t1 - t2
    else
        diff = (now.year - date.year) * 365 * 24 - (t1 - t2)
    end
    for _, v in ipairs(ranges) do
        local v1, v2 = v[1], v[2]
        if diff >= v1 and diff <= v2 then
            result = v[3]
            break
        end
    end
    --print(result)
    return result
end

function getDefaultSettings(): Settings
    print("getDefaultSettings")
    return {
        volume = 0.2,
        firstRun = true,
    }
end

-- XXX Может быть сломано
function readSettings(): Settings
    local data, _ = love.filesystem.read(SETTINGS_FILENAME)
    local result: Settings

    if data then
        local ok, func = serpent.load(data)
        if not ok then
            result = getDefaultSettings()
        else
            result = func() as Settings
        end
    else
        result = getDefaultSettings()
    end

    return result
end

function writeSettings()
    local serialized = serpent.dump(settings)
    local ok, msg = love.filesystem.write(SETTINGS_FILENAME, serialized)
    if not ok then
        print("Could write settings to ", SETTINGS_FILENAME, " file", msg)
    end
end

function isPositionEqual(a: Signals.Pos, b: Signals.Pos): boolean
    return a.x == a.y and b.x == b.y
end

