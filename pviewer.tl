require "love"
require "common"
require "drawstat"
require "nback"
require "layout"
require "button"

local i18n = require "i18n"
local inspect = require "inspect"
local serpent = require "serpent"
--local timer = require "Timer"
local pallete = require "pallete"
local g = love.graphics
local cam = require "camera".new()
local List = require "pviewer_list"
local fonts = require "fonts"

global __MORE_DATA__ = false

global type Pviewer = record
    font: love.graphics.Font
    w: number
    h: number
    activeIndex: integer
    save_name: string
    timer: Timer
    data: {History}
    statisticRender: StatisticRender
    list: List
    layout: Layout
    layout_nodata: Layout
    backButton: Button
    rt: g.Canvas

    init:function(Pviewer, string)
    leave: function(Pviewer)
    resize: function(Pviewer, number, number)
    buildLayout: function(Pviewer)
    enter: function(Pviewer)
    sortByDate: function(Pviewer)
    updateRender: function(Pviewer, integer)
end

local pviewer_mt: metatable<Pviewer> = {
    __index = Pviewer
}

function Pviewer.new(): Pviewer
    local self: Pviewer = {
        font = require "fonts".pviewer,
        activeIndex = 0, -- обработай случаи если таблица истории пустая
    }
    self.w, self.h = g.getDimensions()
    return setmetatable(self, pviewer_mt)
end

function Pviewer:init(save_name: string)
    print("save_name", save_name)
    self.save_name = save_name
    self:resize(g.getDimensions())
    --local Timer = require 'Timer'.new
    --print('Timer', inspect(Timer))
    self.timer = require 'Timer'.new()
end

-- создает новый экземпляр просмотрщика статистики для текущего положения
-- индекса pviewer.activeIndex
function Pviewer:updateRender(index: integer)
    print("updateRender()", index)
    if self.data and index >= 1 and index <= #self.data then
        local data = self.data[index]
        self.statisticRender = require "drawstat".new({
            signals = data.signals,
            pressed = data.pressed,
            level = data.level,
            pause_time = data.pause_time,

            x0 = 0,
            y0 = 0,
            --font = nback.font,
            font = self.font,
            border = nback.border,
            durationMin = 0,
            durationSec = 0,
        })
    else
        self.statisticRender = nil
    end
end

