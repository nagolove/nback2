-- какие параметры контролирует меню? Что передавать в функцию создания нового
-- пункта меню?
-- Где будет находиться обработка пунктов, изменение их значений?
--
-- * уровень н-назад
-- * временя паузы
-- * длина раунда
--
-- * вывод расчетного значения времени раунда(Почему "раунд"? Бокс что-ли?
-- Попробуй заменить на время концентрации

local inspect = require "libs.inspect"
local g = love.graphics

local menu = {}
menu.__index = menu

-- парамертрами могут быть - шрифт и его размер, цвет текста, стиль рамки
-- выделения пункта
function menu.new(font, color)
    local self = {
        font = font,
        color = color,
        items = {},
        activeIndex = 1,
        cursorLineWidth = 3,
    }
    return setmetatable(self, menu)
end

local function checkTableMember(t, name)
    if t[name] then
        print("checking type")
        assert(type(t[name]) == "function", 
            string.format("Field t['%s'] should be function", name))
    end
end

-- oninit - пустое значение(nil) - недопустимая ситуация?
-- onleft, onright равны nil - значение не регулируется?
-- t["oninit"]
-- t["onleft"]
-- t["onright"]
-- t["onselect"]
function menu:addItem(t)
    print("addItem", inspect(t))

    assert(t)
    assert(t.oninit ~= nil) -- обязательное поле

    checkTableMember(t, "oninit")
    checkTableMember(t, "onleft")
    checkTableMember(t, "onright")
    checkTableMember(t, "onselect")

    self.items[#self.items + 1] = t
    local item = self.items[#self.items]
    item.text = item.oninit()
    assert(type(item.text == "string"), "oninit() should return string.")
end

function menu:update(dt)
end

-- может сделать лучше прокрутку списка клавишами по-кругу? В виде
-- закольцованного списка?
function menu:scrollUp()
    if self.activeIndex - 1 >= 1 then
        self.activeIndex = self.activeIndex - 1
    else
        self.activeIndex = #self.items
    end
end

function menu:scrollDown()
    if self.activeIndex + 1 <= #self.items then
        self.activeIndex = self.activeIndex + 1
    else
        self.activeIndex = 1
    end
end

-- тут изменение параметра в меньшую стророну
function menu:leftPressed()
    local item = self.items[self.activeIndex]
    if item.onleft then
        item.text = item.onleft()
    end
end

-- тут изменение параметра в большую строну
function menu:rightPressed()
    local item = self.items[self.activeIndex]
    if item.onright then
        item.text = item.onright()
    end
end

-- целевая задача: рисовка одной единственной менюшки, в центре экрана, с
-- выравниманием по-центру прямоугольника.
function menu:draw()
    local y0 = (h - #self.items * self.font:getHeight()) / 2 
    local w, h = g.getDimensions()
    --local menuHeight = 
    local y = y0
    local oldfont = g.getFont()
    g.setColor(self.color)
    g.setFont(self.font)

    local oldLineWidth = g.getLineWidth()
    g.setLineWidth(self.cursorLineWidth)

    for k, v in pairs(self.items) do
        local text = ""

        if v.onleft then
            text = "<< "
        end
        text = text .. v.text
        if v.onright then
            text = text .. " >>"
        end

        g.printf(text, 0, y, w, "center")

        if k == self.activeIndex then 
            local textWidth = g.getFont():getWidth(v.text)
            local x = (w - textWidth) / 2
            local oldcolor = {g.getColor()}
            g.setColor{0.8, 0, 0}
            g.rectangle("line", x, y, textWidth, g.getFont():getHeight())
            g.setColor(oldcolor)
        end
        y = y + self.font:getHeight()
    end

    g.setLineWidth(oldLineWidth)
    g.setFont(oldfont)
end

return setmetatable(menu, { __call = function(cls, ...)
    return cls.new(...)
end})
