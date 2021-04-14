--
-- * уровень н-назад
-- * временя паузы
-- * длина раунда
--
-- * вывод расчетного значения времени раунда(Почему "раунд"? Бокс что-ли?
-- Попробуй заменить на время концентрации

require "love"
require "common"

local g = love.graphics

global type SetupMenu = record

    record Rect
        x: number
        y: number
        w: number
        h: number
        k: number
    end

    record ItemHandler
        oninit: function(): {any}, boolean, boolean
        onleft: function(): {any}, boolean, boolean
        onright: function(): {any}, boolean, boolean
        onselect: function(ItemHandler)

        content: {string}
        isfirst: boolean
        islast: boolean
        leftPressedKey: boolean
        rightPressedKey: boolean
        leftRect: Rect
        rightRect: Rect
        rect: Rect
        leftBorder: boolean
        rightBorder: boolean
    end

    font: love.graphics.Font
    color: {number}
    items: {ItemHandler}
    activeIndex: integer
    cursorLineWidth: number
    cursorColor: {number}
    markerColor: {number}
    activeMarkerColor: {number}
    inactiveMarkerColor: {number}
    freeze: boolean

    new: function(love.graphics.Font, {number}): SetupMenu
    addItem: function(SetupMenu, SetupMenu.ItemHandler)
    select: function(SetupMenu)
    update: function(SetupMenu, number)
    scrollUp: function(SetupMenu)
    scrollDown: function(SetupMenu)
    leftPressed: function(SetupMenu)
    leftReleased: function(SetupMenu)
    rightPressed: function(SetupMenu)
    rightReleased: function(SetupMenu)
    draw: function(SetupMenu)
    mousemoved: function(SetupMenu, x: number, y: number, dx: number, dy: number, istouch: boolean)
    keypressed: function(SetupMenu, string)
    mousepressed: function(SetupMenu, x: number, y: number, btn: number, istouch: boolean)
end

local SetupMenu_mt: metatable<SetupMenu> = {
    __index = SetupMenu
}

-- парамертрами могут быть - шрифт и его размер, цвет текста, стиль рамки
-- выделения пункта
function SetupMenu.new(font: love.graphics.Font, color: {number}): SetupMenu
    local self: SetupMenu = {
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
    return setmetatable(self, SetupMenu_mt)
end

local function checkTableMember(t: SetupMenu.ItemHandler, name: string)
    if (t as {any:any})[name] then
        --print("checking type")
        assert(type((t as {any:any})[name]) == "function", string.format("Field t['%s'] should be function", name))
    end
end

-- oninit - пустое значение(nil) - недопустимая ситуация?
-- onleft, onright равны nil - значение не регулируется?
-- t["oninit"]
-- t["onleft"]
-- t["onright"]
-- t["onselect"]
function SetupMenu:addItem(t: SetupMenu.ItemHandler)
    --print("addItem", inspect(t))

    assert(t)
    assert(t.oninit ~= nil) -- обязательное поле

    checkTableMember(t, "oninit")
    checkTableMember(t, "onleft")
    checkTableMember(t, "onright")
    checkTableMember(t, "onselect")

    self.items[#self.items + 1] = t
    local item = self.items[#self.items]
    item.content, item.isfirst, item.islast = item.oninit() as ({string}, boolean, boolean)

    if not item.isfirst then
        item.isfirst = false
    end
    if not item.islast then
        item.islast = false
    end

    assert(type(item.content) == "table", "oninit() should return table.")
    item.leftPressedKey = false
    item.rightPressedKey = false
end

function SetupMenu:select()
    local item = self.items[self.activeIndex]
    if item and item.onselect then
        item:onselect()
    end
end

function SetupMenu:update(_: number)
    --print("menu:update()")
    local item = self.items[self.activeIndex]
    --linesbuf:pushi("item.leftPressedKey = %s", tostring(item.leftPressedKey))
    --linesbuf:pushi("item.rightPressedKey = %s", tostring(item.rightPressedKey))
    if item then
        --linesbuf:pushi("item.isfirst = %s, item.islast = %s", item.isfirst, item.islast)
    end
end

function SetupMenu:scrollUp()
    if self.activeIndex - 1 >= 1 then
        self.activeIndex = self.activeIndex - 1
    else
        self.activeIndex = #self.items
    end
end

function SetupMenu:scrollDown()
    if self.activeIndex + 1 <= #self.items then
        self.activeIndex = self.activeIndex + 1
    else
        self.activeIndex = 1
    end
end

-- тут изменение параметра в меньшую стророну
function SetupMenu:leftPressed()
    local item = self.items[self.activeIndex]
    if item.onleft then
        item.content, item.isfirst, item.islast = item.onleft() as ({string}, boolean, boolean)
        if not item.isfirst then
            item.isfirst = false
        end
        if not item.islast then
            item.islast = false
        end
        item.leftPressedKey = true
    end
end

function SetupMenu:leftReleased()
    local item = self.items[self.activeIndex]
    item.leftPressedKey = false
end

-- тут изменение параметра в большую строну
function SetupMenu:rightPressed()
    local item = self.items[self.activeIndex]
    if item.onright then
        item.content, item.isfirst, item.islast = item.onright() as ({string}, boolean, boolean)
        if not item.isfirst then
            item.isfirst = false
        end
        if not item.islast then
            item.islast = false
        end
        item.rightPressedKey = true
    end
end

function SetupMenu:rightReleased()
    local item = self.items[self.activeIndex]
    item.rightPressedKey = false
end

-- целевая задача: рисовка одной менюшки, в центре экрана, с выравниманием 
-- по центру экрана
function SetupMenu:draw()

    -- XXX может быть какая-то ошибка с переменной h
    local w, h = g.getDimensions()
    local y0 = (h - #self.items * self.font:getHeight()) / 2 
    local y = y0

    local oldfont = g.getFont()
    g.setFont(self.font)

    local oldLineWidth = g.getLineWidth()
    g.setLineWidth(self.cursorLineWidth)

    local leftMarker, rightMarker = "<< ", " >>"

    --self.rects = {}
    for k, v in ipairs(self.items) do
        local leftMarkerColor = v.leftPressedKey and self.activeMarkerColor 
            or (v.isfirst and self.inactiveMarkerColor or self.markerColor)
        local rightMarkerColor = v.rightPressedKey and self.activeMarkerColor 
            or (v.islast and self.inactiveMarkerColor or self.markerColor)

        local text = ""

        if v.onleft then
            text = leftMarker
        end
        for _, p in ipairs(v.content) do
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
        for _, p in ipairs(v.content) do
            if type(p) == "table" then
                g.setColor(p as {number})
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

function SetupMenu:mousemoved(x: number, y: number, _: number, _: number, _: boolean)
    if not self.freeze then
        for k, v in ipairs(self.items) do
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
end

function SetupMenu:keypressed(key: string)
    if key == "up" or key == "k" then
        self:scrollUp()
    elseif key == "down" or key == "j" then
        self:scrollDown()
    end
end

function SetupMenu:mousepressed(x: number, y: number, btn: number, _: boolean)
    if not self.freeze then
        if btn == 1 then
            for k, v in ipairs(self.items) do
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
end

--return setmetatable(menu, { __call = function(cls, ...)
    --return cls.new(...)
--end})

return SetupMenu
