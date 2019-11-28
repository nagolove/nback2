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
    item.content = item.oninit()
    assert(type(item.content == "table"), "oninit() should return table.")
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
        item.content = item.onleft()
    end
end

function menu:leftReleased()
    print("menu:leftReleased()")
end

-- тут изменение параметра в большую строну
function menu:rightPressed()
    local item = self.items[self.activeIndex]
    if item.onright then
        item.content = item.onright()
    end
end

function menu:rightReleased()
    print("menu:rightReleased()")
end

-- целевая задача: рисовка одной единственной менюшки, в центре экрана, с
-- выравниманием по-центру прямоугольника.
function menu:draw()

    function subDrawText(text)
    end

    local y0 = (h - #self.items * self.font:getHeight()) / 2 
    local w, h = g.getDimensions()
    local y = y0

    local oldfont = g.getFont()
    g.setFont(self.font)

    local oldLineWidth = g.getLineWidth()
    g.setLineWidth(self.cursorLineWidth)

    local leftMarker, rightMarker = "<< ", " >>"
    local leftMarkerColor, rightMarkerColor = {0, 0.8, 0}, {0, 0.8, 0}
    for k, v in pairs(self.items) do
        local text = ""

        if v.onleft then
            text = "<< "
        end
        for _, p in pairs(v.content) do
            if type(p) == "string" then
                text = text .. p
            end
        end
        if v.onright then
            text = text .. " >>"
        end

        local textWidth = g.getFont():getWidth(text)
        local x0 = (w - textWidth) / 2
        local x = x0

        --g.printf(text, 0, y, w, "center")

        if v.onleft then
            g.setColor(leftMarkerColor)
            g.print(leftMarker, x, y)
            x = x + g.getFont():getWidth(leftMarker)
        end
        local xLeft = x
        g.setColor(self.color)
        for _, p in pairs(v.content) do
            if type(p) == "table" then
                -- дополнительная проверка на соответствие таблицы структуре
                -- цвета?
                g.setColor(p)
            elseif type(p) == "string" then
                g.print(p, x, y)
                x = x + g.getFont():getWidth(p)
            else
                error("Unexpected type of value.")
            end
        end
        local xRight = x
        if v.onright then
            g.setColor(rightMarkerColor)
            g.print(rightMarker, x, y)
            x = x + g.getFont():getWidth(rightMarker)
        end

        if k == self.activeIndex then 
            -- Переменная с таким именем уже испльзуется. Могут быть ошибки
            --local textWidth = g.getFont():getWidth(v.text)
            --local x = (w - textWidth) / 2
            local oldcolor = {g.getColor()}
            g.setColor{0.8, 0, 0}
            g.rectangle("line", xLeft, y, xRight - xLeft, g.getFont():getHeight())
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
