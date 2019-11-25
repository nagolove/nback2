﻿local g = love.graphics
local inspect = require "libs.inspect"
local serpent = require "serpent"
local vector = require "libs.vector"

local conbuf = require "kons".new(0, 0)

local signal = {}
signal.__index = signal

-- width - ширина ячейки для фигурки
-- soundPack - имя подкаталога в 'sfx' с набором звуков
function signal.new(width, soundPack)
    local self = {
        width = width,
        sounds = {}, 
        canvas = nil,
        borderColor = {0, 0, 0},
        borderLineWidth = 3,
    }

    wavePath = "sfx/" .. soundPack
    for k, v in pairs(love.filesystem.getDirectoryItems(wavePath)) do
        table.insert(self.sounds, love.audio.newSource(wavePath .. "/" .. v, 
            "static"))
    end

    self = setmetatable(self, signal)
    self:setCorner(0, 0)
    self:resize(self.width)

    return self
end

-- установить координаты левого верхнего угла, от которого идет отсчет ячеек.
-- обязательно вызывать перед рисовкой.
function signal:setCorner(x, y)
    self.x0, self.y0 = x, y
end

function signal:resize(width)
    self.width = width
    --self.canvas = g.newCanvas(width, width, {msaa = 2})
    self.canvas = g.newCanvas(width, width, {msaa = 2})
    if not self.canvas then
        error("Could'not create Canvas for signal rendering.")
    end
end

-- xd, yd - целочисленная позиция фигуры в матрице.
-- type - тип рисуемой картинки(квадрат, круг, треугольник вниз, 
-- треугольник вверх, пересечение треугольников, ромб)
-- color - текущий цвет
function signal:draw(xd, yd, type, color)
    local border = 5
    local w, h = self.width - border * 2, self.width - border * 2
    local x = self.x0 + xd * self.width + border 
    local y = self.y0 + yd * self.width + border
    print("x, y = ", x, y)

    self.borderColor[4] = color[4] -- анимирую альфа-канал цвета рамки
    g.setColor(color)
    local oldWidth = g.getLineWidth()
    g.setLineWidth(self.borderLineWidth)
    self[type](self, x, y, w, h)
    g.setLineWidth(oldWidth)
end

