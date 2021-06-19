-- vim: set foldmethod=indent
print('hello from begin of nback module')

require "Timer"
require "button"
require "common"
require "coroprocessor"
require "cmn"
require "drawstat"
require "layout"
require "menu-main"
require "nbtypes"
require "signal_quad_field"
require "snippets"
require "tiledbackground"

--local hex = require "hex"
local inspect = require "inspect"
local colorConstants = require "colorconstants"
local g = love.graphics
local generator = require "generator"
local getTime = love.timer.getTime
local gr = love.graphics
local i18n = require "i18n"
local pallete = require "pallete"
local serpent = require "serpent"
local setupmenu = require "setupmenu"
local w, h = g.getDimensions()
local yield = coroutine.yield

global type Nback = record

    enum Mode
        "quad"
        "hex"
    end

    record Button
        x: number
        y: number
        w: number
        h: number
        title: string
        coroName: string
        ontouch: function
        textx: number
        texty: number
    end

    mode: Mode

    -- количество ячеек поля
    dim: integer

    -- ширина игрового поля в пикселях
    cellWidth: integer

     -- номер текущего сигнала, при начале партии равен 1
    currentSig: integer

    -- количество сигналов
    sigCount: integer

    -- уровень, на сколько позиций назад нужно нажимать клавишу сигнала
    level: integer

    -- индикатор запуска рабочего цикла
    isRun: boolean

    -- задержка между сигналами, в секундах
    pauseTime: number

    -- XXX FIXME зачем нужна эта переменная?
    canPress: boolean

    -- индикатор показа статистики в конце сета
    showStatistic: boolean

    fieldColor: {number}
    font: love.graphics.Font
    buttonsFont: love.graphics.Font
    centralFont: love.graphics.Font

    -- какое-то значение в пикселях
    border: number

    layout: Layout
    timer: Timer

    -- история была записана в файл?
    written: boolean

    pause: boolean
    signals: Signals
    timestamp: number
    pressed: Signals.Eq
    signalView: SignalView
    stopppedSignal: number

    -- время в секундах от нажатия "старт" до первого сигнала
    start_pause_rest: number

    -- что за переменная?
    start_pause: boolean

    startTime: number
    shader: love.graphics.Shader
    setupmenu: SetupMenu

    uiState: any

    shaderTimer: number
    shaderTimeEnabled: boolean
    figureAlpha: number
    bhupur_h: number
    x0: number
    y0: number
    processor: CoroProcessor
    statisticRender: StatisticRender
    volume: number
    saveName: string
    buttons: {Button}
    durationMin: number
    durationSec: number
    signalsInspected: boolean

    -- вроде не используется
    map: {{number}}

    new:                            function():Nback

    buildLayout:                    function(Nback)
    check:                          function(Nback, signalType: Signals.EqKeys)
    checkTouchButtons:              function(Nback, x: number, y: number)
    createSetupMenu:                function(Nback)
    draw:                           function(Nback)
    drawActiveSignal:               function(Nback)
    drawButtons:                    function(Nback)
    drawField:                      function(Nback)
    drawMapIndices:                 function(Nback)
    enter:                          function(Nback)
    fillLinesbuf:                   function(Nback)
    init:                           function(Nback, string)
    initButtons:                    function(Nback)
    initShaders:                    function(Nback)
    initShadersTimer:               function(Nback)
    inspectSignals:                 function(Nback)
    isRoundFinished:                function(Nback):boolean
    keypressed:                     function(Nback, scancode: string)
    keyreleased:                    function(Nback, scancode: string)
    leave:                          function(Nback)
    loverVolume:                    function(Nback)
    mousemoved:                     function(Nback, x: number, y: number, dx: number, dy: number, istouch: boolean)
    mousepressed:                   function(Nback, x: number, y: number, btn: number, istouch: boolean)
    mousereleased:                  function(Nback, x: number, y: number, btn: number)
    printStartPause:                function(Nback)
    processSignal:                  function(Nback)
    processSignal:                  function(Nback)
    processTouches:                 function(Nback)
    quit:                           function(Nback, byescape: boolean)
    raiseVolume:                    function(Nback)
    resize:                         function(Nback, number, number)
    save_to_history:                function(Nback)
    setupButtonsTextPosition:       function(Nback)
    start:                          function(Nback)
    stop:                           function(Nback, boolean)
    update:                         function(Nback, dt: number)
end

local Nback_mt: metatable<Nback> = {
    __index = Nback
}

local fonts = require "fonts"

local nbackSelf: Nback = {
    dim = 8,    
    cellWidth = 100, 
    currentSig = 1,
    sigCount = 8, 
    level = 1, 
    isRun = false, 
    pauseTime = 2.0, 
    canPress = false, 
    showStatistic = false, 
    fieldColor = shallowCopy(pallete.field), 
    font = fonts.nback.font,
    buttonsFont = fonts.nback.buttons,
    centralFont = fonts.nback.central,
    border = 3,
    mode = "quad",
}

