--
-- * уровень н-назад
-- * временя паузы
-- * длина раунда
--
-- * вывод расчетного значения времени раунда(Почему "раунд"? Бокс что-ли?
-- Попробуй заменить на время концентрации

require("common")
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
        cursorColor = {0.8, 0, 0},
        markerColor = {1, 1, 1},
        activeMarkerColor = {0, 0.8, 0},
        inactiveMarkerColor = {0.5, 0.5, 0.5},
    }
    return setmetatable(self, menu)
end

local function checkTableMember(t, name)
    if t[name] then
        --print("checking type")
        assert(type(t[name]) == "function", string.format("Field t['%s'] should be function", name))
    end
end

-- oninit - пустое значение(nil) - недопустимая ситуация?
-- onleft, onright равны nil - значение не регулируется?
-- t["oninit"]
-- t["onleft"]
-- t["onright"]
-- t["onselect"]
function menu:addItem(t)
    --print("addItem", inspect(t))

    assert(t)
    assert(t.oninit ~= nil) -- обязательное поле

    checkTableMember(t, "oninit")
    checkTableMember(t, "onleft")
    checkTableMember(t, "onright")
    checkTableMember(t, "onselect")

    self.items[#self.items + 1] = t
    local item = self.items[#self.items]
    item.content, item.isfirst, item.islast = item.oninit()

    if not item.isfirst then
        item.isfirst = false
    end
    if not item.islast then
        item.islast = false
    end

    assert(type(item.content == "table"), "oninit() should return table.")
    item.leftPressedKey = false
    item.rightPressedKey = false
end

function menu:select()
    local item = self.items[self.activeIndex]
    if item and item.onselect then
        item:onselect()
    end
end

function menu:update(dt)
    --print("menu:update()")
    local item = self.items[self.activeIndex]
    --linesbuf:pushi("item.leftPressedKey = %s", tostring(item.leftPressedKey))
    --linesbuf:pushi("item.rightPressedKey = %s", tostring(item.rightPressedKey))
    if item then
        linesbuf:pushi("item.isfirst = %s, item.islast = %s", item.isfirst, item.islast)
    end
end

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
        item.content, item.isfirst, item.islast = item.onleft()
        if not item.isfirst then
            item.isfirst = false
        end
        if not item.islast then
            item.islast = false
        end
        item.leftPressedKey = true
    end
end

function menu:leftReleased()
    local item = self.items[self.activeIndex]
    item.leftPressedKey = false
end

-- тут изменение параметра в большую строну
function menu:rightPressed()
    local item = self.items[self.activeIndex]
    if item.onright then
        item.content, item.isfirst, item.islast = item.onright()
        if not item.isfirst then
            item.isfirst = false
        end
        if not item.islast then
            item.islast = false
        end
        item.rightPressedKey = true
    end
end

function menu:rightReleased()
    local item = self.items[self.activeIndex]
    item.rightPressedKey = false
end

-- целевая задача: рисовка одной менюшки, в центре экрана, с выравниманием 
-- по центру экрана
function menu:draw()

    local y0 = (h - #self.items * self.font:getHeight()) / 2 
    local w, h = g.getDimensions()
    local y = y0

    local oldfont = g.getFont()
    g.setFont(self.font)

    local oldLineWidth = g.getLineWidth()
    g.setLineWidth(self.cursorLineWidth)

    local leftMarker, rightMarker = "<< ", " >>"
    local leftMarkerColor, rightMarkerColor

    --self.rects = {}
    for k, v in pairs(self.items) do
        local leftMarkerColor = v.leftPressedKey and self.activeMarkerColor 
            or (v.isfirst and inactiveMarkerColor or self.markerColor)
        local rightMarkerColor = v.rightPressedKey and self.activeMarkerColor 
            or (v.islast and inactiveMarkerColor or self.markerColor)

        local text = ""

        if v.onleft then
            text = leftMarker
        end
        for _, p in pairs(v.content) do
            if type(p) == "string" then
                text = text .. p
            end
        end
        if v.onright then
            text = text .. rightMarker
        end

        local textWidth = g.getFont():getWidth(text)
        local x0 = (w - textWidth) / 2
        local x = x0

        if v.onleft then
            g.setColor(leftMarkerColor)
            g.print(leftMarker, x, y)

            local width = g.getFont():getWidth(leftMarker)
            v.leftRect = { x = x, y = y, w = width,
                h = g.getFont():getHeight(), k = k}
            
            if v.leftBorder then
                g.setColor(self.cursorColor)
                g.rectangle("line", v.leftRect.x, v.leftRect.y, v.leftRect.w,
                    v.leftRect.h)
            end

            x = x + width
        end
        local xLeft = x
        g.setColor(self.color)
        for _, p in pairs(v.content) do
            if type(p) == "table" then
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
            local width = g.getFont():getWidth(rightMarker)
            v.rightRect = { x = x, y = y, w = width,
                h = g.getFont():getHeight(), k = k}

            if v.rightBorder then
                g.setColor(self.cursorColor)
                g.rectangle("line", v.rightRect.x, v.rightRect.y, v.rightRect.w,
                    v.rightRect.h)
            end

            x = x + width
        end

        -- здесь можно заполнить внутреннюю табличку, содержащую координаты
        -- всех прямоугольников меню
        -- плохой код так как он дублируется чуть ниже и заполнения и стирания
        -- производятся каждый кадр
        -- x, y, w, h, k
        v.rect = {x = xLeft, y = y, w = xRight - xLeft, 
            h = g.getFont():getHeight(), k = k}

        if k == self.activeIndex then 
            local oldcolor = {g.getColor()}
            g.setColor(self.cursorColor)
            g.rectangle("line", xLeft, y, xRight - xLeft, 
                g.getFont():getHeight())
            g.setColor(oldcolor)
        end

        y = y + self.font:getHeight()
    end

    g.setLineWidth(oldLineWidth)
    g.setFont(oldfont)
end

function menu:mousemoved(x, y, dx, dy, istouch)
    for k, v in pairs(self.items) do
        local rect = v.rect
        if pointInRect(x, y, rect.x, rect.y, rect.w, rect.h) then
            self.activeIndex = k
        end
        local leftRect = v.leftRect
        v.leftBorder = leftRect and pointInRect(x, y, leftRect.x, 
            leftRect.y, leftRect.w, leftRect.h)
        local rightRect = v.rightRect
        v.rightBorder = rightRect and pointInRect(x, y, rightRect.x, 
            rightRect.y, rightRect.w, rightRect.h)

        if v.leftBorder or v.rightBorder then
            self.activeIndex = k
        end

    end
end

function menu:mousepressed(x, y, btn, istouch)
    if btn == 1 then
        for k, v in pairs(self.items) do
            local rect = v.rect
            if pointInRect(x, y, rect.x, rect.y, rect.w, rect.h) then
                self:select()
            end
            local leftRect = v.leftRect
            if leftRect and pointInRect(x, y, leftRect.x, leftRect.y,
                leftRect.w, leftRect.h) and self.activeIndex == k then
                self:leftPressed()
                self:leftReleased()
            end
            local rightRect = v.rightRect
            if rightRect and pointInRect(x, y, rightRect.x, rightRect.y,
                rightRect.w, rightRect.h) and self.activeIndex == k then
                self:rightPressed()
                self:rightReleased()
            end
        end
    end
end

return setmetatable(menu, { __call = function(cls, ...)
    return cls.new(...)
end})