-- хорошая идея добавить проигрывание звука, но как ориентироваться в
-- сэмплах? На стадии создания сигнала загрузить набор сэмплов и
-- ориентироваться по их номерам? Тогда нужно предоставить пользователю
-- сигнала диапазон возможных значений номеров сэмпла 1..samplesCount
function signal:play(index)
    assert(index <= #self.sounds)
    self.sounds[index]:play()
end

function signal:quad(x, y, w, h)
    local delta = 5
    g.rectangle("fill", x + delta, y + delta, w - delta * 2, h - delta * 2)
    g.setColor(self.borderColor)
    g.rectangle("line", x + delta, y + delta, w - delta * 2, h - delta * 2)
end

function signal:circle(x, y, w, h)
    g.circle("fill", x + w / 2, y + h / 2, w / 2.3)
    g.setColor(self.borderColor)
    g.circle("line", x + w / 2, y + h / 2, w / 2.3)
end

function signal:trdown(x, y, w, h)
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

function signal:trup(x, y, w, h)
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
function signal:calculateIntersections(up, down)
    local points = {}
    local x, y
    local p
    print("calculateIntersections")
    print("up", inspect(up))
    print("down", inspect(down))

    -- 1
    p = intersection(vector(up[5], up[6]), vector(up[1], up[2]),
        vector(down[5], down[6]), vector(down[3], down[4]))
    points[#points + 1] = p.x
    points[#points + 1] = p.y
    print(x, y)

    local oldcolor = {g.getColor()}
    g.setColor{0, 0, 1}
    g.line(up[1], up[2], up[5], up[6])
    g.line(down[3], down[4], down[5], down[6])
    g.setColor(oldcolor)

    -- 2
    p = intersection(vector(up[5], up[6]), vector(up[1], up[2]),
        vector(down[3], down[4]), vector(down[1], down[2]))
    points[#points + 1] = p.x
    points[#points + 1] = p.y
    print(x, y)

    -- 3
    p = intersection(vector(up[3], up[4]), vector(up[5], up[6]),
        vector(down[3], down[4]), vector(down[1], down[2]))
    points[#points + 1] = p.x
    points[#points + 1] = p.y
    print(x, y)

    -- 4
    p = intersection(vector(up[3], up[4]), vector(up[5], up[6]),
        vector(down[1], down[2]), vector(down[5], down[6]))
    points[#points + 1] = p.x
    points[#points + 1] = p.y
    print(x, y)

    -- 5
    p = intersection(vector(up[3], up[4]), vector(up[1], up[2]),
        vector(down[1], down[2]), vector(down[5], down[6]))
    points[#points + 1] = p.x
    points[#points + 1] = p.y
    print(x, y)

    -- 6
    p = intersection(vector(up[3], up[4]), vector(up[1], up[2]),
        vector(down[3], down[4]), vector(down[5], down[6]))
    points[#points + 1] = p.x
    points[#points + 1] = p.y
    print(x, y)

    return points
end

function signal:trupdown(x, y, w, h)
    --g.setCanvas(self.canvas)

    local tri_up, tri_down = {}, {}
    --local rad = w / 2
    local rad = w * 1.5
    for i = 1, 3 do
        local alpha = 2 * math.pi * i / 3
        local sx = w / 2 + rad * math.sin(alpha)
        local sy = h / 2 + rad * math.cos(alpha)
        tri_up[#tri_up + 1] = sx
        tri_up[#tri_up + 1] = sy
        local alpha = math.pi + 2 * math.pi * i / 3
        local sx = w / 2 + rad * math.sin(alpha)
        local sy = h / 2 + rad * math.cos(alpha)
        tri_down[#tri_down + 1] = sx
        tri_down[#tri_down + 1] = sy
    end

    g.push()
    g.translate(200, 200)

    g.polygon("fill", tri_up)
    g.polygon("fill", tri_down)

    g.print(string.format("%d", 1), tri_down[1], tri_down[2])
    g.print(string.format("%d", 2), tri_down[3], tri_down[4])
    g.print(string.format("%d", 3), tri_down[5], tri_down[6])

    g.print(string.format("%d", 1), tri_up[1], tri_up[2])
    g.print(string.format("%d", 2), tri_up[3], tri_up[4])
    g.print(string.format("%d", 3), tri_up[5], tri_up[6])

    local points = self:calculateIntersections(tri_up, tri_down)
    print("#points", #points)
    print("points", inspect(points))

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
    print("#borderVertices", #borderVertices)
    print("borderVertices", inspect(borderVertices))

    --[[
       [g.polygon("line", points)
       [g.setColor{1, 1, 1}
       [for k = 1, #points - 1 do
       [    g.circle("fill", points[k], points[k + 1], 3)
       [    g.print(string.format("%d", k), points[k], points[k + 1])
       [    --g.print(string.format("(%d, %d) %d", points[k], points[k + 1], k),
       [        --points[k], points[k + 1])
       [end
       ]]

    g.setColor(self.borderColor)
    g.polygon("line", borderVertices)
    g.pop()

    --g.circle("fill", tri_up[1], tri_up[2], 3)
    --g.circle("fill", tri_down[1], tri_down[2], 3)
    --g.setColor{1, 0, 0}
    --g.circle("fill", tri_up[5], tri_up[6], 3)
    --g.circle("fill", tri_down[5], tri_down[6], 3)
    --g.setColor{0, 1, 0.3}
    --g.circle("fill", tri_up[5], tri_up[6], 3)
    --g.circle("fill", tri_down[5], tri_down[6], 3)
    --g.polygon("line", tri_up)
    --g.polygon("line", tri_down)

    --g.setCanvas()
    --g.setColor{1, 1, 1, 1}
    --g.draw(self.canvas, x, y)
end

function signal:rhombus(x, y, w, h)
    local delta = 0
    g.polygon("fill", {x + delta, y + h / 2, x + w / 2, y + h - delta,
            x + w - delta, y + h / 2,
            x + w / 2, y + delta})
    g.setColor(self.borderColor)
    g.polygon("line", {x + delta, y + h / 2, x + w / 2, y + h - delta,
            x + w - delta, y + h / 2,
            x + w / 2, y + delta})
end

-- параметры - hump.vector
-- источник: https://users.livejournal.com/-winnie/152327.html
function intersection(start1, end1, start2, end2)
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

-- функция проверяет, еть ли точки пересечения отрезков, обозначенных 
-- координатами x1, y1, x2, y2, x3, y3, x4, y4
-- возвращает координаты x, y точки пересечения или nil, если таковые 
-- не найдены.  сделано методом копипаста, тестированием не покрывал
function lineCross(x1, y1, x2, y2, x3, y3, x4, y4)
    --print(x1, y1, x2, y2, x3, y3, x4, y4)
    local divisor = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
    
    -- lines are parralell
    if divisor == 0 then return nil end

    local ua = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)
    ua = ua / divisor
    --local ub = (x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)
    --ub = ub / divisor
    --print("lineCross ua: ",ua, " ub: ", ub)
    local x, y = x1 + ua * (x2 - x1), y1 + ua * (y2 - y1)
    if not (x > x1 and x < x2 and y < y2 and y > y1) then 
        --print("point is not on segment")
        return nil
    end
    return x, y
end

return {
    new = signal.new,
}
