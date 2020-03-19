local pallete = require "pallete"

local statisticRender = {}
statisticRender.__index = statisticRender

-- x, y - координаты левого верхнего угла отрисовываемой картинки.
-- arr - массив со значениями чего?
-- eq - массив-наложение на arr, для успешных попаданий?
-- rect_size - размер отображаемого в сетке прямоугольника
-- border - зазор между прямоугольниками.
-- что за пару x, y возвращает функция?
local function draw_hit_rects(x, y, pressed_arr, eq_arr, 
    rect_size, border, level)
    local g = love.graphics
    local hit_color = {200 / 255, 10 / 255, 10 / 255}
    for k, v in pairs(pressed_arr) do
        g.setColor(pallete.field)
        g.rectangle("line", x + rect_size * (k - 1), y, rect_size, rect_size)
        g.setColor(pallete.inactive)
        g.rectangle("fill", x + rect_size * (k - 1) + border, y + border, 
            rect_size - border * 2, rect_size - border * 2)

        -- отмеченная игроком позиция
        if v then
            g.setColor(hit_color)
            g.rectangle("fill", x + rect_size * (k - 1) + border, y + border, 
                rect_size - border * 2, rect_size - border * 2)
        end

        -- правильная позиция нажатия
        if eq_arr[k] then
            local radius = 4
            g.setColor{0, 0, 0}
            g.circle("fill", x + rect_size * (k - 1) + rect_size / 2, 
                y + rect_size / 2, radius)
            -- кружок на место предудущего сигнала
            g.setColor{1, 1, 1, 0.5}
            g.circle("line", x + rect_size * ((k - level) - 1) + rect_size / 2, 
                y + rect_size / 2, radius)
        end
    end

    -- этот код должен быть в вызывающей функции
    y = y + rect_size + 6
    return x, y
end

-- draw one big letter in left side of hit rects output
function print_signal_type(x, y, rect_size, str, pixel_gap, delta)
    local delta = (rect_size - g.getFont():getHeight()) / 2
    g.print(str, x - g.getFont():getWidth(str) - pixel_gap, y + delta)
    y = y + rect_size + 6
    return x, y
end

-- рисовать статистику после конца сета
function draw_statistic(font, signals, pressed, level)
    local w, h = g.getDimensions()

    g.setFont(font)
    g.setColor(pallete.statistic)

    local width_k = 3 / 4
    -- XXX depend on screen resolution
    local rect_size = math.floor(w * width_k / #signals.pos)

    --print("rect_size", rect_size)
    --print("self.statisticRender", self.statisticRender)

    local x = self.statisticRender and 0 or (w - w * width_k) / 2

    --local x = (w - w * width_k) / 2 

    local starty = self.statisticRender and 0 or 200
    local y = starty + g.getFont():getHeight() * 1.5
    local border = 2
    local freezedY = y

    x, y = draw_hit_rects(x, y, pressed.sound, signals.eq.sound, rect_size, border, level)
    x, y = draw_hit_rects(x, y, pressed.color, signals.eq.color, rect_size, border, level)
    x, y = draw_hit_rects(x, y, pressed.form, signals.eq.form, rect_size, border, level)
    x, y = draw_hit_rects(x, y, pressed.pos, signals.eq.pos, rect_size, border, level)

    -- drawing left column with letters
    g.setColor({200 / 255, 0, 200 / 255})

    local y = freezedY
    local pixel_gap = 10
    x, y = print_signal_type(x, y, rect_size, "S", pixel_gap, delta) 
    x, y = print_signal_type(x, y, rect_size, "C", pixel_gap, delta) 
    x, y = print_signal_type(x, y, rect_size, "F", pixel_gap, delta) 
    x, y = print_signal_type(x, y, rect_size, "P", pixel_gap, delta)

    if not self.statisticRender then
        x, y = self:draw_percents(x, freezedY + 0, rect_size, pixel_gap, border, 
        starty)

        local y = self.y0 + self.font:getHeight()
        --g.printf(string.format("Set results:"), 0, y, w, "center")
        y = y + self.font:getHeight()
        g.printf(string.format("Level %d Exposition %1.f sec", self.level, self.pause_time), 0, y, w, "center")
        --[[y = y + self.font:getHeight()]]
        --[[g.printf(string.format("Exposition time %.1f sec", self.pause_time), ]]
        --[[0, y, w, "center")]]
        y = y + self.font:getHeight()
        if self.durationMin and self.durationSec then
            g.printf(string.format("Duration %d min %d sec.", self.durationMin, self.durationSec), 0, y, w, "center")
        end
    end

    drawHierachy(self.layout)
end

function statisticRender:buildLayout()
    require "layout"
    local screen = makeScreenTable()
    screen.top, screen.middle, screen.bottom = splith(screen, 0.2, 0.7, 0.1)
    self.layout = screen
end

function statisticRender.new()
    local self = setmetatable({}, statisticRender)
    self:buildLayout()
end

return statisticRender
--[[return { ]]
    --[[draw_hit_rects = draw_hit_rects,]]
    --[[draw_statistic = draw_statistic,]]
--[[}]]