function Nback.new(): Nback
    local self = deepcopy(nbackSelf)
    --print("self.statisticRender", inspect(self.statisticRender))
    return setmetatable(self, Nback_mt)
end

local function makeFalseArray(len: number): {boolean}
    local ret = {}
    for _ = 1, len do
        ret[#ret + 1] = false
    end
    return ret
end

function Nback:buildLayout()
    local screen = makeScreenTable()
    screen.left, screen.center, screen.right = 
        splitv(screen, 0.2, 0.6, 0.2)
    screen.leftTop, screen.leftMiddle, screen.leftBottom = 
        splith(screen.left, 0.2, 0.4, 0.4)
    screen.rightTop, screen.rightMiddle, screen.rightBottom = 
        splith(screen.right, 0.2, 0.4, 0.4)
    screen.leftTop, screen.leftMiddle, screen.leftBottom = 
        shrink(screen.leftTop, self.border), 
        shrink(screen.leftMiddle, self.border), 
        shrink(screen.leftBottom, self.border)
    screen.rightTop, screen.rightMiddle, screen.rightBottom = 
        shrink(screen.rightTop, self.border), 
        shrink(screen.rightMiddle, self.border), 
        shrink(screen.rightBottom, self.border)
    screen.center = shrink(screen.center, self.border)

    self.layout = screen
    --print("self.layout", inspect(self.layout))
end

local function genMapByDim(d: number): {{number}}
    local t: {{number}} = {}
    for _ = 1, d do
        table.insert(t, {})
        local p = t[#t]
        for _ = 1, d do
            table.insert(p, 0)
        end
    end
    return t
end

function Nback:start()
    print("nback:start()")
    local q = pallete.field
    -- запуск анимации цвета игрового поля
    --self.timer:tween(3, self, { field_color = {q[1], q[2], q[3], 1}}, "linear")
    self.timer:tween(3, self, { fieldColor = {q[1], q[2], q[3], 1}}, "linear")
    self.written = false
    self.pause = false
    self.map = genMapByDim(self.dim)

    self.signals = generator.generateAll(
        self.sigCount, 
        self.level, 
        self.dim, 
        #self.signalView.sounds, 
        self.map
    )

    --print("self.signals", inspect(self.signals))
    self.currentSig = 1
    self.timestamp = love.timer.getTime() - self.pauseTime
    self.showStatistic = false

    -- массивы хранящие булевские значения - нажат сигнал вот время обработки или нет?
    local signalsCount = #self.signals.pos
    self.pressed = {
        pos = makeFalseArray(signalsCount),
        color = makeFalseArray(signalsCount),
        form = makeFalseArray(signalsCount),
        sound = makeFalseArray(signalsCount),
    }
    --print("self.pressed", inspect(self.pressed))

    -- сигнал, на котором остановилась партия. Используется для рисовки
    -- вертикальной временной черты на графике нажатий
    self.stopppedSignal = 0 
    self.start_pause_rest = 3 -- время паузы перед раундом
    self.start_pause = true

    -- задержка измеряется в секундах?
    local delay = 1
    self.timer:every(delay, 
        function() 
            self.start_pause_rest = self.start_pause_rest - 1 
        end, 
        self.start_pause_rest, function()
            self.start_pause = false
            self.isRun = true
            -- фиксирую время начала игры
            self.startTime = love.timer.getTime()
        end, 
        "notag"
    )

    if ON_ANDROID or not USE_KEYBOARD then
        self:initButtons()
    end
end

function Nback:enter()
    -- установка альфа канала цвета сетки игрового поля
    self.fieldColor[4] = 0.2

    print("nback:enter()")
    -- setup Gooi
    restoreUI(self.uiState)
end

function Nback:leave()
    print("nback:leave()")
    self.showStatistic = false
    self.uiState = storeUI()
end

-- time изменяется в пределах 0..1
local fragmentCode = [[
extern float time;
vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
    vec4 pixel = Texel(image, uvs);
    //float av = (pixel.r + pixel.g + pixel.b) / time;
    color.a = time;
    //return pixel * color;
    return pixel * color;
}
]]

function Nback:initShaders()
    self.shader = g.newShader(fragmentCode)
end

-- фигачу кастомную менюшку на лету
function Nback:createSetupMenu()
    -- начальное значение. Можно менять исходя из
    -- предыдущих игр, брать из файла настроек и т.д.
    local nbackLevel = self.level 
    -- значение должно поддерживаться генератором, 
    -- больше значение - длиннее последовательность и(или)
    -- меньше целевых сигналов в итоге.
    local maxLevel = 5   
    
    local dim = 5
    --local minDim, maxDim = 4, 10
        
    local expositionList = { "1", "2", "3", "4", "5", "6", }
    local activeExpositionItem = 2

    local parameterColor = {0, 0.9, 0}

    self.setupmenu = setupmenu.new(fonts.nback.setupmenu, pallete.signal)

    -- пункт меню - поехали!
    self.setupmenu:addItem({
        oninit = function(): {string}, boolean, boolean
            return {i18n("setupMenu.start")} 
        end,
        onselect = function() --  точка входа в игру
            self.level = nbackLevel
            self.dim = dim
            --self:resize(g.getDimensions())
            self:resize(w, h)
            self.pauseTime = tonumber(expositionList[activeExpositionItem])
            self.setupmenu.freeze = true
            self:start()
            self.setupmenu.freeze = false
        end})

    -- выбор продолжительности экспозиции
    self.setupmenu:addItem({
        oninit = function(): {string}, boolean, boolean
            --debug.debug()
            print('count', tonumber(expositionList[activeExpositionItem]))
            local fullStr = i18n("setupMenu.expTime_plural", {
                count = tonumber(expositionList[activeExpositionItem])
            })

            --XXX костыль
            --if not fullStr then
                --print('fullStr', fullStr)
                --os.exit()
            --end
            --fullStr = 'fullStr'

            --print("------", tonumber(expositionList[activeExpositionItem]))
            --print("------", i18n("setupMenu.expTime_plural_stub", {
                --count = tonumber(expositionList[activeExpositionItem])
            --}))

            --print("------", i18n("setupMenu.expTime_plural", {
                --count = tonumber(expositionList[activeExpositionItem])
            --}))

            --[[
  local colors = require 'ansicolors'
  print(colors('%{red}hello'))
  print(colors('%{redbg}hello%{reset}'))
  print(colors('%{bright red underline}hello'))
  --]]

            --local ansicolors = require 'ansicolors'
            --print(ansicolors(string.format("%{red}fullStr = %s", fullStr)))

            --print(string.format("\%{red}fullStr = %s", fullStr))
            print("fullStr = ", fullStr)

            local part1, _, part2 = string.match(fullStr, "(.+)(%d)(.+)")
            -- XXX may be harmful type conversion
            return {pallete.signal, part1, parameterColor, 
                expositionList[activeExpositionItem], pallete.signal, part2} as {string},
                activeExpositionItem == 1,
                activeExpositionItem == #expositionList
        end,

        onleft = function(): {string}, boolean, boolean
            if activeExpositionItem - 1 >= 1 then
                activeExpositionItem = activeExpositionItem - 1
            end
            local fullStr = i18n("setupMenu.expTime_plural", {count = tonumber(expositionList[activeExpositionItem])})
            local part1, _, part2 = string.match(fullStr, "(.+)(%d)(.+)")
            return {pallete.signal, part1, parameterColor,
                expositionList[activeExpositionItem], pallete.signal, part2} as {string}, 
                activeExpositionItem == 1,
                activeExpositionItem == #expositionList
        end,

        onright = function(): {string}, boolean, boolean
            if activeExpositionItem + 1 <= #expositionList then
                activeExpositionItem = activeExpositionItem + 1
            end
            local fullStr = i18n("setupMenu.expTime_plural", {count = tonumber(expositionList[activeExpositionItem])})
            local part1, _, part2 = string.match(fullStr, "(.+)(%d)(.+)")
            -- XXX может не работать из-за различий в типах
            return {pallete.signal, part1, parameterColor,
                expositionList[activeExpositionItem], pallete.signal, part2} as {string},
                activeExpositionItem == 1,
                activeExpositionItem == #expositionList
        end})

    -- выбор уровня эн-назад
    self.setupmenu:addItem({
        oninit = function(): {string}, boolean, boolean 
            return {pallete.signal, i18n("setupMenu.diffLevel"),
                parameterColor, tostring(nbackLevel)} as {string}, 
                nbackLevel == 1,
                nbackLevel == maxLevel
        end,

        onleft = function(): {string}, boolean, boolean
            if nbackLevel - 1 >= 1 then nbackLevel = nbackLevel - 1 end
            return {pallete.signal, i18n("setupMenu.diffLevel"), parameterColor,
                tostring(nbackLevel)} as {string},
                nbackLevel == 1,
                nbackLevel == maxLevel
        end,

        onright = function(): {string}, boolean, boolean
            if nbackLevel + 1 <= maxLevel then nbackLevel = nbackLevel + 1 end
            return {pallete.signal, i18n("setupMenu.diffLevel"), parameterColor,
                tostring(nbackLevel)} as {string},
                nbackLevel == 1,
                nbackLevel == maxLevel
        end})
    
--[[
   [    --  выбор разрешения поля клеток для сигнала "позиция". 
   [    --  Рабочее значение : от 4 до 8-10-20?
   [    self.setupmenu:addItem({
   [        oninit = function() return {pallete.signal, i18n("setupMenu.dimLevel"),
   [            parameterColor, tostring(dim)}, 
   [            dim == 1,
   [            dim == maxDim
   [        end,
   [
   [        onleft = function()
   [            if dim - 1 >= minDim then dim = dim - 1 end
   [            return {pallete.signal, i18n("setupMenu.dimLevel"), parameterColor,
   [                tostring(dim)},
   [                dim == 1,
   [                dim == maxLevel
   [        end,
   [
   [        onright = function()
   [            if dim + 1 <= maxDim then dim = dim + 1 end
   [            return {signal.color, i18n("setupMenu.dimLevel"), parameterColor,
   [                tostring(dim)},
   [                dim == 1,
   [                dim == maxLevel
   [        end})
   ]]

end

--[[
function Nback:drawMapIndices()
    local currentHex = self.hexField:get(1, 1)
    local currentHex = self.hexField:get(2, 1)

    g.setColor{1, 0, 0}
    for k, v in pairs(self.hexField) do
        local baseIndex = 9
        local x, y = v[baseIndex], v[baseIndex + 1]
        local mapx, mapy = unpack(v.mapIndex)
        local delta = 20
        g.print(string.format("%dx%d", mapx, mapy), x + 20, y)
    end
end
--]]

function Nback:init(saveName: string)
    readSettings()
    self.volume = SETTINGS.volume
    love.audio.setVolume(SETTINGS.volume)
    self.saveName = saveName
    self.timer = require "Timer".new()

    if self.mode == "quad" then
        self.signalView = require "signal_quad_field".new(self.cellWidth, "alphabet")
    elseif self.mode == "hex" then
        error("not implemented")
        w, h = gr.getDimensions()
        self.map = {
            {1, 1, 1},
            {1, 1, 0},
            {1, 1, 1},
        }
        --local fieldSize = #self.map
        --local rad = math.floor((math.min(w, h) / fieldSize) / 2)
        --local testHex = hex.newHexPolygon(0, 0, rad)
        --self.startcx = (w - (getHexPolygonWidth(testHex) * fieldSize - rad * 2)) / 2
        --self.startcy = (h - (getHexPolygonHeight(testHex) * fieldSize - rad * 3)) / 2
        --print("self.startcx, self.startcy", self.startcx, self.startcy)
    end

    self:createSetupMenu()
    self:resize(w, h)
    self:initShaders()
    --self:initShadersTimer()
    self.uiState = storeUI()
end

function Nback:initShadersTimer()
    self.shaderTimer = 0
    self.shaderTimeEnabled = true -- непутевое название переменной
    self.timer:during(2, function(dt: number, _: number, _: number) 
        --print("time, delay, shaderTimer", time, delay, self.shaderTimer)
        local delta = 0.4 * dt
        if self.shaderTimer + delta <= 1 then
            self.shaderTimer = self.shaderTimer + delta
        end
    end, 
    function() 
        self.shaderTimeEnabled = false
    end)
end

function Nback:processSignal()
    local time = love.timer.getTime()
    if (time - self.timestamp >= self.pauseTime) then
        self.timestamp = time

        self.currentSig = self.currentSig + 1
        self.canPress = true

        -- setup timer for figure alpha channel animation
        --self.figure_alpha = 1
        self.figureAlpha = 0.1

        local tween_time = self.pauseTime / 2
        print("tween_time", tween_time)
        print("time delta = " .. self.pauseTime - tween_time)
        local after = self.pauseTime - tween_time - 0.1
        --local after = 0.1
        print("after", after)

        --self.timer:tween(tween_time, self, {figure_alpha = 0}, "out-linear")
        self.timer:tween(self.pauseTime / 3, self, {figure_alpha = 1}, "out-linear")

        self.timer:after(after, function()
            print("figureAlpha before", self.figureAlpha)
            print("tween_time", tween_time)
            self.timer:tween(tween_time, self, {figure_alpha = 0}, "out-linear")
            print("figure_alpha after", self.figureAlpha)
        end)

        colprint(inspect(self.signals.sound[self.currentSig]))
        self.signalView:play(self.signals.sound[self.currentSig])
    end
end

local function drawButtonCapture(button: Nback.Button, nback: Nback)
    g.setColor{0, 0, 0}
    g.setFont(nback.buttonsFont)
    g.printf(button.title, button.textx, button.texty, button.w, "center")
end

local drawButton = function(button: Nback.Button, nback: Nback)
    --yield()

    local ok, errmsg: boolean, string = pcall(function()

    local ret: string
    repeat
        local oldwidth = g.getLineWidth()
        g.setColor(pallete.buttonColor)
        g.rectangle("fill", button.x, button.y, button.w, button.h, 6, 6)
        g.setColor{0, 0, 0}
        g.setLineWidth(2)
        g.rectangle("line", button.x, button.y, button.w, button.h, 6, 6)

        drawButtonCapture(button, nback)
        g.setLineWidth(oldwidth)
        ret = yield() as string
    until ret == "exit"

    end)

    if not ok then
        error(errmsg)
    end
end

local drawButtonClicked = function(button: Nback.Button, nback: Nback)
    --yield()

    local ok, errmsg: boolean, string = pcall(function()

    local btnColor = shallowCopy(pallete.buttonColor)
    --btnColor[4] = 1
    local ret: string
    local time = getTime()
    local alphaDelta = 0.05

    repeat
        local now = getTime()
        local diff = now - time
        if diff > 0.04 then
            if btnColor[4] > 0.1 then
                btnColor[4] = btnColor[4] - alphaDelta
            else
                break
            end
        end

        local oldwidth = g.getLineWidth()
        g.setColor(btnColor)
        g.rectangle("fill", button.x, button.y, button.w, button.h, 6, 6)
        g.setColor{0, 0, 0}
        g.setLineWidth(2)
        g.rectangle("line", button.x, button.y, button.w, button.h, 6, 6)

        drawButtonCapture(button, nback)
        g.setLineWidth(oldwidth)

        ret = yield() as string
    until ret == "exit"

    if ret == "exit" then
        return
    end

    repeat
        local now = getTime()
        local diff = now - time
        if diff > 0.04 then
            if btnColor[4] < pallete.buttonColor[4] then
            --if btnColor[4] < 1 then
                btnColor[4] = btnColor[4] + alphaDelta
            else
                nback.processor:push(button.coroName, drawButton, button, nback)
                break
            end
        end

        local oldwidth = g.getLineWidth()
        g.setColor(btnColor)
        g.rectangle("fill", button.x, button.y, button.w, button.h, 6, 6)
        g.setColor{0, 0, 0}
        g.setLineWidth(2)
        g.rectangle("line", button.x, button.y, button.w, button.h, 6, 6)

        drawButtonCapture(button, nback)
        g.setLineWidth(oldwidth)

        ret = yield() as string
    until ret == "exit"

    end)

    if not ok then
        error(errmsg)
    end
end

function Nback:initButtons()
    self.buttons = {}

    -- клавиша выхода слева
    table.insert(self.buttons, { 
        x = self.layout.leftTop.x, 
        y = self.layout.leftTop.y, 
        w = self.layout.leftTop.w,
        h = self.layout.leftTop.h,
        title = i18n("quitBtn"),
        coroName = "quitBtn",
        ontouch = function() 
            mainMenu:goBack()
        end})

    -- клавиша дополнительных настроек справа
    table.insert(self.buttons, { 
        x = self.layout.rightTop.x, 
        y = self.layout.rightTop.y, 
        w = self.layout.rightTop.w, 
        h = self.layout.rightTop.h,
        title = i18n("settingsBtn"),
        coroName = "settingsBtn",
        ontouch = function() 
            -- какие тут могут быть настройки?
            writeSettings()
            love.event.quit() 
        end})

    -- левая верхняя клавиша управления
    table.insert(self.buttons, { 
        x = self.layout.leftMiddle.x, 
        y = self.layout.leftMiddle.y, 
        w = self.layout.leftMiddle.w, 
        h = self.layout.leftMiddle.h, 
        title = i18n("sound"),
        coroName = "soundBtn",
        ontouch = function() 
            if self.isRun then
                self:check("sound") 
            end
        end})

    -- правая верхняя клавиша управления
    table.insert(self.buttons, { 
        x = self.layout.rightMiddle.x, 
        y = self.layout.rightMiddle.y, 
        w = self.layout.rightMiddle.w, 
        h = self.layout.rightMiddle.h,
        title = i18n("pos"),
        coroName = "posBtn",
        ontouch = function() 
            if self.isRun then
                self:check("pos") 
            end
        end})

    -- левая нижняя клавиша управления
    table.insert(self.buttons, { 
        x = self.layout.leftBottom.x, 
        y = self.layout.leftBottom.y, 
        w = self.layout.leftBottom.w, 
        h = self.layout.leftBottom.h, 
        title = i18n("form"),
        coroName = "formBtn",
        ontouch = function() 
            if self.isRun then
                self:check("form") 
            end
        end})

    -- правая нижняя клавиша управления
    table.insert(self.buttons, { 
        x = self.layout.rightBottom.x, 
        y = self.layout.rightBottom.y, 
        w = self.layout.rightBottom.w, 
        h = self.layout.rightBottom.h, 
        title = i18n("color"),
        coroName = "colorBtn",
        ontouch = function() 
            if self.isRun then
                self:check("color") 
            end
        end})

    self:setupButtonsTextPosition()

    for _, v in ipairs(self.buttons) do
        self.processor:push(v.coroName, drawButton, v, self)
        --self.processor:push(v.coroName, drawButtonClicked, v, self)
    end

    -- кнопки с подписями
    --self.namedButtons = {}
    --for k, v in pairs(self.buttons) do
        --self.namedButtons[v.coroName] = v
    --end
end

function Nback:setupButtonsTextPosition()
    for _, v in ipairs(self.buttons) do
        v.textx = v.x
        v.texty = v.y + (v.h / 2 - self.font:getHeight() / 2)
    end
end

function Nback:drawButtons()
    -- эта строчка необходима так как initButtons() вызывается не в саммом
    -- подходящем месте. Найдешь место лучше, эта строчка не будет нужна.
    if not self.buttons then return end

    local oldwidth = g.getLineWidth()
    for _, v in ipairs(self.buttons) do
        g.setColor(pallete.buttonColor)
        g.rectangle("fill", v.x, v.y, v.w, v.h, 6, 6)
        g.setColor{0, 0, 0}
        g.setLineWidth(2)
        g.rectangle("line", v.x, v.y, v.w, v.h, 6, 6)

        g.setColor{0, 0, 0}
        g.setFont(self.font)
        g.printf(v.title, v.textx, v.texty, v.w, "center")
    end
    g.setLineWidth(oldwidth)
end

local function drawTouches()
    local touches = love.touch.getTouches()
    for _, id in ipairs(touches) do
        local x, y = love.touch.getPosition(id)
        g.setColor{0, 0, 0}
        g.circle("fill", x, y, 20)
    end
end

function Nback:draw()
    love.graphics.clear(pallete.background)

    --g.push("all")

    --[[
       [g.setShader(self.shader)
       [if self.shaderTimeEnabled then
       [    self.shader:send("time", self.shaderTimer)
       [end
       ]]

    if self.isRun then
        if self.start_pause then
            tiledback:draw(0.3)
            self:drawField()
            self:printStartPause()
        else
            tiledback:draw(0.3)

            if self.mode == "quad" then
                self:drawField()
            elseif self.mode == "hex" then
                error("not implemented")
                --gr.draw(self.hexMesh)
            end

            if __DEBUG__ then
                --self:drawMapIndices()
            end

            self:drawActiveSignal()
            --self.processor:update()
            --self:drawButtons()
        end
    else
        if self.showStatistic then 
            tiledback:draw(0.3)
            self.statisticRender:draw()
        else
            tiledback:draw(0.3)
            self.setupmenu:draw()
        end
    end

    drawTouches()

    if USE_KEYBOARD then
        --linesbuf:pushi("[a] - sound [f] - color [j] - form [;] - position")
    end

    --g.setShader()
    --g.pop()

    --g.setColor{0, 0, 0}
    --[[drawHierachy(self.layout)]]
end

function Nback:checkTouchButtons(x: number, y: number)
    if self.buttons then
        for _, v in ipairs(self.buttons) do
            if pointInRect(x, y, v.x, v.y, v.w, v.h) then
                v.ontouch()
                self.processor:sendMessage(v.coroName, "exit")
                self.processor:push(v.coroName, drawButtonClicked, v, self)
            end
        end
    end
end

function Nback:processTouches()
    local touches: {any} = love.touch.getTouches()
    for _, id in ipairs(touches) do
        local x, y = love.touch.getPosition(id)
        self:checkTouchButtons(x, y)
    end
end

function Nback:isRoundFinished(): boolean
    return self.currentSig < #self.signals.pos
end

function Nback:update(dt: number)
    --self:fillLinesbuf()
    self.timer:update(dt)
    self.processor:update()

    if self.pause or self.start_pause then 
        self.timestamp = love.timer.getTime() - self.pauseTime
        -- подумай, нужен ли здесь код строчкой выше. 
        -- Могут ли возникнуть проблемы с таймером отсчета если 
        -- продолжительноть паузы больше self.pause_time?
        return 
    end

    if ON_ANDROID then
        self:processTouches()
    end

    if self.isRun then
        if not self:isRoundFinished() then
            self:processSignal()
        else
            self:stop()
        end
    else
        if not self.showStatistic then
            self.setupmenu:update(dt)
        end
    end
end

function Nback:save_to_history()
    if self.written then
        return
    else
        self.written = true
    end

    local history: {History} = {}
    local ok: boolean
    local data, _ = love.filesystem.read(self.saveName)
    if data ~= nil then
        ok, history = serpent.load(data) as boolean, {History}
        -- нужно выходить?
        if not ok then
            return
        end
    end
    print("nback:save_to_history()")
    
    os.setlocale("C")
    table.insert(history, { date = os.date("*t"), 
                            signals = self.signals,
                            pressed = self.pressed,
                            level = self.level,
                            pause_time = self.pauseTime,
                            -- XXX неизвестные значения
                            --percent = self.percent
                        })
    love.filesystem.write(self.saveName, serpent.dump(history))
    collectgarbage()
end

function Nback:stop(byescape: boolean)
    print("stop")
    local q = pallete.field
    -- амимация альфа-канала игрового поля
    self.timer:tween(2, self.fieldColor, { q[1], q[2], q[3], 0.1 }, "linear")

    self.isRun = false
    self.showStatistic = true

    -- зачем нужна эта проверка? Расчет на то, что раунд был начат?
    if self.signals and self.signals.pos then
        self.stopppedSignal = self.currentSig 
    end

    print("byescape", byescape)
    if not byescape then
        local duration = love.timer.getTime() - self.startTime
        self.durationMin = math.floor(duration / 60)
        self.durationSec = duration - self.durationMin * 60
        print(string.format("durationMin %f, durationSec %f", self.durationMin, self.durationSec))

        -- Раунд полностью закончен? - записываю историю
        if self.signals and self.currentSig == #self.signals.pos then 
            self:save_to_history() 
        end

        self.statisticRender = require "drawstat".new({
            signals = self.signals,
            pressed = self.pressed,
            level = self.level,
            pause_time = self.pauseTime,

            x0 = self.x0,
            y0 = self.y0,
            font = self.font,
            durationMin = self.durationMin,
            durationSec = self.durationSec,
            buttons = true, -- флажок - показывать ли кнопку "вернуться"
        })
    end
end

function Nback:quit(byescape: boolean)
    self.timer:destroy()
    self:stop(byescape)
    SETTINGS.volume = self.volume
    SETTINGS.level = self.level
    SETTINGS.pause_time = self.pauseTime
    SETTINGS.dim = self.dim
    writeSettings()
    mainMenu:goBack()
end

function Nback:keyreleased(scancode: string)
    --print(string.format("nback:keyreleased(%s)", scancode))
    if not self.isRun and not self.showStatistic then
        if scancode == "left" or scancode == "h" then
            self.setupmenu:leftReleased()
        elseif scancode == "right" or scancode == "l" then
            self.setupmenu:rightReleased()
        end
    end
end

function Nback:keypressed(scancode: string)

    if not USE_KEYBOARD then 
        return
    end

    if self.isRun then
        if scancode == "a" then
            self:check("sound")
            --self.p3ocessor:push("soundBtn", drawButtonClicked, self.namedButtons["soundBtn"], self)
            --self.processor:sendMessage("soundBtn", "exit")
        elseif scancode == "f" then
            self:check("color")
            --self.processor:push("colorBtn", drawButtonClicked, self.namedButtons["colorBtn"], self)
            --self.processor:sendMessage("colorBtn", "exit")
        elseif scancode == "j" then
            self:check("form")
            --self.processor:push("formBtn", drawButtonClicked, self.namedButtons["formBtn"], self)
            --self.processor:sendMessage("formBtn", "exit")
        elseif scancode == ";" then
            self:check("pos")
            --self.processor:push("posBtn", drawButtonClicked, self.namedButtons["posBtn"], self)
            --self.processor:sendMessage("posBtn", "exit")
        end
    else
        if not self.showStatistic then
            if scancode == "space" or scancode == "return" then
                print("select")
                self.setupmenu:select()
            elseif scancode == "up" or scancode == "k" then
                self.setupmenu:scrollUp()
            elseif scancode == "down" or scancode == "j" then 
                self.setupmenu:scrollDown()
            elseif scancode == "left" or scancode == "h" then
                self.setupmenu:leftPressed()
            elseif scancode == "right" or scancode == "l" then
                self.setupmenu:rightPressed()
            end
        end
    end
    if scancode == "-" then 
        self:loverVolume()
    elseif scancode == "=" then
        self:raiseVolume()
    end
    if scancode == "escape" or scancode == "achome" then
        if self.isRun then
            print("stop by escape")
            self:stop()
        else
            self:quit(true)
        end
    end
end

local soundVolumeStep = 0.05

function Nback:loverVolume()
    if self.volume - soundVolumeStep >= 0 then
        self.volume = self.volume - soundVolumeStep
        love.audio.setVolume(self.volume)
    end
end

function Nback:raiseVolume()
    if self.volume + soundVolumeStep <= 1 then
        self.volume = self.volume + soundVolumeStep
        love.audio.setVolume(self.volume)
    end
end

-- signal type may be "pos", "sound", "color", "form"
function Nback:check(signalType: Signals.EqKeys)
    -- эта проверка должна выполняться в другом месте, снаружи данной функции.
    if not self.isRun then
        return
    end

    local signals: {any} = (self.signals as {any:{any}})[signalType]
    local cmp = function(a: any, b: any): boolean
        return a == b 
    end
    if signalType == "pos" then
        cmp = isPositionEqual
    end

    self.pressed[signalType][self.currentSig] = true
    if self.currentSig - self.level > 1 then
        if cmp(signals[self.currentSig], signals[self.currentSig - self.level]) then
            --print(inspect(nback))
            if self.canPress then
                print(signalType .. " hit!")
                self.canPress = false
            end
        end
    end
end

function Nback:resize(neww: integer, newh: integer)
    print(string.format("resized to %d * %d", neww, newh))
    self:buildLayout()

    w, h = neww, newh

    --self.cellWidth = self.layout.center.h / self.dim
    self.cellWidth = math.ceil(self.layout.center.h / self.dim)

    self.bhupur_h = self.cellWidth * self.dim 
    self.x0, self.y0 = self.layout.center.x + (self.layout.center.w - self.layout.center.h) / 2, self.layout.center.y
    self.processor = require "coroprocessor".new()

    if self.signalView then
        self.signalView:setCorner(self.x0, self.y0)
        self.signalView:resize(self.cellWidth)
    end

    if self.statisticRender then
        self.statisticRender:buildLayout(self.border)
    end
end

function Nback:inspectSignals()
    --[[
    if self.signals then
        self.signalsInspected = {}
        self.signalsInspected.pos = inspect(self.signals.pos)
        self.signalsInspected.form = inspect(self.signals.pos)
        self.signalsInspected.sound = inspect(self.signals.sound)
        self.signalsInspected.color = inspect(self.signals.color)
        local strings = {}
        table.insert(strings, "pos " .. self.signalsInspected.pos)
        table.insert(strings, "sound " .. self.signalsInspected.sound)
        table.insert(strings, "form " .. self.signalsInspected.form)
        table.insert(strings, "color " .. self.signalsInspected.color)
        self.signalsInspected.strings = strings
    end
    --]]
end

function Nback:fillLinesbuf()
    if not self.signalsInspected then
        --self:inspectSignals()
    end
    if self.signals then
        --[[
           [local strings = self.signalsInspected.strings
           [for i = 1, 4 do
           [    linesbuf:pushi(strings[i])
           [end
           ]]
    end

    -- TODO подключить вывод информации
    --linesbuf:pushi("current_sig = " .. self.current_sig)
    --linesbuf:pushi("nback.can_press = " .. tostring(self.can_press))
    --linesbuf:pushi("volume %.3f", self.volume)
    --linesbuf:pushi("Mem: %.3f MB", collectgarbage("count") / 1024)
    --linesbuf:pushi("signal.width %d", self.signal.width)
end

function Nback:drawActiveSignal()
    print('Nback:drawActiveSignal()')
    local pos = self.signals.pos[self.currentSig]
    print("self.signals", inspect(self.signals))
    print("self.signals.pos", inspect(self.signals.pos[self.currentSig]))
    print('pos', inspect(pos))

    local x, y = pos.x, pos.y

    print('self.current_sig',       inspect(self.currentSig))
    print('self.signals.color',     inspect(self.signals.color))
    print('colorConstants.colors',  inspect(colorConstants.colors))
    print('hmm',                    inspect(self.signals.color[self.currentSig]))

    local sig_color = colorConstants.colors[self.signals.color[self.currentSig]]
    print('sig_color', sig_color)

    if self.figureAlpha then
        sig_color[4] = self.figureAlpha
    else
        print("no self.figure_alpha")
    end
    --print("sig_color[4]", sig_color[4])
    local curtype: string = self.signals.form[self.currentSig]
    self.signalView:draw(x, y, curtype, sig_color)
end

function Nback:drawField()
    local field_h = self.dim * self.cellWidth
    g.setColor(self.fieldColor)
    local oldwidth = g.getLineWidth()
    g.setLineWidth(2)
    for i = 0, self.dim do
        -- horizontal
        g.line(self.x0, self.y0 + i * self.cellWidth, 
            self.x0 + field_h, self.y0 + i * self.cellWidth)
        -- vertical
        g.line(self.x0 + i * self.cellWidth, 
            self.y0, self.x0 + i * self.cellWidth, self.y0 + field_h)
    end
    g.setLineWidth(oldwidth)
end

-- draw central_text - Press Space key
function Nback:printStartPause()
    print('Nback:printStartPause')
    local central_text = i18n("waitFor", { self.start_pause_rest })
    g.setFont(self.centralFont)
    g.setColor(pallete.signal)
    local x = (w - self.centralFont:getWidth(central_text)) / 2
    local y = self.y0 + (self.dim - 1) * self.cellWidth
    g.print(central_text, x, y)
end

function Nback:mousemoved(x: number, y: number, dx: number, dy: number, istouch: boolean)
    if not self.isRun and not self.showStatistic then
        self.setupmenu:mousemoved(x, y, dx, dy, istouch)
    end
end

function Nback:mousereleased(x: number, y: number, btn: number)
    if self.statisticRender then
        self.statisticRender:mousereleased(x, y, btn)
    end
end

function Nback:mousepressed(x: number, y: number, btn: number, istouch: boolean)
    if not self.isRun and not self.showStatistic then
        self.setupmenu:mousepressed(x, y, btn, istouch)
    elseif self.statisticRender then
        self.statisticRender:mousepressed(x, y, btn, istouch)
    elseif not ON_ANDROID then
        self:checkTouchButtons(x, y)
    end
end

--[[
function Nback:touchpressed(id, x, y, dx, dy, pressure)
end

function nback:touchreleased(id, x, y, dx, dy, pressure)
end

function nback:touchmoved(id, x, y, dx, dy, pressure)
end
--]]

global nback: Nback = Nback.new()
print('hello from end of nback module')
