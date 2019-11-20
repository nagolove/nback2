local serpent = require "serpent"
local inspect = require "libs.inspect"
local g = love.graphics

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
-- двух треугольников. trUp, trDown - координаты точек треугольника вершинами
-- вверх и вершинами вниз соответственно. Вершины лежат в массиве плоско.
function signal:calculateIntersections(trUp, trDown)
    local points = {}
    local x, y
   
    -- 1
    x, y = lineCross(trUp[1], trUp[2], trUp[5], trUp[6],
        trDown[3], trDown[4], trDown[5], trDown[6])
    points[#points + 1] = x
    points[#points + 1] = y

    -- 2
    x, y = lineCross(trUp[1], trUp[2], trUp[5], trUp[6],
        trDown[3], trDown[4], trDown[1], trDown[2])
    points[#points + 1] = x
    points[#points + 1] = y

    -- 3
    x, y = lineCross(trUp[3], trUp[4], trUp[5], trUp[6],
        trDown[3], trDown[4], trDown[1], trDown[2])
    points[#points + 1] = x
    points[#points + 1] = y

    -- 4
    x, y = lineCross(trUp[3], trUp[4], trUp[5], trUp[6],
        trDown[1], trDown[2], trDown[5], trDown[6])
    points[#points + 1] = x
    points[#points + 1] = y

    -- 5
    x, y = lineCross(trUp[3], trUp[4], trUp[1], trUp[2],
        trDown[1], trDown[2], trDown[5], trDown[6])
    points[#points + 1] = x
    points[#points + 1] = y

    -- 6
    x, y = lineCross(trUp[3], trUp[4], trUp[1], trUp[2],
        trDown[3], trDown[4], trDown[5], trDown[6])
    points[#points + 1] = x
    points[#points + 1] = y

    return points
end

function signal:trupdown(x, y, w, h)
    g.setCanvas(self.canvas)

    local tri_up, tri_down = {}, {}
    local rad = w / 2
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
    g.polygon("fill", tri_up)
    g.polygon("fill", tri_down)
    g.setColor(self.borderColor)

    g.circle("fill", tri_up[1], tri_up[2], 3)
    g.circle("fill", tri_down[1], tri_down[2], 3)
    g.setColor{1, 0, 0}
    g.circle("fill", tri_up[5], tri_up[6], 3)
    g.circle("fill", tri_down[5], tri_down[6], 3)
    g.setColor{0, 1, 0.3}
    g.circle("fill", tri_up[5], tri_up[6], 3)
    g.circle("fill", tri_down[5], tri_down[6], 3)
    --g.polygon("line", tri_up)
    --g.polygon("line", tri_down)

    g.setCanvas()
    g.setColor{1, 1, 1, 1}
    g.draw(self.canvas, x, y)
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
