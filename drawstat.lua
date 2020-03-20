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


-- x, y - координаты левого верхнего угла отрисовываемой картинки.
-- arr - массив со значениями чего?
-- eq - массив-наложение на arr, для успешных попаданий?
-- rect_size - размер отображаемого в сетке прямоугольника
-- border - зазор между прямоугольниками.
-- что за пару x, y возвращает функция?
function statisticRender:draw_hit_rects(x, y, pressed_arr, eq_arr, rect_size, border, level)
    for k, v in pairs(pressed_arr) do
        g.setColor(pallete.field)
        g.rectangle("line", x + rect_size * (k - 1), y, rect_size, rect_size) g.setColor(pallete.inactive)
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
            g.circle("line", x + rect_size * ((k - level) - 1) + rect_size / 2, y + rect_size / 2, radius)
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

function statisticRender:draw_percents(x, y, rect_size, pixel_gap, border, starty)
    local sx = x + rect_size * (#self.signals.pos - 1) + border + rect_size 
    - border * 2 + pixel_gap
    local formatStr = "%.3f"

    g.setColor({200 / 255, 0, 200 / 255})
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

    local width_k = 3 / 4
    -- XXX depend on screen resolution
    local signalsCount = #self.signals.pos
    local rect_size = math.floor(w * width_k / signalsCount)

    --print("rect_size", rect_size)
    --print("self.statisticRender", self.statisticRender)
    --[[local x = self.statisticRender and 0 or (w - w * width_k) / 2]]
    --[[local x = self.statisticRender and 0 or (w - w * width_k) / 2]]
    --
    local x = (w - w * width_k) / 2 

    --[[local starty = self.statisticRender and 0 or 200]]
    local starty = 200
    local y = starty + g.getFont():getHeight() * 1.5
    local border = 2
    local freezedY = y

    x, y = self:draw_hit_rects(x, y, self.pressed.sound, self.signals.eq.sound, rect_size, border, self.level)
    x, y = self:draw_hit_rects(x, y, self.pressed.color, self.signals.eq.color, rect_size, border, self.level)
    x, y = self:draw_hit_rects(x, y, self.pressed.form, self.signals.eq.form, rect_size, border, self.level)
    x, y = self:draw_hit_rects(x, y, self.pressed.pos, self.signals.eq.pos, rect_size, border, self.level)

    -- drawing left column with letters
    g.setColor({200 / 255, 0, 200 / 255})

    local y = freezedY
    local pixel_gap = 10
    x, y = print_signal_type(x, y, rect_size, "S", pixel_gap, delta) 
    x, y = print_signal_type(x, y, rect_size, "C", pixel_gap, delta) 
    x, y = print_signal_type(x, y, rect_size, "F", pixel_gap, delta) 
    x, y = print_signal_type(x, y, rect_size, "P", pixel_gap, delta)

    --[[if not self.statisticRender then]]
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
    --[[end]]

    drawHierachy(self.layout)
end

function statisticRender:buildLayout()
    --[[require "layout"]]
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
    }, statisticRender)
    self:percentage()
    self:buildLayout()
    return self
end

return statisticRender
--[[return { ]]
    --[[draw_hit_rects = draw_hit_rects,]]
    --[[draw_statistic = draw_statistic,]]
--[[}]]
