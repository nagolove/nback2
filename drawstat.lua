local inspect = require "libs.inspect"

require "gooi.gooi"

local pallete = require "pallete"
local g = love.graphics

local statisticRender = {}
statisticRender.__index = statisticRender

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
        --print("self.percent", inspect(self.percent))
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

function statisticRender:drawHits(x, y)
    self:printSignalType(x, y, "sound") 
    y = y + self.fontHeight
    self:drawHitQuads(x, y, "sound", self.border)
    y = y + self:getHitQuadLineHeight()

    self:printSignalType(x, y, "color") 
    y = y + self.fontHeight
    self:drawHitQuads(x, y, "color", self.border)
    y = y + self:getHitQuadLineHeight()

    self:printSignalType(x, y, "form") 
    y = y + self.fontHeight
    self:drawHitQuads(x, y, "form", self.border)
    y = y + self:getHitQuadLineHeight()

    self:printSignalType(x, y, "pos") 
    y = y + self.fontHeight
    self:drawHitQuads(x, y, "pos", self.border)
end

function statisticRender:getHitsRectHeight()
    return (self.fontHeight + self:getHitQuadLineHeight()) * 4
end

function statisticRender:beforeDraw()
    g.setFont(self.font)
    g.setColor(pallete.statistic)
    g.setLineWidth(1)
    self.fontHeight = g.getFont():getHeight()
end

-- рисовать статистику после конца сета
function statisticRender:draw(noInfo)
    local w = g.getWidth()
    self:beforeDraw()
    local x = (w - w * self.width_k) / 2 
    local y = self.layout.middle.y + (self.layout.middle.h - self:getHitsRectHeight()) / 2
    self:drawHits(x, y)
    self:printInfo()
    --g.setColor{0.5, 0.5, 0.5, 1}
    --drawHierachy(self.layout)
    if self.buttons then
        gooi.draw()
    end
end

function statisticRender:printInfo()
    local y = self.info.y
    g.print(self.info.durationStr, self.info.durationX, y)
    y = y + g.getFont():getHeight()
    g.print(self.info.infoStr, self.info.infoX, y)
end

function statisticRender:buildLayout(border)
    border = border or self.border
    local screen = makeScreenTable()
    screen.top, screen.middle, screen.bottom = splith(screen, 0.2, 0.7, 0.1)
    screen.bottom.left, screen.bottom.right = splitv(screen.bottom, 0.5, 0.5)
    screen.mainMenuBtn = shrink(screen.bottom.right, border)
    self.layout = screen
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

function statisticRender:preparePrintInfo()
    self.info = {}
    self.info.durationStr = i18n("levelInfo2_part1", {count = self.level}) .. " " ..
        i18n("levelInfo2_part2", {count = self.pause_time}) 
    self.info.infoStr = i18n("levelInfo1_part1", {count = self.durationMin}) .. " " ..
        i18n("levelInfo1_part2", {count = tonumber( -- hacky hack, lol. for proper printing
        string.format("%d", math.floor(self.durationSec)))})

    local width1, width2 = g.getFont():getWidth(self.info.infoStr), g.getFont():getWidth(self.info.durationStr)
    local textHeight = g.getFont():getHeight() * 2
    self.info.infoX, self.info.durationX = (self.layout.top.w - width1) / 2, (self.layout.top.w - width2) / 2
    self.info.y = (self.layout.top.h - textHeight) / 2
end

function statisticRender.new(data)
    local self = setmetatable({
        signals = data.signals,
        pressed = data.pressed,
        level = data.level,
        pause_time = data.pause_time,
        font = data.font,
        x0 = data.x0,
        y0 = data.y0,
        durationMin = data.durationMin,
        durationSec = data.durationSec,
        buttons = data.buttons,
    }, statisticRender)
    -- должен быть минимальный размер, не слишком мелкий если не все 
    --квадраты умещаются в ширину экрана
    self.width_k = 3.9 / 4
    self.border = 2
    self.signals.eq = require "generator".makeEqArrays(self.signals, self.level)
    self.rect_size = math.floor(w * self.width_k / #self.signals.pos)
    self.percent = percentage(self.signals, self.pressed)
    self:buildLayout(data.border or nback.border)

    self:preparePrintInfo()

    --print("data.border", data.border)
    --print("data.buttons", data.buttons)
    if self.buttons then
        gooi.setStyle({ font = g.newFont("gfx/DejaVuSansMono.ttf", 13),
            showBorder = true,
            bgColor = {0.208, 0.220, 0.222},
        })

        self.mainMenuBtn = gooi.newButton({ 
            text = i18n("backToMainMenu"),
            x = self.layout.mainMenuBtn.x, y = self.layout.mainMenuBtn.y, 
            w = self.layout.mainMenuBtn.w, h = self.layout.mainMenuBtn.h
        }):onRelease(function()
            linesbuf:push(1, "return to main!")
            menu:goBack()
        end)
    end

    return self
end

return statisticRender
