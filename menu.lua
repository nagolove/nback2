﻿local inspect = require "libs.inspect"
local pviewer = require "pviewer"
local nback = require "nback"
local help = require "help"
local pallete = require "pallete"
local timer = require "libs.Timer"

local g = love.graphics
local w, h = g.getDimensions()
local tile_size = 256

local menu = {}
menu.__index = menu

function menu.new()
    local self = {
        active_item = 1, -- указывает индекс выбранного пункта
        active = false,  -- указывает, что запущено какое-то состояние из меню
        items = {},
        font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 72),
        back_tile = love.graphics.newImage("gfx/IMG_20190111_115755.png")
    }
    return setmetatable(self, menu)
end

-- вызывается из игрового состояния для возвращения в меню
function menu:goBack()
    self.active = false
end

function menu:compute_rects()
    -- позиционирование игрек посредине высоты экрана
    self.y_pos = (h - #self.items * self.font:getHeight()) / 2

    -- заполнение прямоугольников меню
    self.items_rects = {}
    local y = self.y_pos
    local rect_width = self.maxWidth
    for i, k in ipairs(self.items) do
        self.items_rects[#self.items_rects + 1] = { 
            x = (w - rect_width) / 2, 
            y = y, w = rect_width, 
            h = self.font:getHeight()
        }
        y = y + self.font:getHeight()
    end
end

-- как лучше хранить актиный элемент из списка меню? По индексу?
-- Важен порядок элементов. Значит добавлять в массив таблички по индексу.
function menu:init()
    math.randomseed(os.time())
    self.timer = timer()
    self.alpha = 1
    self:calc_rotation_grid()
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
    assert(type(name) == "string")
    self.items[#self.items + 1] = { name = name, object = object }
    self:searchWidestText()
    self:compute_rects()
end

function menu:resize(neww, newh)
    w = neww
    h = newh
    self:calc_rotation_grid()
    self:compute_rects()
    print(string.format("menu:resize() %d*%d -> %d*%d!", w, h, neww, newh))
end

-- здесь добавить генерацию разных маршрутов движения и преобразования
-- элементов - "плиток"
function menu:calc_rotation_grid()
    self.rot_grid = {}
    local i, j = 0, 0
    while i <= w do
        j = 0
        while j <= h do
            local v = math.random()
            local angle = 0
            if 0 <= v and v <= 0.25 then angle = 0
            elseif 0.25 < v and v < 0.5 then angle = math.pi
            elseif 0.5 < v and v < 0.75 then angle = math.pi * 3 / 4
            elseif 0.75 < v and v <= 1 then angle = math.pi * 2 end
            self.rot_grid[#self.rot_grid + 1] = angle
            j = j + tile_size
        end
        i = i + tile_size
    end
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

function menu:keypressed(key)
    if key == "up" or key == "k" then self:moveUp()
    elseif key == "down" or key == "j" then self:moveDown()
    elseif key == "escape" then love.event.quit()
    elseif key == "return" or key == "space" then 
        self.active = true
    end
end

function menu:update(dt) 
    self.timer:update(dt)
    
    if self.active then
        local obj = self.items[self.active_item]
        if obj.update then obj:update(dt) end
    end
end

function point_in_rect(px, py, x, y, w, h)
    return px > x and py > y and px < x + w and py < y + h
end

function menu:process_menu_selection(x, y, dx, dy, istouch)
    for k, v in pairs(self.items_rects) do
        if point_in_rect(x, y, v.x, v.y, v.w, v.h) then 
            self.active_item = k 
        end
    end
end

function menu:mousemoved(x, y, dx, dy, istouch)
    if self.active then
        local obj = self.items[self.active_item]
        if obj.mousemoved then obj:mousemoved(x, y, dx, dy, istouch) end
    else
        self:process_menu_selection(x, y, dx, dy, istouch)
    end
end

function menu:mousepressed(x, y, button, istouch)
    if self.active then
        local obj = self.items[self.active_item]
        if obj.mousepressed then obj:mousepressed(x, y, button, istouch) end
    else
        local active_rect = self.items_rects[self.active_item]
        if button == 1 and active_rect and point_in_rect(x, y, active_rect.x, 
            active_rect.y, active_rect.w, active_rect.h) then
            self.active = true
        end
    end
end

function menu:drawBackground()
    g.clear(pallete.background)
    local quad = g.newQuad(0, 0, self.back_tile:getWidth(), 
        self.back_tile:getHeight(), self.back_tile:getWidth(), 
        self.back_tile:getHeight())
    local i, j = 0, 0
    local l = 1
    g.setColor(1, 1, 1, self.alpha)
    while i <= w do
        j = 0
        while j <= h do
            --print("angle = ", self.rot_grid[l])
            g.draw(self.back_tile, quad, i, j, self.rot_grid[l], 
            tile_size / self.back_tile:getWidth(), 
            tile_size / self.back_tile:getHeight(),
            self.back_tile:getWidth() / 2, self.back_tile:getHeight() / 2)
            --g.draw(menu.back_tile, quad, i, j, math.pi, 0.3, 0.3)
            l = l + 1
            j = j + tile_size
        end
        i = i + tile_size
    end
end

-- печать вертикального списка меню
function menu:drawList()
    local y = self.y_pos
    g.setFont(self.font)
    for i, k in ipairs(self.items) do
        local q = self.active_item == i and pallete.active or pallete.inactive 
        q[4] = self.alpha
        g.setColor(q)
        g.printf(k.name, 0, y, w, "center")
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
        local obj = self.items[self.active_item]
        if obj.draw then obj:draw() end
    else
        g.push("all")
        self:drawBackground()
        self:drawList()
        self:drawCursor()
        g.pop()
    end
end

return {
    new = menu.new
}
