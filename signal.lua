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
        canvas = g.newCanvas(width, width, {msaa = 2}),
    }

    wavePath = "sfx/" .. soundPack
    for k, v in pairs(love.filesystem.getDirectoryItems(wavePath)) do
        table.insert(self.sounds, love.audio.newSource(wavePath .. "/" .. v, 
            "static"))
    end

    if not self.canvas then
        error("Could'not create Canvas for signal rendering.")
    end

    self = setmetatable(self, signal)
    self:setCorner(0, 0)

    return self
end

-- установить координаты левого верхнего угла, от которого идет отсчет ячеек.
-- обязательно вызывать перед рисовкой.
function signal:setCorner(x, y)
    self.x0, self.y0 = x, y
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

    g.setColor(color)
    --local x, y = self.x0 + border, self.y0 + border
    --print("type", type)
    --print("dispatch", inspect(dispatch))
    --print("dispatch[type] = ", dispatch[type])
    self[type](self, x, y, w, h)
end

-- хорошая идея добавить проигрывание звука, но как ориентироваться в
-- сэмплах? На стадии создания сигнала загрузить набор сэмплов и
-- ориентироваться по их номерам? Тогда нужно предоставить пользователю
-- сигнала диапазон возможных значений номеров сэмпла 1..samplesCount
function signal:play(index)
    assert(index <= #self.sounds)
end

function signal:quad(x, y, w, h)
    local delta = 5
    g.rectangle("fill", x + delta, y + delta, w - delta * 2, h - delta * 2)
end

function signal:circle(x, y, w, h)
    g.circle("fill", x + w / 2, y + h / 2, w / 2.3)
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
end

-- рисовать для нормального отображения анимации альфа канала через канвас.
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

    g.setCanvas()
    g.draw(self.canvas, x, y)
end

function signal:rhombus(x, y, w, h)
    local delta = 0
    g.polygon("fill", {x + delta, y + h / 2, x + w / 2, y + h - delta,
            x + w - delta, y + h / 2,
            x + w / 2, y + delta})
end

return {
    new = signal.new,
}
