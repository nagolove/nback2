﻿local inspect = require "libs.inspect"

require "gooi.gooi"

local pallete = require "pallete"
local g = love.graphics

local statisticRender = {}
statisticRender.__index = statisticRender

-- подсчет процентов успешности за раунд для данного массива.
-- eq - массив с правильными нажатиями
-- pressed_arr - массив с нажатиями игрока
function calc_percent(eq, pressed_arr)
    if not eq then return 0 end --0% если не было нажатий
    local succ, mistake, count = 0, 0, 0
    for k, v in pairs(eq) do
        if v then
            count = count + 1
        end
        if v and pressed_arr[k] then
            succ = succ + 1
        end
        if not v and pressed_arr[k] then
            mistake = mistake + 1
        end
    end
    print(string.format("calc_percent() count = %d, succ = %d, mistake = %d", count, succ, mistake))
    return succ / count - mistake / count
end

function statisticRender:getHitQuadLineHeight()
    return self.rect_size + 12
end

-- x, y - координаты левого верхнего угла отрисовываемой картинки.
-- type - строка "pos", "sound", etc.
function statisticRender:drawHitQuads(x, y, type, border)
    local rect_size = self.rect_size
    local eq_arr = self.signals.eq[type]
    for k, v in pairs(self.pressed[type]) do
        g.setColor(pallete.field)
        g.rectangle("line", x + rect_size * (k - 1), y, rect_size, rect_size) 
        g.setColor(pallete.inactive)
        g.rectangle("fill", x + rect_size * (k - 1) + border, y + border, rect_size - border * 2, rect_size - border * 2)

        -- отмеченная игроком позиция
        if v then
            g.setColor(pallete.hit_color)
            g.rectangle("fill", x + rect_size * (k - 1) + border, y + border, rect_size - border * 2, rect_size - border * 2)
        end

        -- правильная позиция нажатия
        if eq_arr[k] then
            local radius = 4
            g.setColor{0, 0, 0}
            g.circle("fill", x + rect_size * (k - 1) + rect_size / 2, y + rect_size / 2, radius)
            -- кружок на место предудущего сигнала
            g.setColor{1, 1, 1, 0.5}
            g.circle("line", x + rect_size * ((k - self.level) - 1) + rect_size / 2, y + rect_size / 2, radius)
        end
    end

    -- этот код должен быть в вызывающей функции
    y = y + self:getHitQuadLineHeight()
    return x, y
end

function statisticRender:preparePrintingSignalsType(signalType)
    function prepare(signalType)
        local loc = i18n(signalType) or ""
        local str =  loc .. "  " 
        local strWidth = g.getFont():getWidth(str)
        local formatStr = "%.3f"
        print("self.percent", inspect(self.percent))
        return string.format(formatStr, self.percent[signalType]), x + strWidth, y
    end
    local tbl = {}
    table.insert(tbl, prepare("pos"))
    table.insert(tbl, prepare("sound"))
    table.insert(tbl, prepare("color"))
    table.insert(tbl, prepare("form"))
    self.printingSignalsPrepared = tbl
end

function processTouches()
    local i = 0
    local tbl = {}
    for k, v in pairs(touches) do
        if i < 2 then
            table.insert(tbl, v)
            i = i + 1
        end
    end
    if #tbl == 2 then
        cam:move(-tbl[1].dx, -tbl[1].dy)
    end
end

function statisticRender:update(dt)
    processTouches()
    gooi.update(dt)
end

-- draw one big letter in left side of hit rects output
function statisticRender:printSignalType(x, y, signalType)
    local loc = i18n(signalType) or ""
    local str =  loc .. "  " 
    local strWidth = g.getFont():getWidth(str)
    g.setColor(pallete.statisticSignalType)
    g.print(str, x, y)
    g.setColor(pallete.percentFont)
    --print("self.percent", inspect(self.percent))
    g.print(string.format("%.3f", self.percent[signalType]), x + strWidth, y)
end

