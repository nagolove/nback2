require "love"
local lg = love.graphics

local inspect = require "inspect"
--[[local ok, _  = pcall(function() inspect = require "inspect" end)]]
--[[if not ok then inspect = function() return "" end end]]

global type Layout = record
    enum AlignMode
        "left"
        "right"
        "center"
    end
    x: integer
    y: integer
    w: integer
    h: integer

    top: Layout
    bottom: Layout
    middle: Layout
    left: Layout
    right: Layout
    leftTop: Layout
    leftMiddle: Layout
    leftBottom: Layout
    rightTop: Layout
    rightMiddle: Layout
    rightBottom: Layout
    center: Layout

    new: function(x: number|Layout, y: number, w: number, h: number): Layout
end

local Layout_mt: metatable<Layout> = {
    __index = Layout
}

function makeScreenTable(): Layout
    return {x = 0, y = 0, w = lg.getWidth(), h = lg.getHeight()}
end

function assertHelper(tbl: Layout)
    assert(tbl.x and tbl.y and tbl.w and tbl.h, 
        "not all fields are correct " .. inspect(tbl))
end

-- возвращает истину если поля переданной таблички соответствуют Layout
function checkHelper(tbl: Layout): boolean
    return (tbl.x and tbl.y and tbl.w and tbl.h) ~= nil
end

function Layout.new(x: integer|Layout, y: integer, w: integer, h: integer): Layout
    local self: Layout
    if not x and not y and not w and not h then
        self = makeScreenTable()
    else
        self = {x = x as integer, y = y, w = w, h = h}
    end
    if type(x) == "table" then
        assertHelper(x as Layout)
        local tbl: Layout = x as Layout
        self = {x = tbl.x, y = tbl.y, w = tbl.w, h = tbl.h}
    end
    return setmetatable(self, Layout_mt)
end

function assertVariadic(...: number)
    local sum = 0.
    for i = 1, select("#", ...) do
        sum = sum + select(i, ...)
    end
    assert(math.abs(sum - 1) < 0.01)
end

-- функция возвращает переменное количество параметров
function splith(tbl: Layout, ...: number): Layout...
    assertVariadic(...)
    assertHelper(tbl)
    local subTbls = {}
    local lasty = tbl.y
    for i = 1, select("#", ...) do
        local currenth: integer = tbl.h * math.floor(select(i, ...))
        table.insert(subTbls, { x = tbl.x, y = lasty, w = tbl.w, h = currenth})
        lasty = lasty + currenth
    end
    return table.unpack(subTbls)
end

function assertAlign(alignMode: Layout.AlignMode)
    assert(type(alignMode) == "string")
    assert(alignMode == "left" or alignMode == "right" 
        or alignMode == "center")
end

function splitv(tbl: Layout, ...: number): Layout...
    assertVariadic(...)
    assertHelper(tbl)
    local subTbls = {}
    local lastx = tbl.x
    for i = 1, select("#", ...) do
        local currentw = tbl.w * math.floor(select(i, ...))
        table.insert(subTbls, { x = lastx, y = tbl.y, w = currentw, h = tbl.h})
        lastx = lastx + currentw            
    end
    return table.unpack(subTbls)
end

--function splitvAlign(tbl: Layout, alignMode: Layout.AlignMode, ...: number): Layout...
function splitvAlign(tbl: Layout, alignMode: Layout.AlignMode): Layout...
    assert(false, "Not yet implemented")
    assertHelper(tbl)
    assertAlign(alignMode)
    --local subTbls = {}
    --for i = 1, select("#", ...) do
    --end
    assert(false, "Not implemented")
end

function splithByNum(tbl: Layout, piecesNum: integer): Layout...
    assertHelper(tbl)
    local subTbls = {}
    local prevy, h = tbl.y, tbl.h // piecesNum
    for _ = 1, piecesNum do
        table.insert(subTbls, {x = tbl.x, y = prevy, w = tbl.w, h = h})
        prevy = prevy + h
    end
    return table.unpack(subTbls)
end

