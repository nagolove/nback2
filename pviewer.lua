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

require "common"
local inspect = require "libs.inspect"
local serpent = require "serpent"
local timer = require "libs.Timer"

local pallete = require "pallete"
local g = love.graphics

local pviewer = {}
pviewer.__index = pviewer

function pviewer.new()
    local self = {
        border = 40, --y axis border in pixels for drawing chart
        font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
        activeIndex = 0, -- обработай случаи если таблица истории пустая
    }
    self.w, self.h = g.getDimensions()
    return setmetatable(self, pviewer)
end

function pviewer:init(save_name)
    print("save_name", save_name)
    self.save_name = save_name
    self:resize(g.getDimensions())
    self.timer = timer()
end

-- создает новый экземпляр просмотрщика статистики для текущего положения
-- индекса pviewer.activeIndex
function pviewer:updateRender(index)
    if self.data and index >= 1 and index <= #self.data then
        local data = self.data[index]
        self.statisticRender = require "drawstat".new({
            signals = data.signals,
            pressed = data.pressed,
            level = data.level,
            pause_time = data.pause_time,

            x0 = 0,
            y0 = 0,
            font = nback.font,
            border = nback.border,
            durationMin = 0,
            durationSec = 0,
        })
    else
        self.statisticRender = nil
    end
end

local function removeDataWithoutDateField(data)
    local cleanedData = {}
    for k, v in pairs(data) do
        if v.date then
            cleanedData[#cleanedData + 1] = v
        end
    end
    return cleanedData
end

function pviewer:makeList()
    self.list = require "pviewer_list":new(self.layout.left.x, self.layout.left.y, self.layout.left.w, self.layout.left.h)
    self.list.onclick = function(item, idx)
        self:updateRender(idx)
    end
    for k, v in pairs(self.data) do
        local item = self.list:add("hui", "xo")
        item.data = v
        item.color = pallete.levelColors[v.level]
        --item.ondraw = function(self, item, rx, ry, rw, rh)
            ----print("item", inspect(item))
            --if item.color then
                --g.setColor(item.color)
            --else
                --g.setColor(pallete.pviewerUnknown)
            --end
            --g.rectangle("fill", rx, ry, rw, rh)
            --g.setColor(pallete.pviewerItemText)
            --g.print(compareDates(os.date("*t"), item.data.date), rx, ry)
        --end
    end
    self.list:done()
end

function pviewer:sortByDate()
    table.sort(self.data, function(a, b)
        print("a, b", inspect(a), inspect(b))
        a, b = a.date, b.date
        return a.year * 365 * 24 + a.yday * 24 + a.hour >
            b.year * 365 * 24 + b.yday * 24 + b.hour
    end)
end

function pviewer:enter()
    print("pviewer:enter()")
    local tmp, size = love.filesystem.read(self.save_name)
    if tmp ~= nil then
        ok, self.data = serpent.load(tmp)
        print("pviewer.data", inspect(self.data))
        if not ok then 
            -- эту строчку с падением при ошибке заменить на показ пустой
            -- статистики.
            error("Something wrong in restoring data " .. self.save_name)
        end
    else
        self.data = {}
    end
    self:sortByDate()
    self:makeList()
    self.data = removeDataWithoutDateField(self.data)
    self.activeIndex = #self.data >= 1 and 1 or 0
    self:updateRender(1)
end

function pviewer:leave()
    print("pviewer:leave()")
    self.data = nil
end

function pviewer:resize(neww, newh)
    print(string.format("pviewer.resize(%d, %d)", neww, newh))
    w, h = neww, newh
    self:buildLayout()
    -- обрати внимание на размер создаваемого полотна. Взят от балды.
    self.rt = g.newCanvas(w, h, {format = "normal", msaa = 4})
    if not self.rt then
        error("Sorry, canvases are not supported!")
    end
end

function pviewer:buildLayout()
    local screen = {}
    screen.left, screen.right = splitv(makeScreenTable(), 0.2, 0.8)
    screen.right.x = screen.right.x + 3
    screen.right.w = screen.right.w - 3
    screen.top, screen.bottom = splith(screen.right, 0.1, 0.9)
    self.layout = screen
end

function pviewer:draw()
    g.push("all")

    g.clear(pallete.background)
    local oldFont = g.getFont()
    g.setFont(self.font)

    self.list:draw()
    g.setColor{1, 1, 1}
    g.setCanvas(self.rt)
    g.clear(pallete.background)
    if self.statisticRender then
        self.statisticRender:beforeDraw()
        local y = self.layout.bottom.y + (self.layout.bottom.h - self.statisticRender:getHitsRectHeight()) / 2
        self.statisticRender:drawHits(self.layout.bottom.x, y)
    end
    g.setCanvas()
    g.setColor{1, 1, 1}
    g.draw(self.rt)

    g.setFont(oldFont)
    g.pop()
end

-- перемотка на страницу вверх
function pviewer:pageUp()
end

-- перемотка на страницу вниз
function pviewer:pageDown()
end

-- сместить курсор на строчку вверх
function pviewer:scrollUp()
    if self.activeIndex - 1 >= 1 then
        self.activeIndex = self.activeIndex - 1
        self:updateRender(self.activeIndex)
    end
end

-- сместить курсор на строчку вниз
function pviewer:scrollDown()
    if self.activeIndex + 1 <= #self.data then
        self.activeIndex = self.activeIndex + 1
        self:updateRender(self.activeIndex)
    end
end

-- добавить клавиши управления для постраничной прокрутки списка результатов.
function pviewer:keypressed(_, key)
    if key == "escape" or key == "acback" then
        menu:goBack()
    elseif key == "return" or key == "space" then
        -- TODO по нажатию клавиши показать конечную таблицу игры
    elseif key == "home" or key == "kp7" then
    elseif key == "end" or key == "kp1" then
    elseif key == "up" or key == "k" then
        self:scrollUp()
    elseif key == "down" or key == "j" then
        self:scrollDown()
    elseif key == "pageup" then
        self:pageUp()
    elseif key == "pagedown" then
        self:pageDown()
    end
end

function pviewer:wheelmoved(x, y)
    if self.list then
        self.list:wheelmoved(x, y)
    end
end

function pviewer:mousepressed(x, y, btn, istouch)
    if self.list then
        self.list:mousepressed(x, y, btn, istouch)
    end
end

function pviewer:mousereleased(x, y, btn, istouch)
    if self.list then
        self.list:mousereleased(x, y, btn, istouch)
    end
end

function pviewer:moved(x, y, dx, dy)
    if self.list then
        self.list:mousemoved(x, y, dx, dy)
    end
end

function pviewer:update(dt)
    local kb = love.keyboard
    --if kb.isDown("up", "k") then
        --self:scrollUp()
    --elseif kb.isDown("down", "j") then
        --self:scrollDown()
    --elseif kb.isDown("pageup") then
        --self:pageUp()
    --elseif kb.isDown("pagedown") then
        --self:pageDown()
    --end

    self.timer:update(dt)
end

return {
    new = pviewer.new
}
