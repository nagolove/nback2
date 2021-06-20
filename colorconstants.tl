--local type ConstantsTable = {string: {number}} 
----local constans_mt: metatable<ConstantsTable> = { 
----}
--local constans_mt = {}

----constans.__index = constans

----function constans_mt:makeNamesArray(): {string}
--function constans_mt:makeNamesArray(): {string}
    --local color_arr: {string} = {}
    --for k, _ in pairs(self as {any:any}) do
        --color_arr[#color_arr + 1] = k as string
    --end
    --return color_arr
--end

--local function new(): ConstantsTable
    --return setmetatable({
        --["brown"] = {136 / 255, 55 / 255, 41 / 255},
        --["green"] = {72 / 255, 180 / 255, 66 / 255},
        --["blue"] = {27 / 255, 30 / 255, 249 / 255},
        --["red"] = {241 / 255, 30 / 255, 27 / 255},
        --["yellow"] = {231 / 255, 227 / 255, 11 / 255},
        --["purple"] = {128 / 255, 7 / 255, 128 / 255}, } as ConstantsTable, constans_mt as metatable<ConstantsTable>)
--end

-- TODO Расширить палитру парами дополненных цветов
local colors: {string:{number}} = {
        -- отладочные цвета
        ["black"] = {136 / 255, 55 / 255, 41 / 255},
        ["white"] = {136 / 255, 55 / 255, 41 / 255},

        -- основные цвета
        ["brown"] = {136 / 255, 55 / 255, 41 / 255},
        ["green"] = {72 / 255, 180 / 255, 66 / 255},
        ["blue"] = {27 / 255, 30 / 255, 249 / 255},
        ["red"] = {241 / 255, 30 / 255, 27 / 255},
        ["yellow"] = {231 / 255, 227 / 255, 11 / 255},
        ["purple"] = {128 / 255, 7 / 255, 128 / 255}, 
} 

local function makeNamesArray(): {string}
    local color_arr: {string} = {}
    for k, _ in pairs(colors) do
        color_arr[#color_arr + 1] = k
    end
    return color_arr
end

return {
    colors = colors,
    makeNamesArray = makeNamesArray,
}


