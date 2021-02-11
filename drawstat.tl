require "love"
require "nbtypes"
require "layout"
require "cmn"
require "globals"

local gooi = require "gooi.gooi"
local pallete = require "pallete"
local i18n = require "i18n"
local g = love.graphics

local type LinkPoint = {number, string}

global type StatisticRenderData = record
    --signals: 
    level: number
    pause_time: number
    font: love.graphics.Font
    x0: number
    y0: number
    durationMin: number
    durationSec: number
end

global type StatisticRender = record

    record InitData
        signals: Signals
        pressed: {string:{boolean}}
        level: number
        font: love.graphics.Font
        pause_time: number
        x0: number
        y0: number
        durationMin: number
        durationSec: number
        buttons: boolean
        border: number
    end

    record Info
        durationStr: string
        infoStr: string
        y: number
        durationX: number
        infoX: number
    end

    rect_size: number
    signals: Signals
    width_k: number
    border: number
    level: number
    pressed: {string:{boolean}}
    percent: Percentage
    font: love.graphics.Font
    fontHeight: number
    layout: Layout
    info: Info
    pause_time: number
    durationMin: number
    durationSec: number
    buttons: boolean
    mainMenuBtn: gooi.Component
end

local StatisticRender_mt: metatable<StatisticRender> = {
    __index = StatisticRender
}

function StatisticRender:getHitQuadLineHeight(): number
    return self.rect_size + 12
end

-- drawLinks({ idx, "left" }, { idx, "right" })
-- drawLinks({ idx, "center" }, { idx, "right" })
function StatisticRender:drawLink(x: number, y: number, point1: LinkPoint, point2: LinkPoint)
    assert(type(point1) == "table")
    assert(type(point2) == "table")
    --assert(type(point1[1]) == "number" and type(point1[2]) == "string")
    --assert(type(point2[1]) == "number" and type(point2[2]) == "string")
    --assert(point1[2] == "right" or point1[2] == "left")
    --assert(point2[2] == "right" or point2[2] == "left")

    --[[ XXX сломано
    local rect_size = self.rect_size
    local eq_arr = self.signals.eq[type]

    local idx1, idx2 = point1[1], point2[1]
    local mode1, mode2 = point1[2], point1[2]

    local delta = 20
    local diff = 4

    local p1x, p1y = x + rect_size * (idx1 - 1) + rect_size / 2, y + rect_size / 2
    local p2x, p2y = x + rect_size * (idx2 - 1) + rect_size / 2, y + rect_size / 2

    if point1[2] == "left" then
        p1x = p1x - diff
    elseif point1[2] == "center" then
    elseif point1[2] == "right" then
        p1x = p1x + diff
    end

    if point2[2] == "left" then
        p2x = p2x - diff
    elseif point2[2] == "center" then
    elseif point2[2] == "right" then
        p2x = p2x + diff
    end

    g.setColor{0, 0, 1}
    g.line(p2x, p2y, p2x, p2y + delta)
    g.line(p1x, p1y, p1x, p1y + delta)
    g.line(p1x, p1y + delta, p2x, p2y + delta)
    --]]
end

function StatisticRender:drawLinks(x: number, y: number, type: Signals.EqKeys): number
    --local rect_size = self.rect_size
    local eq_arr = self.signals.eq[type]

    local maxLinks = 1
    -- рисую "скобки" под квадратиками, соединяющие точки сигналов и ответов
    local pressed = self.pressed[type]

    local points: {{{number, string}}} = {}
    for k, _ in ipairs(pressed) do
        points[k] = {}
    end

    for k, _ in ipairs(pressed) do
        if eq_arr[k] then -- индекс правильного нажатия
            if not points[k][1] then
                points[k] = { {}, {} }
            end
            points[k][1][1] = k - self.level
            points[k][2][1] = k

            local leftIndex = k - self.level
            if leftIndex >= 1 and eq_arr[leftIndex] then
                points[k][1][2] = "right"
            end

            local rightIndex = k + self.level
            if rightIndex <= #pressed and eq_arr[rightIndex] then
                points[k][2][2] = "left"
            end

            --self:drawLink(x, y, {k, "right"}, {})
            --self:drawLink(x, y, {k - self.level}, {k})
        end
    end

    --print("points", inspect(points))

    for _, v in ipairs(points) do
        if v[1] and v[2] then
            self:drawLink(x, y, v[1], v[2])
        end
    end

    return maxLinks
end

function StatisticRender:drawBox(x: number, y: number, k: number, border: number)
    local rect_size = self.rect_size
    g.setColor(pallete.field)
    g.rectangle("line", x + rect_size * (k - 1), y, rect_size, rect_size) 
    g.setColor(pallete.inactive)
    g.rectangle("fill", x + rect_size * (k - 1) + border, y + border, rect_size - border * 2, rect_size - border * 2)
end

function StatisticRender:drawHitBox(x: number, y: number, k: number, border: number)
    local rect_size = self.rect_size
    g.setColor(pallete.hit_color)
    g.rectangle("fill", x + rect_size * (k - 1) + border, y + border, rect_size - border * 2, rect_size - border * 2)
end

function StatisticRender:drawHitCirclesPair(x: number, y: number, k: number)
    local rect_size = self.rect_size
    local radius = 4
    g.setColor{0, 0, 0}
    g.circle("fill", x + rect_size * (k - 1) + rect_size / 2, y + rect_size / 2, radius)
    -- кружок на место предудущего сигнала
    g.setColor{1, 1, 1, 0.5}
    g.circle("line", x + rect_size * ((k - self.level) - 1) + rect_size / 2, y + rect_size / 2, radius)
end

