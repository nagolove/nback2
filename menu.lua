local inspect = require "libs.inspect"
local pviewer = require "pviewer"
local nback = require "nback"
local help = require "help"
local pallete = require "pallete"

local g = love.graphics

local menu = {}
menu.__index = menu

function menu.new()
    local self = {
        items = {},
        active_item = 1, -- указывает индекс выбранного пункта
        active = false,  -- указывает, что запущено какое-то состояние из меню
        --font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 72),
        font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 32),
        back = require "background".new()
    }
    return setmetatable(self, menu)
end

-- вызывается из игрового состояния для возвращения в меню
function menu:goBack()
    local obj = self.items[self.active_item].obj
    if obj.leave then obj:leave() end
    self.active = false
end

function menu:compute_rects()
    -- позиционирование игрек посредине высоты экрана
    self.y_pos = (self.h - #self.items * self.font:getHeight()) / 2

    -- заполнение прямоугольников меню
    self.items_rects = {}
    local y = self.y_pos
    local rect_width = self.maxWidth
    for i, k in ipairs(self.items) do
        self.items_rects[#self.items_rects + 1] = { 
            x = (self.w - rect_width) / 2, 
            y = y, w = rect_width, 
            h = self.font:getHeight()
        }
        y = y + self.font:getHeight()
    end
end

-- как лучше хранить актиный элемент из списка меню? По индексу?
-- Важен порядок элементов. Значит добавлять в массив таблички по индексу.
function menu:init()
    self:resize(g.getDimensions())
    self.alpha = 1
end

-- ищет наиболее длинный текст в списке пунктов меню и устанавливает
-- внутреннюю переменную menu.maxWidth по найденному значению(в знаках).
function menu:searchWidestText()
    local maxWidth = 0
    for _, v in pairs(self.items) do
        local w = self.font:getWidth(v.name)
        if w > maxWidth then maxWidth = w end
    end
    self.maxWidth = maxWidth
end

-- добавить следующий пункт с заголовком name и обработчиком object.
-- object - таблица с методами update, draw, keypressed и другими.
-- Или object может быть функцией(пока не реализовано).
function menu:addItem(name, object)
    --print("menu:addItem()", inspect(name), inspect(object))
    assert(type(name) == "string")
    self.items[#self.items + 1] = { name = name, obj= object }
    self:searchWidestText()
    self:resize(g.getDimensions())
end

function menu:resize(neww, newh)
    self.w = neww
    self.h = newh
    self:compute_rects()
    self.back:resize(neww, newh)
    self.canvas = g.newCanvas(neww, newh, {msaa = 4})
    --print(string.format("menu:resize() %d*%d -> %d*%d!", w, h, neww, newh))
end

function menu:moveDown()
    if self.active_item + 1 <= #self.items then
        self.active_item = self.active_item + 1
    else
        self.active_item = 1
    end
end

function menu:moveUp()
    if self.active_item - 1 >= 1 then
        self.active_item = self.active_item - 1
    else
        self.active_item = #self.items
    end
end

function menu:keyreleased(key, scancode)
    if self.active then
        --пересылка обработки в активное состояние
        local obj = self.items[self.active_item].obj
        if obj.keyreleased then obj:keyreleased(key, scancode) end
    end
end

function menu:keypressed(key, scancode)
    if self.active then
        --пересылка обработки в активное состояние
        local obj = self.items[self.active_item].obj
        assert(obj)
        if obj.keypressed then obj:keypressed(key, scancode) end
    else
        --движение по меню

        if key == "up" or key == "k" then self:moveUp()
        elseif key == "down" or key == "j" then self:moveDown()
        elseif key == "escape" then love.event.quit()
        elseif key == "return" or key == "space" then 
            local obj = self.items[self.active_item].obj
            if type(obj) == "function" then
                obj()
            else
                self.active = true
                if obj.enter then obj:enter() end
            end
        end
    end
end

function menu:update(dt) 
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.update then obj:update(dt) end
    else
        self.back:update(dt)
    end
end

function menu:process_menu_selection(x, y, dx, dy, istouch)
    for k, v in pairs(self.items_rects) do
        if pointInRect(x, y, v.x, v.y, v.w, v.h) then 
            self.active_item = k 
        end
    end
end

function menu:mousemoved(x, y, dx, dy, istouch)
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.mousemoved then obj:mousemoved(x, y, dx, dy, istouch) end
    else
        self:process_menu_selection(x, y, dx, dy, istouch)
    end
end

function menu:mousereleased(x, y, btn, istouch)
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.mousereleased then obj:mousereleased(x, y, btn, istouch) end
    end
end

function menu:mousepressed(x, y, button, istouch)
    if self.active then
        local obj = self.items[self.active_item].obj
        assert(obj)
        if obj.mousepressed then obj:mousepressed(x, y, button, istouch) end
    else
        local active_rect = self.items_rects[self.active_item]
        if button == 1 and active_rect and pointInRect(x, y, active_rect.x, 
            active_rect.y, active_rect.w, active_rect.h) then
            self.active = true
            local obj = self.items[self.active_item].obj
            if type(obj) == "table" and obj.enter then obj:enter()
            elseif type(obj) == "function" then obj() end
        end
    end
end

-- печать вертикального списка меню
function menu:drawList()
    local y = self.y_pos
    g.setFont(self.font)
    for i, k in ipairs(self.items) do
        --local q = self.active_item == i and pallete.active or pallete.inactive 
        local q = self.active_item == i and {1, 1, 1, 1} or {0, 0, 0, 1}
        q[4] = self.alpha
        g.setColor(q)
        g.printf(k.name, 0, y, self.w, "center")
        y = y + self.font:getHeight()
    end
end

function menu:drawCursor()
    local v = self.items_rects[self.active_item]
    g.setLineWidth(3)
    g.setColor{1, 0, 0}
    g.rectangle("line", v.x, v.y, v.w, v.h)
end

function menu:draw()
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.draw then 

            --g.setCanvas{self.canvas, stencil = true}
            --g.setColor{1, 1, 1, 1}
            --g.clear{1, 1, 1, 1}

            obj:draw() 

            --g.setCanvas()
            --g.setColor{1, 1, 1, 0.2}
            --g.clear(pallete.background)
            --g.setColor{1, 1, 1, 1}
            --g.draw(self.canvas)

        end
    else
        g.push("all")
        self.back:draw()
        self:drawList()
        self:drawCursor()
        g.pop()
    end
end

function menu:touchpressed(id, x, y, dx, dy, pressure)
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.touchpressed then obj:touchpressed(id, x, y, dx, dy, pressure) end
    end
end

function menu:touchreleased(id, x, y, dx, dy, pressure)
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.touchreleased then obj:touchreleased(id, x, y, dx, dy, pressure) end
    end
end

function menu:touchmoved(id, x, y, dx, dy, pressure)
    if self.active then
        local obj = self.items[self.active_item].obj
        if obj.touchmoved then obj:touchmoved(id, x, y, dx, dy, pressure) end
    end
end

return {
    new = menu.new
}
