local inspect = require "libs.inspect"

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
function statisticRender:draw_hit_rects(x, y, type, border)
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

-- draw one big letter in left side of hit rects output
function statisticRender:printSignalType(x, y, str)
    --print("printSignal", delta)
    local rect_size = self.rect_size
    local delta = (rect_size - g.getFont():getHeight()) / 2
    ----g.print(str, x - g.getFont():getWidth(str) - pixel_gap, y + delta)
    --g.print(str, x, y + delta)
    g.print(str, x, y)
    --y = y + rect_size + 6
    --return x, y
end

function statisticRender:drawPercents(x, y, pixel_gap, border, starty)
    local rect_size = self.rect_size
    local sx = x + rect_size * (#self.signals.pos - 1) + border + rect_size 
    - border * 2 + pixel_gap
    local formatStr = "%.3f"

    g.setColor(pallete.percentFont)
    g.setFont(self.font)

    -- эти условия нужно как-то убрать или заменить на что-то
    if self.sound_percent then
        g.print(string.format(formatStr, self.sound_percent), sx, y)
        y = y + rect_size + 6
    end
    if self.color_percent then
        g.print(string.format(formatStr, self.color_percent), sx, y)
        y = y + rect_size + 6
    end
    if self.form_percent then
        g.print(string.format(formatStr, self.form_percent), sx, y)
        y = y + rect_size + 6
    end
    if self.pos_percent then
        g.print(string.format(formatStr, self.pos_percent), sx, y)
        y = starty + 4 * (rect_size + 20)
    end
    --[[if not self.statisticRender then]]
        --[[g.printf(string.format("rating " .. formatStr, self.percent), 0, y, w, "center")]]
    --[[end]]
    return x, y
end

-- рисовать статистику после конца сета
function statisticRender:draw()
    local w, h = g.getDimensions()

    g.setFont(self.font)
    g.setColor(pallete.statistic)
    g.setLineWidth(1)

    local width_k = 3.9 / 4
    local signalsCount = #self.signals.pos

    self.rect_size = math.floor(w * width_k / signalsCount)

    local x = (w - w * width_k) / 2 

    --[[local starty = self.statisticRender and 0 or 200]]
    local fontHeight = g.getFont():getHeight()
    local starty = self.layout.middle.y + (self.layout.middle.h - (fontHeight + self:getHitQuadLineHeight()) * 4) / 2
    local y = starty
    local border = 2
    local freezedY = y
    local pixel_gap = 10

    if not __ONCE__ then
        __ONCE__ = true
        print("getColor()", inspect({g.getColor()}))
    end

    self:printSignalType(x, y, "Sound") 
    y = y + fontHeight
    self:draw_hit_rects(x, y, "sound", border)
    y = y + self:getHitQuadLineHeight()

    self:printSignalType(x, y, "Color") 
    y = y + fontHeight
    self:draw_hit_rects(x, y, "color", border)
    y = y + self:getHitQuadLineHeight()

    self:printSignalType(x, y, "Form") 
    y = y + fontHeight
    self:draw_hit_rects(x, y, "form", border)
    y = y + self:getHitQuadLineHeight()

    self:printSignalType(x, y, "Position") 
    y = y + fontHeight
    self:draw_hit_rects(x, y, "pos", border)
    y = y + self:getHitQuadLineHeight()

    -- drawing left column with letters
    g.setColor({200 / 255, 0, 200 / 255})

    local y = freezedY
    --x, y = self:print_signal_type(x, y, "C", pixel_gap, delta) 
    --x, y = self:print_signal_type(x, y, "F", pixel_gap, delta) 
    --x, y = self:print_signal_type(x, y, "P", pixel_gap, delta)

    x, y = self:drawPercents(x, freezedY + 0, pixel_gap, border, starty)

    self:printInfo()

    g.setColor{0.5, 0.5, 0.5}
    drawHierachy(self.layout)
end

function statisticRender:printInfo()
    local str1, str2 = string.format("Level %d Exposition %1.f sec", self.level, self.pause_time),
        string.format("Duration %d min %d sec.", self.durationMin, self.durationSec)
    local width1, width2 = g.getFont():getWidth(str1), g.getFont():getWidth(str2)
    local textsHeight = g.getFont():getHeight() * 2
    local x1, x2 = (self.layout.top.w - width1) / 2, (self.layout.top.w - width2) / 2
    local y = (self.layout.top.h - textsHeight) / 2
    --g.printf(str1, , y, w, "center")
    g.print(str1, x1, y)
    y = y + g.getFont():getHeight()
    g.print(str2, x2, y)
    --g.printf(str2, 0, y, w, "center")
end

function statisticRender:buildLayout()
    local screen = makeScreenTable()
    screen.top, screen.middle, screen.bottom = splith(screen, 0.2, 0.7, 0.1)
    self.layout = screen
end

function statisticRender:percentage()
    local p

    p =  calc_percent(self.signals.eq.sound, self.pressed.sound)
    self.sound_percent = p > 0.0 and p or 0.0

    p = calc_percent(self.signals.eq.color, self.pressed.color)
    self.color_percent = p > 0.0 and p or 0.0

    p = calc_percent(self.signals.eq.form, self.pressed.form)
    self.form_percent = p > 0.0 and p or 0.0

    p = calc_percent(self.signals.pos.eq, self.pressed.pos)
    self.pos_percent = p > 0.0 and p or 0.0

    self.percent = (self.sound_percent + self.color_percent + 
    self.form_percent + self.pos_percent) / 4
end

--[[function statisticRender.new(font, signals, pressed, level, pause_time)]]
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
    self:percentage()
    self:buildLayout()
    return self
end

return statisticRender