-- рисовать статистику после конца сета
function statisticRender:draw()
    local w = g.getWidth()

    g.setFont(self.font)
    g.setColor(pallete.statistic)
    g.setLineWidth(1)

    local x = (w - w * self.width_k) / 2 
    local fontHeight = g.getFont():getHeight()
    local y = self.layout.middle.y + (self.layout.middle.h - (fontHeight + self:getHitQuadLineHeight()) * 4) / 2
    local border = 2

    self:printSignalType(x, y, "sound") 
    y = y + fontHeight
    self:drawHitQuads(x, y, "sound", border)
    y = y + self:getHitQuadLineHeight()

    self:printSignalType(x, y, "color") 
    y = y + fontHeight
    self:drawHitQuads(x, y, "color", border)
    y = y + self:getHitQuadLineHeight()

    self:printSignalType(x, y, "form") 
    y = y + fontHeight
    self:drawHitQuads(x, y, "form", border)
    y = y + self:getHitQuadLineHeight()

    self:printSignalType(x, y, "position") 
    y = y + fontHeight
    self:drawHitQuads(x, y, "pos", border)

    self:printInfo()

    g.setColor{0.5, 0.5, 0.5}
    drawHierachy(self.layout)

    gooi.draw()
end

function statisticRender:printInfo()
    local str1, str2 = string.format("Level %d Exposition %1.f sec", self.level, self.pause_time),
        string.format("Duration %d min %d sec.", self.durationMin, self.durationSec)
    local width1, width2 = g.getFont():getWidth(str1), g.getFont():getWidth(str2)
    local textsHeight = g.getFont():getHeight() * 2
    local x1, x2 = (self.layout.top.w - width1) / 2, (self.layout.top.w - width2) / 2
    local y = (self.layout.top.h - textsHeight) / 2
    g.print(str1, x1, y)
    y = y + g.getFont():getHeight()
    g.print(str2, x2, y)
end

function statisticRender:buildLayout()
    local screen = makeScreenTable()
    screen.top, screen.middle, screen.bottom = splith(screen, 0.2, 0.7, 0.1)
    screen.bottom.left, screen.bottom.right = splitv(screen.bottom, 0.5, 0.5)
    self.layout = screen
end

function statisticRender:percentage()
    local p
    self.percent = {}
    p =  calc_percent(self.signals.eq.sound, self.pressed.sound)
    self.percent.sound = p > 0.0 and p or 0.0
    p = calc_percent(self.signals.eq.color, self.pressed.color)
    self.percent.color = p > 0.0 and p or 0.0
    p = calc_percent(self.signals.eq.form, self.pressed.form)
    self.percent.form = p > 0.0 and p or 0.0
    p = calc_percent(self.signals.pos.eq, self.pressed.pos)
    self.percent.position = p > 0.0 and p or 0.0
    self.percent.common = (self.percent.sound + self.percent.color + 
        self.percent.form + self.percent.form) / 4
end

function statisticRender:keypressed(_, key, isrepeat)
    gooi.keypressed(_, key, isrepeat)
end

function statisticRender:keyreleased(_, key)
    gooi.keyreleased(_, key)
end

function statisticRender:mousepressed(x, y, button)
    gooi.pressed()
end

function statisticRender:mousereleased(x, y, button)
    gooi.released()
end

function statisticRender.new(nback)
    local self = setmetatable({
        font = nback.font,
        signals = nback.signals,
        pressed = nback.pressed,
        level = nback.level,
        pause_time = nback.pause_time,
        x0 = nback.x0,
        y0 = nback.y0,
        durationMin = nback.durationMin,
        durationSec = nback.durationSec,
    }, statisticRender)
    -- должен быть минимальный размер, не слишком мелкий если не все 
    --квадраты умещаются в ширину экрана
    self.width_k = 3.9 / 4
    self.rect_size = math.floor(w * self.width_k / #self.signals.pos)
    self:percentage()
    self:buildLayout()

    print("self.layout.bottom", inspect(self.layout.bottom))

    gooi.setStyle({ font = g.newFont("gfx/DroidSansMono.ttf", 13),
        showBorder = true,
        bgColor = {0.208, 0.220, 0.222},
    })

    local mainMenuBtnLayout = shrink(self.layout.bottom.right, nback.border)
    self.mainMenuBtn = gooi.newButton({ text = "Return to menu",
        x = mainMenuBtnLayout.x, y = mainMenuBtnLayout.y, 
        w = mainMenuBtnLayout.w, h = mainMenuBtnLayout.h})
        :onRelease(function()
            linesbuf:push(1, "return to main!")
            menu:goBack()
        end)

    return self
end

return statisticRender