function splitvByNum(tbl: Layout, piecesNum: integer): Layout...
    assertHelper(tbl)
    local subTbls = {}
    local prevx, w = tbl.x, tbl.w // piecesNum
    for _ = 1, piecesNum do
        table.insert(subTbls, {x = prevx, y = tbl.y, w = w, h = tbl.h})
        prevx = prevx + w
    end
    return table.unpack(subTbls)
end

function shrink(tbl: Layout, value: number): Layout
    assertHelper(tbl)
    assert(type(value) == "number", string.format("number expected, but %s is", type(value)))
    return { x = tbl.x + value, y = tbl.y + value, 
        w = tbl.w - value * 2, h = tbl.h - value * 2}
end

function areaGrowByPixel(tbl: Layout, delta: number): Layout
    assertHelper(tbl)
    assert(type(delta) == "number")
    return { x = tbl.x + delta, y = tbl.y + delta, 
        w = tbl.w - delta * 2, h = tbl.h - delta * 2}
end

-- рисовать переданные таблички. Последним аргументов может идти специальная
-- табличка с цветом.
function drawHelper(...: Layout)
    --[[local hasColor = 0]]
    --[[local lastArg = select(select("#", ...), ...)]]
    --[[local color = {1, 0, 1}]]
    --[[if type(lastArg) == "table" and type(lastArg[1]) == "number" and ]]
       --[[type(lastArg[2]) == "number" and type(lastArg[3]) == "number" then]]
        --[[hasColor = 1]]
        --[[color = {lastArg[1], lastArg[2], lastArg[3]}]]
        --[[if type(lastArg[4]) == "number" then]]
            --[[color[4] = lastArg[4]]
        --[[end]]
    --[[end]]

    --[[if not __ONCE__ then]]
        --[[print("hasColor", hasColor)]]
        --[[print("color", inspect(color))]]
        --[[print("lastArg", inspect(lastArg))]]
        --[[print("drawHelper", inspect(...))]]
        --[[__ONCE__ = true]]
    --[[end]]

    --[[for i = 1, select("#", ...) - hasColor do]]
    for i = 1, select("#", ...) do
        local tbl = select(i, ...)
        --[[print("i", i)]]
        --[[print("tbl", inspect(tbl))]]
        assertHelper(tbl)
        if checkHelper(tbl) then
            --[[lg.setColor{1, 0, 1}]]
            lg.rectangle("line", tbl.x, tbl.y, tbl.w, tbl.h)
            --[[lg.setColor{1, 0, 1, 0.5}]]
            lg.rectangle("line", tbl.x + 1, tbl.y + 1, tbl.w - 1, tbl.h - 1)
        elseif type(tbl) == "table" then
            -- что делает этот код внутри цикла?
            -- ищет подтаблицы
            for _, v in pairs(tbl as {any: any}) do
                if checkHelper(v as Layout) then
                    drawHelper(v)
                end
            end
        end
    end
end

function drawHierachy(rootTbl: Layout)
    --print("drawHierachy", inspect(rootTbl), inspect(color))
    if checkHelper(rootTbl) then
        drawHelper(rootTbl)
    end
    for _, v in pairs(rootTbl as {any:any}) do
        if type(v) == "table" and checkHelper(v as Layout) then
            drawHierachy(v as Layout)
        end
    end
end

-- XXX Сломана проверка типов
--[[
function layoutExample()
    local t = areaGrowByPixel(splitv(makeScreenTable(), 1), 10)
    local t1, t2 = splitv(t, 0.5, 0.5)
    local arr = {splitvByNum(t1, 4)} as Layout
    local arr2 = {splithByNum(arr[1], 3)} as Layout
    local arr3 = {splitv(t2, 0.3, 0.7)} as Layout
    local arr4 = {splith(arr3[2], 0.1, 0.7, 0.2)} as Layout
    print("arr3", inspect(arr3))
    arr2[1] = areaGrowByPixel(arr2[1], 10)
    arr[4] = areaGrowByPixel(arr[4], 20)

    local drawList = {}
    table.insert(drawList, function()
        drawHelper(t1)
        drawHelper(t2)
        drawHelper(arr)
        drawHelper(arr2)
        drawHelper(arr3)
        drawHelper(arr4)
        drawHelper(t)
    end)
    return drawList
end
--]]

