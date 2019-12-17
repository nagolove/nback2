-- [[
-- Класс должен рисовать список сохраненных игр в левой части экрана.
-- В правой части экрана - вывод результатов через 
-- nback:drawStatistic2Canvas(). Следи за аккуратной обработкой ошибок -
-- могут быть различные версии данных в файле результатов, их нужно корректно
-- не показывать, но не падать.
--
-- Строчки списка сортировать по дате - от последних к первым. Поддержка
-- клавиш выстрой перемотки. Для мобильной версии - наличие визуальных кнопок.
--
-- План работ: загрузка данных, сортировка данных, вывод списка. Клавиши
-- управления. Подсказки клавиш управления.
-- Как хранить список данных?
-- ]]

require("common")
local inspect = require "libs.inspect"
local serpent = require "serpent"
local timer = require "libs.Timer"

local pallete = require "pallete"
local g = love.graphics
local Kons = require "kons"

local pviewer = {}
pviewer.__index = pviewer

function pviewer.new()
    local self = {
        border = 40, --y axis border in pixels for drawing chart
        font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
        scroolTipFont = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 13),
        activeIndex = 0, -- обработай случаи если таблица истории пустая
    }
    self.w, self.h = g.getDimensions()
    return setmetatable(self, pviewer)
end

local linesbuffer = Kons(x, y)

function pviewer:init(save_name)
    self.save_name = save_name
    self:resize(g.getDimensions())
    self.timer = timer()
end

function pviewer:enter()
    print("pviewer:enter()")
    local tmp, size = love.filesystem.read(self.save_name)
    if tmp ~= nil then
        ok, self.data = serpent.load(tmp)
        if not ok then 
            -- эту строчку с падением при ошибке заменить на показ пустой
            -- статистики.
            error("Something wrong in restoring data " .. self.save_name)
        end
    else
        self.data = {}
    end

    self.data = self.data or nil

    print("*** begining of pviewer.data ***")
    local str = inspect(self.data)
    print("Length of pviewer.data =", #self.data)
    love.filesystem.write("pviewer_data_extracting.lua", str, str:len())
    print("*** end of pviewer.data ***")
end

function pviewer:leave()
    print("pviewer:leave()")
    self.data = nil
end

function pviewer:get_max_lines_printed()
    return div(h - 100, self.font:getHeight())
end

function pviewer:resize(neww, newh)
    print(string.format("pviewer.resize(%d, %d)", neww, newh))
    w = neww
    h = newh
    self.verticalBufLen = self:get_max_lines_printed()
    --[[
       [self.rt = g.newCanvas(w, self.vertical_buf_len * 
       [    self.font:getLineHeight() * self.font:getHeight(), {format = "normal", 
       [    msaa = 4})
       [if not self.rt then
       [    error("Canvas not supported!")
       [end
       ]]
end

function pviewer:print_dbg_info()
    linesbuffer:pushi("fps " .. love.timer.getFPS())
    linesbuffer:pushi("self.verticalBufLen %d", self.verticalBufLen)
    linesbuffer:draw()
end

function pviewer:draw()
    g.push("all")

    love.graphics.clear(pallete.background)

    local x = 30
    local y = self.border

    for k, v in pairs(self.data) do
        if v.date then
            local str = string.format("%.2d.%.2d.%d %.2d:%.2d:%.2d",
            v.date.day, v.date.month, v.date.year, v.date.hour, v.date.min,
            v.date.sec)
            print(v.date.day, v.date.month, v.date.year, v.date.hour, v.date.min,
            v.date.sec)
            g.printf(str, x, y, 600, "left")
            y = y + g.getFont():getHeight()
        end
    end

    self:print_dbg_info()

    g.pop()
end

function pviewer:pageUp()
end

function pviewer:pageDown()
end

function pviewer:scrollUp()
end

function pviewer:scrollDown()
end

-- добавить клавиши управления для постраничной прокрутки списка результатов.
function pviewer:keypressed(key)
    if key == "escape" then
        menu:goBack()
    elseif key == "return" or key == "space" then
        -- TODO по нажатию клавиши показать конечную таблицу игры
    elseif key == "home" or key == "kp7" then
    elseif key == "end" or key == "kp1" then
    end
end

function pviewer:update(dt)
    local kb = love.keyboard
    if kb.isDown("up", "k") then
        self:scrollUp()
    elseif kb.isDown("down", "j") then
        self:scrollDown()
    elseif kb.isDown("pageup") then
        self:pageUp()
    elseif kb.isDown("pagedown") then
        self:pageDown()
    end
    self.timer:update(dt)
end

return {
    new = pviewer.new
}
