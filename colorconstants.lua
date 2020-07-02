local constans = {}
constans.__index = constans

function constans:makeNamesArray()
    local color_arr = {}
    for k, _ in pairs(self) do
        color_arr[#color_arr + 1] = k
    end
    return color_arr
end

local function new() 
    return setmetatable({
        ["brown"] = {136 / 255, 55 / 255, 41 / 255},
        ["green"] = {72 / 255, 180 / 255, 66 / 255},
        ["blue"] = {27 / 255, 30 / 255, 249 / 255},
        ["red"] = {241 / 255, 30 / 255, 27 / 255},
        ["yellow"] = {231 / 255, 227 / 255, 11 / 255},
        ["purple"] = {128 / 255, 7 / 255, 128 / 255}, }, constans)
end

if not ... then
    local inspect = require "libs.inspect"
    --print("new()", inspect(new()))
    --print("new():makeIndexArray()", inspect(new():makeNamesArray()))
    local c = new()
    --print(inspect(c["brown"]))
    local a = c:makeNamesArray()
    print(inspect(a[1]))
    print(inspect(c[a[1]]))
end

return new()

