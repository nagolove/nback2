require "love"
require "common"
require "snippets"
--require "vector"
local vec = require "vector"
local gr = love.graphics
--local vec2 = require "vector-light"

function getHexPolygonWidth(hex: {number}): number
    return dist(hex[3], hex[4], hex[11], hex[12])
end

function getHexPolygonHeight(hex: {number}): number
    return dist(hex[1], hex[2], hex[7], hex[8])
end

global record Hex 
    -- массив вершин
    {number}
    -- центр шестиугольника
    cx: number
    cy: number
    endindex: number
    mesh: love.graphics.Mesh
    rad: number
    selected: boolean
    i: number
    j: number
end

local Hex_mt: metatable<Hex> = {
    __index = Hex
}

function Hex:getVertices(): {number}
    local vertices = {}
    for i = 1, 6 do
        table.insert(vertices, self[i])
    end
    return vertices
end

-- [[
-- return {x1, y1, x2, y2 }, w * 2, h * 2
-- ]]
function Hex:getAABB(): {number}, number, number
    local w, h = getHexPolygonWidth(self) / 2, getHexPolygonHeight(self) / 2
    return {self.cx - w, self.cy - h, self.cx + w, self.cx + h}, w * 2, h * 2
end

function Hex:getDebugCanvas(): love.graphics.Canvas
    --local polyW = getHexPolygonWidth(self)
    --local canvas = gr.newCanvas(getHexPolygonWidth(self), 
        --getHexPolygonHeight(self))
    local t, w, h = self:getAABB()
    --local screenW, screenH = gr.getDimensions()
    --[[
       [local snap = 30
       [t[1] = t[1] - snap
       [t[2] = t[2] - snap
       [t[3] = t[3] + snap
       [t[4] = t[4] + snap
       ]]
    local canvas = gr.newCanvas(gr.getDimensions())
    --local canvas = gr.newCanvas(w, h)

    gr.setCanvas(canvas)
    gr.clear(0, 0, 1)

    gr.push()
    --gr.scale(polyW / screenW, polyW / screenW)

    local vi = 1
    for i = 1, #self - 2, 2 do
        gr.setColor{1, 1, 1, 1}
        gr.print(string.format("(%d)", vi), self[i], self[i+1])
        vi = vi + 1
    end
    gr.line(t[1], t[2], t[3], t[4])
    gr.setColor{1, 0, 0}
    gr.rectangle("line", t[1], t[2], w, h)

    gr.pop()
    gr.setCanvas()

    return canvas
end

function Hex:setMesh(mesh: love.graphics.Mesh, endindex: number)
    self.mesh = mesh
    self.endindex = endindex
end

function Hex:setVertexColor(index: number, _: {number})
    local vertex = {self.mesh:getVertex(self.endindex - index + 0)}
    -- XXX цвет не выставляется
    --print("vertex", inspect(vertex))
    self.mesh:setVertex(self.endindex - index + 0, vertex)
end

function Hex:setColor(color: {number})
    for i = 1, 6 do
        self:setVertexColor(i, color)
    end
end

local function newHexPolygon(cx: number, cy: number, rad: number): Hex
    local hex = setmetatable({} as Hex, Hex_mt)

    local d = math.pi * 2 / 6
    local c = 0
    for i = 1, 7 do
        local x, y = cx + math.sin(c) * rad, cy + math.cos(c) * rad
        table.insert(hex, x)
        table.insert(hex, y)
        c = c + d
    end

    hex.rad = rad
    hex.selected = false
    hex.cx, hex.cy = cx, cy

    return hex
end

function addVertex(array: {{number}}, x: number, y: number, color: {number}): number
    table.insert(array, {
        math.floor(x), math.floor(y),
        0, 0, -- u v
        color[1], color[2], color[3], color[4]
    })
    return #array
end

function addHex(data: {{number}}, hex: Hex, color: {number}): number
    addVertex(data, hex.cx, hex.cy, color)
    addVertex(data, hex[1], hex[2], color)
    addVertex(data, hex[3], hex[4], color)

    addVertex(data, hex.cx, hex.cy, color)
    addVertex(data, hex[3], hex[4], color)
    addVertex(data, hex[5], hex[6], color)

    addVertex(data, hex.cx, hex.cy, color)
    addVertex(data, hex[5], hex[6], color)
    addVertex(data, hex[7], hex[8], color)

    addVertex(data, hex.cx, hex.cy, color)
    addVertex(data, hex[7], hex[8], color)
    addVertex(data, hex[9], hex[10], color)

    addVertex(data, hex.cx, hex.cy, color)
    addVertex(data, hex[9], hex[10], color)
    addVertex(data, hex[11], hex[12], color)

    addVertex(data, hex.cx, hex.cy, color)
    addVertex(data, hex[11], hex[12], color)
    return addVertex(data, hex[1], hex[2], color)
end

function addVertex2(array: {{number}}, x: number, y: number)
    table.insert(array, {
        math.floor(x), math.floor(y),
        --math.floor(x), math.floor(y),
        0, 0, -- u v
        1, 1, 1, 1,
    })
end

-- добавляет линию из пары треугольников и шести вершин
function addLine(array: {{number}}, x1: number, y1: number, x2: number, y2: number)
    --TODO Оптимизировать вектора
    local len = dist(x1, y1, x2, y2)
    --local dirx, diry = vec(x2 - x1) / len, vec(y2 - y1) / len
    local dir1, dir2: vector, vector = vec.new(x2 - x1, y2 - y1) / len, vec.new(x1 - x2, y1 - y2) / len

    local width = 3
    local p1 = vec(x1, y1) + dir1:perpendicular() * width
    local p2 = vec(x1, y1) + dir2:perpendicular() * width
    local p3 = vec(x2, y2) + dir1:perpendicular() * width
    local p4 = vec(x2, y2) + dir2:perpendicular() * width

    addVertex2(array, p1.x, p1.y)
    addVertex2(array, p2.x, p2.y)
    addVertex2(array, p3.x, p3.y)

    addVertex2(array, p4.x, p4.y)
    addVertex2(array, p3.x, p3.y)
    addVertex2(array, p2.x, p2.y)
end

function addBorder(data: {{number}}, hex: Hex)
    addLine(data, hex[1], hex[2], hex[3], hex[4])
    addLine(data, hex[3], hex[4], hex[5], hex[6])
    addLine(data, hex[5], hex[6], hex[7], hex[8])
    addLine(data, hex[7], hex[8], hex[9], hex[10])
    addLine(data, hex[9], hex[10], hex[11], hex[12])
    addLine(data, hex[11], hex[12], hex[1], hex[2])
end

global record HexField
    map:{{number}}
    __index: metatable<HexField>

    get: function(HexField, number, number): number
end

-- map - 2d array
local function newHexField(startcx: number, startcy: number, map: {{number}},rad: number, color: {number}): HexField, love.graphics.Mesh
    --print(inspect(map))
    --print(#map)
    local xcount = #map
    local ycount = #map[1]
    assert(xcount == ycount)

    local Handler: HexField = {
        map = {}
    }
    Handler.__index = Handler as metatable<HexField>

    for k, v in ipairs(map) do
        Handler.map[k] = {}
        for _, v2 in ipairs(v) do
            table.insert(Handler.map[k], v2)
        end
    end

    function Handler:get(x: number, y: number): number
        return Handler.map[x][y] or nil
    end

    local result: HexField = {}
    setmetatable(result, Handler as metatable<HexField>)

    local mesh = gr.newMesh((6 * 3 + 6 * 6) * xcount * ycount, "triangles", "dynamic")
    local meshData = {}

    local cx, cy = startcx, startcy
    local hasWH = false
    local w, h: number, number

    local prevHorizon = nil
    local horizon = {}

    for j = 1, ycount do
        for i = 1, xcount do
            local last = newHexPolygon(cx, cy, rad)
            last.j = j
            last.i = i

            --table.insert(result, last)
            
            local visible = map[j][i] ~= 0 

            if visible then
                Handler.map[j][i] = last
                last.mapIndex = {j, i}
                table.insert(horizon, last)
            end

            --[[ 
            [1] left 
            [2] lt
            [3] rt 
            [4] right 
            [5] rb 
            [6] lb ]]
            last.refs = {} 

            if not hasWH then
                w, h = getHexPolygonWidth(last), getHexPolygonHeight(last)
            end

            local lastIndex
            if visible then
                lastIndex = addHex(meshData, last, color)
                addBorder(meshData, last)
                last:setMesh(mesh, lastIndex)
            end

            cx = cx + w
        end

        for k, v in pairs(horizon) do
            table.insert(result, v)
        end
        prevHorizon = horizon
        horizon = {}

        cy = cy + h * 3 / 4
        cx = j % 2 == 1 and startcx + w / 2 or startcx
    end
    
    --updateNeighbors(result, xcount, ycount)
    
    mesh:setVertices(meshData)

    --print("result", inspect(result))
    return result, mesh
end

return {
    newHexField = newHexField,
    newHexPolygon = newHexPolygon,
}

