local lg = love.graphics

local inspect = require "libs.inspect"
--[[local ok, _  = pcall(function() inspect = require "inspect" end)]]
--[[if not ok then inspect = function() return "" end end]]

local Layout = {}
Layout.__index = Layout

function makeScreenTable()
    return {x = 0, y = 0, w = lg.getWidth(), h = lg.getHeight()}
end

function assertHelper(tbl)
    assert(tbl.x and tbl.y and tbl.w and tbl.h, 
        "not all fields are correct " .. inspect(tbl))
end

function checkHelper(tbl)
    return tbl.x and tbl.y and tbl.w and tbl.h
end

function Layout:new(x, y, w, h)
    local self
    if not x and not y and not w and not h then
        self = makeScreenTable()
    else
        self = {x = x, y = y, w = w, h = h}
    end
    if type(x) == "table" then
        assertHelper(x)
        local tbl = x
        self = {x = tbl.x, y = tbl.y, w = tbl.w, h = tbl.h}
    end
    return setmetatable(self, Layout)
end

function assertVariadic(...)
    local sum = 0
    for i = 1, select("#", ...) do
        sum = sum + select(i, ...)
    end
    assert(math.abs(sum - 1) < 0.01)
end

function splith(tbl, ...)
    assertVariadic(...)
    assertHelper(tbl)
    local subTbls = {}
    local lasty = tbl.y
    for i = 1, select("#", ...) do
        local currenth = tbl.h * select(i, ...)
        table.insert(subTbls, { x = tbl.x, y = lasty, w = tbl.w, h = currenth})
        lasty = lasty + currenth
    end
    return unpack(subTbls)
end

function assertAlign(alignMode)
    assert(type(alignMode) == "string")
    assert(alignMode == "left" or alignMode == "right" 
        or alignMode == "center")
end

function splitv(tbl, ...)
    assertVariadic(...)
    assertHelper(tbl)
    local subTbls = {}
    local lastx = tbl.x
    for i = 1, select("#", ...) do
        local currentw = tbl.w * select(i, ...)
        table.insert(subTbls, { x = lastx, y = tbl.y, w = currentw, h = tbl.h})
        lastx = lastx + currentw            
    end
    return unpack(subTbls)
end

function splitvAlign(tbl, alignMode, ...)
    assert(false, "Not yet implemented")
    assertHelper(tbl)
    assertAlign(alignMode)
    local subTbls = {}
    for i = 1, select("#", ...) do
    end
end

function splithByNum(tbl, piecesNum)
    assertHelper(tbl)
    local subTbls = {}
    local prevy, h = tbl.y, tbl.h / piecesNum
    for i = 1, piecesNum do
        table.insert(subTbls, {x = tbl.x, y = prevy, w = tbl.w, h = h})
        prevy = prevy + h
    end
    return unpack(subTbls)
end

function splitvByNum(tbl, piecesNum)
    assertHelper(tbl)
    local subTbls = {}
    local prevx, w = tbl.x, tbl.w / piecesNum
    for i = 1, piecesNum do
        table.insert(subTbls, {x = prevx, y = tbl.y, w = w, h = tbl.h})
        prevx = prevx + w
    end
    return unpack(subTbls)
end

function areaGrowByPixel(tbl, delta)
    assertHelper(tbl)
    assert(type(delta) == "number")
    return { x = tbl.x + delta, y = tbl.y + delta, 
        w = tbl.w - delta * 2, h = tbl.h - delta * 2}
end

-- рисовать переданные таблички. Последним аргументов может идти специальная
-- табличка с цветом.
function drawHelper(...)
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
            for k, v in pairs(tbl) do
                if checkHelper(v) then
                    drawHelper(v)
                end
            end
        end
    end
end

function drawHierachy(rootTbl)
    print("drawHierachy", inspect(rootTbl), inspect(color))
    if checkHelper(rootTbl) then
        drawHelper(rootTbl)
    end
    for k, v in pairs(rootTbl) do
        if type(v) == "table" and checkHelper(v) then
            drawHierachy(v)
        end
    end
end

function layoutExample()
    local t = areaGrowByPixel(splitv(makeScreenTable(), 1), 10)
    local t1, t2 = splitv(t, 0.5, 0.5)
    local arr = {splitvByNum(t1, 4)}
    local arr2 = {splithByNum(arr[1], 3)}
    local arr3 = {splitv(t2, 0.3, 0.7)}
    local arr4 = {splith(arr3[2], 0.1, 0.7, 0.2)}
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