-- x, y - координаты левого верхнего угла отрисовываемой картинки.
-- type - строка "pos", "sound", etc.
function StatisticRender:drawHitQuads(x: number, y: number, type: Signals.EqKeys, border: number): number
    local eq_arr = self.signals.eq[type]

    for k, v in ipairs(self.pressed[type]) do
        self:drawBox(x, y, k, border)

        -- отмеченная игроком позиция
        if v then
            self:drawHitBox(x, y, k, border)
        end

        -- правильная позиция нажатия
        if eq_arr[k] then
            self:drawHitCirclesPair(x, y, k)
        end
    end

    local maxLinks = self:drawLinks(x, y, type)
    return self:getHitQuadLineHeight() + maxLinks * 10
end

-- передвижение двумя пальцами
function processTouches()
    --local i = 0
    --local tbl = {}
    --for k, v in pairs(touches) do
        --if i < 2 then
            --table.insert(tbl, v)
            --i = i + 1
        --end
    --end
    --if #tbl == 2 then
        --cam:move(-tbl[1].dx, -tbl[1].dy)
    --end
end

function StatisticRender:update(dt: number)
    -- XXX disabled
    --processTouches()
    gooi.update(dt)
end

-- draw one big letter in left side of hit rects output
function StatisticRender:printSignalType(x: number, y: number, signalType: Signals.EqKeys)
    local loc = i18n(signalType) or ""
    local str =  loc .. "  " 
    local strWidth = g.getFont():getWidth(str)
    g.setColor(pallete.statisticSignalType)
    g.print(str, x, y)
    g.setColor(pallete.percentFont)
    g.print(string.format("%.3f", self.percent[signalType]), x + strWidth, y)
end

function StatisticRender:drawHits(x: number, y: number)
    local dy = 0
    g.setFont(self.font)
    self:printSignalType(x, y, "sound") 
    y = y + self.fontHeight
    dy = self:drawHitQuads(x, y, "sound", self.border)
    y = y + dy

    self:printSignalType(x, y, "color") 
    y = y + self.fontHeight
    dy = self:drawHitQuads(x, y, "color", self.border)
    y = y + dy

    self:printSignalType(x, y, "form") 
    y = y + self.fontHeight
    dy = self:drawHitQuads(x, y, "form", self.border)
    y = y + dy

    self:printSignalType(x, y, "pos") 
    y = y + self.fontHeight
    self:drawHitQuads(x, y, "pos", self.border)
end

function StatisticRender:getHitsRectHeight(): number
    return (self.fontHeight + self:getHitQuadLineHeight()) * 4
end

function StatisticRender:beforeDraw()
    g.setFont(self.font)
    g.setColor(pallete.statistic)
    g.setLineWidth(1)
    self.fontHeight = g.getFont():getHeight()
end

function StatisticRender:printInfo()
    local y = self.info.y
    g.print(self.info.durationStr, self.info.durationX, y)
    y = y + g.getFont():getHeight()
    g.print(self.info.infoStr, self.info.infoX, y)
end

-- рисовать статистику после конца сета
function StatisticRender:draw()
    local w = g.getWidth()
    self:beforeDraw()
    local x = (w - w * self.width_k) / 2 
    local y = self.layout.middle.y + (self.layout.middle.h - self:getHitsRectHeight()) / 2
    self:drawHits(x, y)
    self:printInfo()
    if self.buttons then
        gooi.draw()
    end
end

function StatisticRender:buildLayout(border: number)
    border = border or self.border
    local screen = makeScreenTable()
    screen.top, screen.middle, screen.bottom = splith(screen, 0.2, 0.7, 0.1)
    screen.bottom.left, screen.bottom.right = splitv(screen.bottom, 0.5, 0.5)

    local tmp: {any:any} = screen as {any:any}
    tmp.mainMenuBtn = shrink(screen.bottom.right, border)

    self.layout = screen
end

function StatisticRender:keypressed(key: string, isrepeat: boolean)
    gooi.keypressed(nil, key, isrepeat)
end

function StatisticRender:keyreleased(key: string)
    gooi.keyreleased(nil, key)
end

function StatisticRender:mousepressed(_: number, _: number, _: number)
    gooi.pressed()
end

function StatisticRender:mousereleased(_: number, _: number, _utton: number)
    gooi.released()
end

function StatisticRender:preparePrintInfo()
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

function StatisticRender.new(data: StatisticRender.InitData): StatisticRender
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
    } as StatisticRender, StatisticRender_mt)
    -- должен быть минимальный размер, не слишком мелкий если не все 
    --квадраты умещаются в ширину экрана
    self.width_k = 3.9 / 4
    self.border = 2
    self.signals.eq = require "generator".makeEqArrays(self.signals, self.level)
    local w, _ = love.graphics.getDimensions()
    self.rect_size = math.floor(w * self.width_k / #self.signals.pos)
    self.percent = percentage(self.signals, self.pressed as Signals.Eq)
    --self:buildLayout(data.border or nback.border)
    self:buildLayout(data.border)

    self:preparePrintInfo()

    --print("data.border", data.border)
    --print("data.buttons", data.buttons)
    if self.buttons then
        gooi.setStyle({ font = require "fonts".drawstat.gooi,
            showBorder = true,
            bgColor = {0.208, 0.220, 0.222},
        })

        local mainMenuBtnLayout: Layout = (self.layout as {any:any}).mainMenuBtn as Layout
        self.mainMenuBtn = gooi.newButton({ 
            text = i18n("backToMainMenu"),
            x = mainMenuBtnLayout.x, y = mainMenuBtnLayout.y, 
            w = mainMenuBtnLayout.w, h = mainMenuBtnLayout.h
        }):onRelease(function()
            --linesbuf:push(1, "return to main!")
            menu:goBack()
        end)
    end

    return self
end

return StatisticRender