local function removeDataWithoutDateField(data: {History}): {History}
    local cleanedData = {}
    for _, v in ipairs(data) do
        if v.date then
            cleanedData[#cleanedData + 1] = v
        end
    end
    return cleanedData
end

function Pviewer:makeList()
    if #self.data ~= 0 then
        self.list = List.new(self.layout.left.x, self.layout.left.y, 
            self.layout.left.w, self.layout.left.h, fonts.pviewer)
        self.list.onclick = function(_: List, idx: number, _: number)
            self:updateRender(math.floor(idx))
        end

        local str: string
        for _, v in ipairs(self.data) do
            str = compareDates(os.date("*t"), v.date)

            --if k == 1 then
            --str = "-- " .. tostring(k) .. string.format(" (%d) ..", #self.data)
            --else
            --str = "-- " .. tostring(k) .. " .."
            --end
            
            local item = self.list:add(str)
            item.data = v
            --item.color = pallete.levelColors[v.level]
            item.colors = pallete.levelColors[v.level]
        end

        self.list:done()
        self.list.onclick(nil, 1)
    end
end

function Pviewer:sortByDate()
    table.sort(self.data, function(h1: History, h2: History): boolean
        local a, b = h1.date, h2.date
        return a.year * 365 * 24 + a.yday * 24 + a.hour > b.year * 365 * 24 + b.yday * 24 + b.hour
    end)
end

function Pviewer:enter()
    print("pviewer:enter()")
    local tmp, _ = love.filesystem.read(self.save_name)
    if tmp ~= nil then
        --local ok, self.data = serpent.load(tmp) as (boolean, {History})
        local ok, t = serpent.load(tmp) as (boolean, {History})
        self.data = t
        if not ok then 
            -- эту строчку с падением при ошибке заменить на показ пустой
            -- статистики.
            error("Something wrong in restoring data " .. self.save_name)
        end
    else
        self.data = {}
    end

    -------------------------------------------
    __MORE_DATA__ = false
    --__MORE_DATA__ = true
    if __MORE_DATA__ then
        local tmp2 = {}
        for _ = 1, 6 do
            for _, v in ipairs(self.data) do
                table.insert(tmp2, v)
            end
        end
        self.data = tmp2
    end
    -------------------------------------------
 
    --[[
    gooi.components = {}
    gooi.setStyle({ font = self.font,
        showBorder = true,
        bgColor = {0.208, 0.220, 0.222},
    })
    if #self.data == 0 then
        self.backButton = gooi.newButton({ text = i18n("backToMainMenu"),
            x = self.layout.nodata.top.x,
            y = self.layout.nodata.top.y,
            w = self.layout.nodata.top.w,
            h = self.layout.nodata.top.h
        }):onRelease(function()
            menu:goBack()
        end)
    else
        self.backButton = gooi.newButton({ text = i18n("backToMainMenu"),
            x = self.layout.top.x,
            y = self.layout.top.y,
            w = self.layout.top.w,
            h = self.layout.top.h
        }):onRelease(function()
            menu:goBack()
        end)
    end
    --]]

    if #self.data == 0 then
        self.backButton = Button.new(
            i18n("backToMainMenu"),
            ((self.layout as {any:any}).nodata as Layout).top.x,
            ((self.layout as {any:any}).nodata as Layout).top.y,
            ((self.layout as {any:any}).nodata as Layout).top.w,
            ((self.layout as {any:any}).nodata as Layout).top.h)
    else
        self.backButton = Button.new(
            i18n("backToMainMenu"),
            self.layout.top.x,
            self.layout.top.x,
            self.layout.top.x,
            self.layout.top.x)
    end

    self.backButton.onMouseReleased = function()
        menu:goBack()
    end
    self.backButton.bgColor = {0.208, 0.220, 0.222}
    self.backButton.font = self.font

    self:sortByDate()
    self:makeList()
    self.data = removeDataWithoutDateField(self.data)
    self.activeIndex = #self.data >= 1 and 1 or 0
    self:updateRender(1)
end

function Pviewer:leave()
    print("pviewer:leave()")
    self.data = nil
end

function Pviewer:resize(neww: number, newh: number)
    --print(string.format("pviewer.resize(%d, %d)", neww, newh))
    local w, h = neww, newh
    self:buildLayout()
    -- обрати внимание на размер создаваемого полотна. Взят от балды.
    self.rt = g.newCanvas(w, h, {format = "normal", msaa = 4})
    if not self.rt then
        error("Sorry, canvases are not supported!")
    end
end

function Pviewer:buildLayout()
    local screen: Layout = {}
    screen.left, screen.right = splitv(makeScreenTable(), 0.2, 0.8)
    screen.right.x = screen.right.x + 3
    screen.right.w = screen.right.w - 3
    screen.top, screen.bottom = splith(screen.right, 0.1, 0.9)

    self.layout_nodata = {}
    self.layout_nodata.top, self.layout_nodata.bottom = splith(makeScreenTable(), 0.2, 0.8)
    self.layout_nodata.top = shrink(self.layout_nodata.top, 3)

    self.layout = screen
end

function Pviewer:drawNodata()
    local str = i18n("nodata")
    g.setFont(self.font)
    g.setColor{0, 0, 0, 1}
    g.printf(str, 0, self.layout_nodata.bottom.y, self.layout_nodata.bottom.w, "center")
end

function Pviewer:draw()
    g.push("all")

    g.clear(pallete.background)
    tiledback:draw(0.3)
    --g.setFont(self.font)

    if #self.data == 0 then
        self:drawNodata()
        self.backButton:draw()
    else
        self.list:draw()

        g.setColor{1, 1, 1}
        g.setCanvas(self.rt)
        g.clear(pallete.background)
        cam:attach()
        if self.statisticRender then
            self.statisticRender:beforeDraw()
            local y = self.layout.bottom.y + (self.layout.bottom.h - self.statisticRender:getHitsRectHeight()) / 2
            self.statisticRender:drawHits(self.layout.bottom.x, y)
        end
        cam:detach()
        g.setCanvas()

        g.setColor{1, 1, 1}

        g.draw(self.rt as g.Drawable)
    end

    g.pop()
end

-- добавить клавиши управления для постраничной прокрутки списка результатов.
function Pviewer:keypressed(key: string)
    if key == "escape" or key == "acback" then
        menu:goBack()
    elseif key == "return" or key == "space" then
        -- TODO по нажатию клавиши показать конечную таблицу игры
    elseif key == "home" or key == "kp7" then
    elseif key == "end" or key == "kp1" then
    elseif key == "up" or key == "k" then
        -- TODO
        --self.list:scrollUp()
    elseif key == "down" or key == "j" then
        -- TODO
        --self.list:scrollDown()
    end
end

function Pviewer:wheelmoved(x: number, y: number)
    if self.list then
        self.list:wheelmoved(x, y)
    end
end

function Pviewer:mousepressed(x: number, y: number, btn: number, _: boolean)
    if self.list then
        self.list:mousepressed(x, y, btn)
    else
        self.backButton:mousePressed()
    end
end

function Pviewer:mousereleased(x: number, y: number, btn: number, _: boolean)
    if self.list then
        self.list:mousereleased(x, y, btn)
    else
        self.backButton:mouseReleased()
    end
end

function Pviewer:mousemoved(x: number, y: number, dx: number, dy: number)
    local mouse = love.mouse
    if mouse.isDown(2) then
        cam:move(-dx, -dy)
    end
    if self.list then
        self.list:mousemoved(x, y, dx, dy)
    end
end

--[[
function Pviewer:touchpressed(id, x, y)
    if self.list then
        self.list:touchpressed(id, x, y)
    end
end

function Pviewer:touchreleased(id, x, y)
    if self.list then
        self.list:touchreleased(id, x, y)
    end
end

function Pviewer:touchmoved(id, x, y, dx, dy)
    if self.list then
        self.list:touchmoved(id, x, y, dx, dy)
    end
end
--]]

function Pviewer:update(dt: number)
    self.backButton:update(dt)
    self.timer:update(dt)
end

--return {
    --new = Pviewer.new
--}

global pviewer: Pviewer = Pviewer.new()
