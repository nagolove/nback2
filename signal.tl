require "love"
require "hex"
require "vector"

--local g = love.graphics

--[[
Что делает этот класс?
--]]
--[[
global type SignalView = record
    new: function(Hex, number, number, any, number, string): SignalView
    setCorner: function(SignalView, number, number)
    resize: function(SignalView, number, number)
    draw2Canvas: function(SignalView, integer)
    drawFigures2Canvas: function(SignalView)
    draw: function(SignalView, number, number, string, {number})

    circleImage: love.graphics.Texture
    imageQuad: love.graphics.Quad
    iCount: number
    hexfield: Hex
    startcx: number
    startcy: number
    map: any
    width: number
    sounds: {love.audio.Source}
    canvas: love.graphics.Canvas
    borderColor: {number}
    borderLineWidth: number
    x0: number
    y0: number
    canvases: {love.graphics.Canvas}
end

local SignalView_mt: metatable<SignalView> = {
    __index = SignalView
}

local enum Types
    "quad"
    "circle"
    "rhombus"
    "trup"
    "trdown"
    "trupdown"
end

-- Типы сигналов и их порядок в канвасах слева на право:
-- quad, circle, rhombus, trup, trdown, trupdown
local types: {string} = {"quad", "circle", "rhombus", "trup", "trdown", "trupdown"}

-- параметры - hump.vector
-- источник: https://users.livejournal.com/-winnie/152327.html
local function intersection(start1: vector, end1: vector, start2: vector, end2: vector): vector
    assert(vector.isvector(start1) and vector.isvector(end1) and
        vector.isvector(start2) and vector.isvector(end2))

    local dir1 = end1 - start1;
    local dir2 = end2 - start2;

    --считаем уравнения прямых проходящих через отрезки
    local a1 = -dir1.y;
    local b1 = dir1.x;
    local d1 = -(a1*start1.x + b1*start1.y);

    local a2 = -dir2.y;
    local b2 = dir2.x;
    local d2 = -(a2*start2.x + b2*start2.y);

    --подставляем концы отрезков, для выяснения в каких полуплоскотях они
    local seg1_line2_start = a2 * start1.x + b2 * start1.y + d2;
    local seg1_line2_end = a2 * end1.x + b2 * end1.y + d2;

    local seg2_line1_start = a1 * start2.x + b1 * start2.y + d1;
    local seg2_line1_end = a1 * end2.x + b1 * end2.y + d1;

    --если концы одного отрезка имеют один знак, значит он в одной полуплоскости и пересечения нет.
    if (seg1_line2_start * seg1_line2_end >= 0 or 
        seg2_line1_start * seg2_line1_end >= 0) then
        return nil
    end

    local u = seg1_line2_start / (seg1_line2_start - seg1_line2_end);

    return start1 + u*dir1;
end


-- width - ширина ячейки для фигурки
-- soundPack - имя подкаталога в 'sfx' с набором звуков
function SignalView.new(hexfield: H, startcx: number, startcy: number, map: {{number}}, cell_width: number, soundPack: string): SignalView
    local circleImage = g.newImage("circle.png") as love.graphics.Texture
    local width = hexfield[1].rad
    local self: SignalView = {
        circleImage = circleImage,
        imageQuad = g.newQuad(0, 0, width, width, 
            circleImage:getWidth(), circleImage:getHeight()),
        iCount = 10,
        hexfield = hexfield, 
        startcx = startcx,
        startcy = startcy,
        map = map,
        width = width,
        sounds = {}, 
        canvas = nil,
        borderColor = {0, 0, 0},
        borderLineWidth = 3,
    }

    local wavePath = "sfx/" .. soundPack
    for _, v in ipairs(love.filesystem.getDirectoryItems(wavePath)) do
        table.insert(self.sounds, love.audio.newSource(wavePath .. "/" .. v, 
            "static"))
    end

    self = setmetatable(self, SignalView_mt)

    --self:exampleFilling()

    self:setCorner(0, 0)
    self:resize(self.width)
    return self
end
--]]

