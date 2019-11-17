local serpent = require "serpent"
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
    }

    wavePath = "sfx/" .. soundPack
    for k, v in pairs(love.filesystem.getDirectoryItems(wavePath)) do
        table.insert(self.sounds, love.audio.newSource(wavePath .. "/" .. v, "static"))
    end

    return setmetatable(self, signal)
end

-- хорошая идея добавить проигрывание звука, но как ориентироваться в
-- сэмплах? На стадии создания сигнала загрузить набор сэмплов и
-- ориентироваться по их номерам? Тогда нужно предоставить пользователю
-- сигнала диапазон возможных значений номеров сэмпла 1..samplesCount
function signal:play(index)
    assert(index <= #self.sounds)
end

-- установить координаты левого верхнего угла, от которого идет отсчет ячеек.
function signal:setCorner(x, y)
    self.x0, self.y0 = x, y
end

function signal:drawQuad(x, y, w, h)
    local delta = 5
    g.rectangle("fill", x + delta, y + delta, w - delta * 2, h - delta * 2)
end

function signal:drawCircle(x, y, w, h)
    --g.circle("fill", x + w / 2, y + h / 2, w / 2)
    --g.setColor({1, 0, 1})
    g.circle("fill", x + w / 2, y + h / 2, w / 2.3)
end

function signal:drawTrDown(x, y, w, h)
    local magic = 2.64
    g.setColor{1, 1, 1}
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

function signal:drawTrUp(x, y, w, h)
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
function signal:drawTrUpDown(x, y, w, h)
    local tri_up, tri_down = {}, {}
    local rad = w / 2
    for i = 1, 3 do
        local alpha = 2 * math.pi * i / 3
        local sx = x + w / 2 + rad * math.sin(alpha)
        local sy = y + h / 2 + rad * math.cos(alpha)
        tri_up[#tri_up + 1] = sx
        tri_up[#tri_up + 1] = sy
        local alpha = math.pi + 2 * math.pi * i / 3
        local sx = x + w / 2 + rad * math.sin(alpha)
        local sy = y + h / 2 + rad * math.cos(alpha)
        tri_down[#tri_down + 1] = sx
        tri_down[#tri_down + 1] = sy
    end
    g.polygon("fill", tri_up)
    g.polygon("fill", tri_down)
end

function signal:drawRhombus(x, y, w, h)
    local delta = 0
    g.polygon("fill", {x + delta, y + h / 2, x + w / 2, y + h - delta,
            x + w - delta, y + h / 2,
            x + w / 2, y + delta})
end

local dispatch = {["quad"] = signal.drawQuad, 
                  ["circle"] = signal.drawCircle,
                  ["trup"] = signal.drawTrUp, 
                  ["trdown"] = signal.drawTrDown, 
                  ["trupdown"] = signal.drawTrUpDown, 
                  ["rhombus"] = signal.drawRhombus}

-- значения размера рисуемой фигурки берется из nback.cell_width
-- xdim и ydim - позиция в сетке поля
-- formtype - тип рисуемой картинки(квадрат, круг, треугольник вниз, 
-- треугольник вверх, пересечение треугольников, ромб)
function signal:draw(x0, y0, type, color)
    local border = 5
    local w, h = self.width - border * 2, self.width - border * 2
    --local x, y = x0 + dim * nback.cell_width + border, y0 + ydim * nback.cell_width + border
    --print("x0", serpent.block(x0))
    --print("y0", serpent.block(y0))

    g.setColor(color)
    local x, y = x0 + border, y0 + border
    dispatch[type](self, x, y, w, h)
end

return {
    new = signal.new,
}
