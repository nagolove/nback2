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

-- может сделать лучше прокрутку списка клавишами по-кругу? В виде
-- закольцованного списка?
function menu:scrollUp()
    if self.activeIndex - 1 >= 1 then
        self.activeIndex = self.activeIndex - 1
    end
end

function menu:scrollDown()
    if self.activeIndex + 1 <= #self.items then
        self.activeIndex = self.activeIndex + 1
    end
end

-- тут изменение параметра в меньшую стророну
function menu:leftPressed()
end

-- тут изменение параметра в большую строну
function menu:rightPressed()
end

-- рисовать курсор на активной позиции
function menu:drawCursor()
end

-- рисовать менюшку с выравниванием относительно прямоугольника x, y, w, h
-- целевая задача: рисовка одной единственной менюшки, в центре экрана, с
-- выравниманием по-центру прямоугольника.
function menu:draw()
    local y0 = 0 -- вычислить на какой высоте начинать рисовать, что-бы меню
                 -- оказалось в центре экрана по высоте.
    local y = y0
    local w = g.getWidth()
    local oldfont = g.getFont()
    g.setFont(self.font)
    for k, v in pairs(self.items) do
       g.printf(v.text, 0, y, w)
       y = y + self.font:getHeight()
    end
    g.setFont(oldfont)
end

return setmetatable(menu, { __call = function(cls, ...)
    return cls.new(...)
end})