--[[
function signal:exampleFilling()
    local exampleHex = self.hexfield[1]
    self.exampleCanvas = g.newCanvas(g.getDimensions())

    local x1, y1 = exampleHex[11], exampleHex[12]
    local x2, y2 = exampleHex[5], exampleHex[6]
    local dup_x1, dup_y1, dup_x2, dup_y2 = x1, y1, x2, y2
    local snap = 10

    local prevWidth = g.getLineWidth()
    g.setCanvas({self.exampleCanvas, stencil=true})

    g.stencil(function()
        g.polygon("fill", exampleHex)
    end, "invert", 1)

    g.setStencilTest("greater", 1)

    for i = 1, 10 do
        g.line(dup_x1, dup_y1, dup_x2, dup_y2)
        dup_x1, dup_y1 = dup_x1 - snap, dup_y1 - snap
        dup_x2, dup_y2 = dup_x2 - snap, dup_y2 - snap

        g.line(x1, y1, x2, y2)
        x1, y1 = x1 + snap, y1 + snap
        x2, y2 = x2 + snap, y2 + snap
    end

    x1, y1, x2, y2 = exampleHex[3], exampleHex[4], exampleHex[9], exampleHex[10]
    dup_x1, dup_y1, dup_x2, dup_y2 = x1, y1, x2, y2

    for i = 1, 10 do
        g.line(dup_x1, dup_y1, dup_x2, dup_y2)
        dup_x1, dup_y1 = dup_x1 + snap, dup_y1 - snap
        dup_x2, dup_y2 = dup_x2 + snap, dup_y2 - snap

        g.line(x1, y1, x2, y2)
        x1, y1 = x1 - snap, y1 + snap
        x2, y2 = x2 - snap, y2 + snap
    end

    g.setStencilTest()
    g.setCanvas()
    g.setLineWidth(prevWidth)
end
--]]

-- установить координаты левого верхнего угла, от которого идет отсчет ячеек.
-- обязательно вызывать перед рисовкой.
--[[
function SignalView:setCorner(x: number, y: number)
    self.x0, self.y0 = x, y
end

function SignalView:resize(width: number)
    self.width = width

    self.canvas = g.newCanvas(width, width * 6, {msaa = 2})
    self.canvases = {}
    for i = 1, 6 do
        table.insert(self.canvases, g.newCanvas(width, width, {msaa = 2}))
    end

    self:drawFigures2Canvas()
end

function SignalView:draw2Canvas(index: integer)
    --local xd, yd = 1, 1
    --local border = 5
    --local w, h = self.width - border * 2, self.width - border * 2
    --local x = self.x0 + xd * self.width + border 
    --local y = self.y0 + yd * self.width + border

    g.setColor{1, 1, 1}
    g.setCanvas(self.canvases[index])
    local funcName: string = types[index] 
    --(self as {string:function})[funcName](self, 0, 0, w, h)
    --(self as {string:function})["wf"](self, 0, 0, w, h)
    --(self as {string:function()})["wf"]()
    self[funcName as Types](self, 0, 0, w, h)
    g.setCanvas()

    self.canvases[index]:newImageData():encode("png", "signals/" .. funcName .. ".png")
end

function SignalView:drawFigures2Canvas()
    love.filesystem.createDirectory("signals")
    for k, _ in ipairs(types) do
        self:draw2Canvas(k)
    end
end

-- xd, yd - целочисленная позиция фигуры в матрице.
-- type - тип рисуемой картинки(квадрат, круг, треугольник вниз, 
-- треугольник вверх, пересечение треугольников, ромб)
-- color - текущий цвет
function SignalView:draw(xd: number, yd: number, type_: string, color: {number})

    local currentHex = self.hexfield:get(xd, yd)

    local border = 1
    local w, h = self.width - border * 2, self.width - border * 2
    --local x = self.x0 + xd * self.width + border 
    --local y = self.y0 + yd * self.width + border

    self.borderColor[4] = color[4] -- анимирую альфа-канал цвета рамки
    g.setColor(color)
    local oldWidth = g.getLineWidth()
    g.setLineWidth(self.borderLineWidth)

    if currentHex and type(currentHex) == "table" then

        --g.setShader(fragmentCode)
        --safesend(fragmentCode, "iTime", love.timer.getTime())
        --safesend(fragmentCode, "iCount", self.iCount)

        --local rad = math.floor(getHexPolygonWidth(self.hexfield[1]) / 2)

        --g.setShader()

        local idx = 0
        for k, v in ipairs(types) do
            if v == type_ then
                idx = k
                break
            end
        end

        local x, y: number, number = currentHex.cx - w / 2, currentHex.cy - h / 2
        g.draw(self.canvases[idx] as love.graphics.Drawable, x, y)
    end

    g.setLineWidth(oldWidth)

    g.setColor{1, 1, 1}
    --g.draw(self.exampleCanvas, 0, 0)

end

-- хорошая идея добавить проигрывание звука, но как ориентироваться в
-- сэмплах? На стадии создания сигнала загрузить набор сэмплов и
-- ориентироваться по их номерам? Тогда нужно предоставить пользователю
-- сигнала диапазон возможных значений номеров сэмпла 1..samplesCount
function SignalView:play(index: number)
    assert(index <= #self.sounds)
    --self.sounds[index]:play()
end

function SignalView:quad(x: number, y: number, w: number, h: number)
    local delta = 5
    g.rectangle("fill", x + delta, y + delta, w - delta * 2, h - delta * 2)
    g.setColor(self.borderColor)
    g.rectangle("line", x + delta, y + delta, w - delta * 2, h - delta * 2)
end

function SignalView:circle(x: number, y: number, w: number, h: number)
    g.circle("fill", x + w / 2, y + h / 2, w / 2.3)
    g.setColor(self.borderColor)
    g.circle("line", x + w / 2, y + h / 2, w / 2.3)
end

function SignalView:trdown(x: number, y: number, w: number, h: number)
    local magic = 2.64
    local tri = {}
    local rad = w / 2
    for i = 1, 3 do
        local alpha = 2 * math.pi * i / 3
        local sx = x + w / 2 + rad * math.sin(alpha)
        local sy = y + h / magic + rad * math.cos(alpha)
        tri[#tri + 1] = sx
        tri[#tri + 1] = sy
    end
    g.polygon("fill", tri)
    g.setColor(self.borderColor)
    g.polygon("line", tri)
end

function SignalView:trup(x: number, y: number, w: number, h: number)
    local magic = 1.64
    local tri = {}
    local rad = w / 2
    for i = 1, 3 do
        local alpha = math.pi + 2 * math.pi * i / 3
        local sx = x + w / 2 + rad * math.sin(alpha)
        local sy = y + h / magic + rad * math.cos(alpha)
        tri[#tri + 1] = sx
        tri[#tri + 1] = sy
    end
    g.polygon("fill", tri)
    g.setColor(self.borderColor)
    g.polygon("line", tri)
end

-- функция расчитывает и возвращает шесть точек пересечения между линиями
-- двух треугольников. up, down - координаты точек треугольника вершинами
-- вверх и вершинами вниз соответственно. Вершины лежат в массиве плоско.
function SignalView:calculateIntersections(up: {number}, down: {number}): {number}
    local points: {number} = {}
    local p: vector

    -- 1
    p = intersection(vector(up[5], up[6]), vector(up[1], up[2]),
        vector(down[5], down[6]), vector(down[3], down[4]))
    points[#points + 1] = p.x
    points[#points + 1] = p.y

    -- 2
    p = intersection(vector(up[5], up[6]), vector(up[1], up[2]),
        vector(down[3], down[4]), vector(down[1], down[2]))
    points[#points + 1] = p.x
    points[#points + 1] = p.y

    -- 3
    p = intersection(vector(up[3], up[4]), vector(up[5], up[6]),
        vector(down[3], down[4]), vector(down[1], down[2]))
    points[#points + 1] = p.x
    points[#points + 1] = p.y

    -- 4
    p = intersection(vector(up[3], up[4]), vector(up[5], up[6]),
        vector(down[1], down[2]), vector(down[5], down[6]))
    points[#points + 1] = p.x
    points[#points + 1] = p.y

    -- 5
    p = intersection(vector(up[3], up[4]), vector(up[1], up[2]),
        vector(down[1], down[2]), vector(down[5], down[6]))
    points[#points + 1] = p.x
    points[#points + 1] = p.y

    -- 6
    p = intersection(vector(up[3], up[4]), vector(up[1], up[2]),
        vector(down[3], down[4]), vector(down[5], down[6]))
    points[#points + 1] = p.x
    points[#points + 1] = p.y

    return points
end

function SignalView:trupdown(_: number, _: number, w: number, h: number)
    local tri_up, tri_down = {}, {}
    local rad = w / 2
    for i = 1, 3 do
        local alpha = 2 * math.pi * i / 3
        local sx = w / 2 + rad * math.sin(alpha)
        local sy = h / 2 + rad * math.cos(alpha)
        tri_up[#tri_up + 1] = sx
        tri_up[#tri_up + 1] = sy

        alpha = math.pi + 2 * math.pi * i / 3
        sx = w / 2 + rad * math.sin(alpha)
        sy = h / 2 + rad * math.cos(alpha)

        tri_down[#tri_down + 1] = sx
        tri_down[#tri_down + 1] = sy
    end

    g.polygon("fill", tri_up)
    g.polygon("fill", tri_down)

    local points = self:calculateIntersections(tri_up, tri_down)

    local borderVertices = {
        tri_up[1], tri_up[2],
        points[1], points[2],
        tri_down[3], tri_down[4],
        points[3], points[4],
        tri_up[5], tri_up[6],
        points[5], points[6],
        tri_down[1], tri_down[2],
        points[7], points[8],
        tri_up[3], tri_up[4],
        points[9], points[10],
        tri_down[5], tri_down[6],
        points[11], points[12],
        tri_up[1], tri_up[2],
        tri_down[3], tri_down[4],
    }

    local oldcolor = {g.getColor()}
    g.setColor(self.borderColor)
    g.polygon("line", borderVertices)
    g.setColor(oldcolor)
end

function SignalView:rhombus(x: number, y: number, w: number, h: number)
    local delta = 6
    g.polygon("fill", {x + delta, y + h / 2, x + w / 2, y + h - delta,
            x + w - delta, y + h / 2,
            x + w / 2, y + delta})
    g.setColor(self.borderColor)
    g.polygon("line", {x + delta, y + h / 2, x + w / 2, y + h - delta,
            x + w - delta, y + h / 2,
            x + w / 2, y + delta})
end

return {
    new = SignalView.new,
}


--]]
