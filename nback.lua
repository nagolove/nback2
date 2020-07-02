-- vim: set foldmethod=indent

require "common"
require "layout"
require "snippets"
require "hex"

local Timer = require "libs.Timer"
local alignedlabels = require "alignedlabels"
local colorConstants = require "colorconstants"
local g = love.graphics
local gr = love.graphics
local generator = require "generator"
local getTime = love.timer.getTime
local inspect = require "libs.inspect"
local math = require "math"
local os = require "os"
local pallete = require "pallete"
local serpent = require "serpent"
local setupmenu = require "setupmenu"
local signal = require "signal"
local string = require "string"
local table = require "table"
local w, h = g.getDimensions()
local yield = coroutine.yield

local function safesend(shader, name, ...)
  if shader:hasUniform(name) then
    shader:send(name, ...)
  end
end

local function width() return love.graphics.getWidth() end
local function height() return love.graphics.getHeight() end

local nback = {}
nback.__index = nback

local nbackSelf = {
    dim = 8,    -- количество ячеек поля
    cell_width = 100,  -- width of game field in pixels
    current_sig = 1, -- номер текущего сигнала, при начале партии равен 1
    sig_count = 8, -- количество сигналов
    level = 1, -- уровень, на сколько позиций назад нужно нажимать клавишу сигнала
    is_run = false, -- индикатор запуска рабочего цикла
    pause_time = 2.0, -- задержка между сигналами, в секундах
    can_press = false, -- XXX FIXME зачем нужна эта переменная?
    show_statistic = false, -- индикатор показа статистики в конце сета
    field_color = table.copy(pallete.field), -- копия таблицы по значению
    -- хорошо-бы закешировать загрузку этих ресурсов
    font = fonts.nback.font,
    buttonsFont = fonts.nback.buttons,
    centralFont = fonts.nback.central,
    border = 3,
}

function nback.new()
    local self = deepcopy(nbackSelf)
    --print("self.statisticRender", inspect(self.statisticRender))
    return setmetatable(self, nback)
end

function makeFalseArray(len)
    local ret = {}
    for i = 1, len do
        ret[#ret + 1] = false
    end
    return ret
end

function nback:buildLayout()
    local screen = makeScreenTable()
    screen.left, screen.center, screen.right = splitv(screen, 0.2, 0.6, 0.2)
    screen.leftTop, screen.leftMiddle, screen.leftBottom = splith(screen.left, 0.2, 0.4, 0.4)
    screen.rightTop, screen.rightMiddle, screen.rightBottom = splith(screen.right, 0.2, 0.4, 0.4)

    screen.leftTop, screen.leftMiddle, screen.leftBottom = shrink(screen.leftTop, self.border), shrink(screen.leftMiddle, self.border), shrink(screen.leftBottom, self.border)
    screen.rightTop, screen.rightMiddle, screen.rightBottom = shrink(screen.rightTop, self.border), shrink(screen.rightMiddle, self.border), shrink(screen.rightBottom, self.border)
    screen.center = shrink(screen.center, self.border)

    self.layout = screen
    --print("self.layout", inspect(self.layout))
end

function nback:start()
    print("nback:start()")
    local q = pallete.field
    -- запуск анимации цвета игрового поля
    self.timer:tween(3, self, { field_color = {q[1], q[2], q[3], 1}}, "linear")
    self.written = false
    self.pause = false
    self.signals = generator.generateAll(self.sig_count, self.level, self.dim, #self.signal.sounds)
    print("self.signals", inspect(self.signals))
    self.current_sig = 1
    self.timestamp = love.timer.getTime() - self.pause_time
    self.show_statistic = false

    -- массивы хранящие булевские значения - нажат сигнал вот время обработки или нет?
    local signalsCount = #self.signals.pos
    self.pressed = {
        pos = makeFalseArray(signalsCount),
        color = makeFalseArray(signalsCount),
        form = makeFalseArray(signalsCount),
        sound = makeFalseArray(signalsCount),
    }
    print("self.pressed", inspect(self.pressed))

    -- сигнал, на котором остановилась партия. Используется для рисовки
    -- вертикальной временной черты на графике нажатий
    self.stopppedSignal = 0 
    self.start_pause_rest = 3 -- время паузы перед раундом
    self.start_pause = true
    self.timer:every(1, function() 
        self.start_pause_rest = self.start_pause_rest - 1 
    end, 
    self.start_pause_rest, function()
        self.start_pause = false
        self.is_run = true
        -- фиксирую время начала игры
        self.startTime = love.timer.getTime()
    end)

    if onAndroid or not useKeyboard then
        self:initButtons()
    end
end

function nback:enter()
    -- установка альфа канала цвета сетки игрового поля
    self.field_color[4] = 0.2

    print("nback:enter()")
    -- setup Gooi
    restoreGooi(self.gooiState)
end

function nback:leave()
    print("nback:leave()")
    self.show_statistic = false
    self.gooiState = storeGooi()
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

function nback:initShaders()
    self.shader = g.newShader(fragmentCode)
end

-- фигачу кастомную менюшку на лету
function nback:createSetupMenu()
    -- начальное значение. Можно менять исходя из
    -- предыдущих игр, брать из файла настроек и т.д.
    local nbackLevel = self.level 
    -- значение должно поддерживаться генератором, 
    -- больше значение - длиннее последовательность и(или)
    -- меньше целевых сигналов в итоге.
    local maxLevel = 3   
    
    local dim = 5
    local minDim, maxDim = 4, 10
        
    local expositionList = { "1", "2", "3", "4", "5", "6", }
    local activeExpositionItem = 2

    local parameterColor = {0, 0.9, 0}

    self.setupmenu = setupmenu(fonts.nback.setupmenu, pallete.signal)

    -- пункт меню - поехали!
    self.setupmenu:addItem({
        oninit = function() return {i18n("setupMenu.start")} end,
        onselect = function() --  точка входа в игру
            self.level = nbackLevel
            self.dim = dim
            self:resize(g.getDimensions())
            self.pause_time = tonumber(expositionList[activeExpositionItem])
            self.setupmenu.freeze = true
            self:start()
            self.setupmenu.freeze = false
        end})

    -- выбор продолжительности экспозиции
    self.setupmenu:addItem({
        oninit = function() 
            local fullStr = i18n("setupMenu.expTime_plural", {count = tonumber(expositionList[activeExpositionItem])})
            local part1, _, part2 = string.match(fullStr, "(.+)(%d)(.+)")
            return {pallete.signal, part1, parameterColor, 
                expositionList[activeExpositionItem], pallete.signal, part2},
                activeExpositionItem == 1,
                activeExpositionItem == #expositionList
        end,

        onleft = function()
            if activeExpositionItem - 1 >= 1 then
                activeExpositionItem = activeExpositionItem - 1
            end
            local fullStr = i18n("setupMenu.expTime_plural", {count = tonumber(expositionList[activeExpositionItem])})
            local part1, _, part2 = string.match(fullStr, "(.+)(%d)(.+)")
            return {pallete.signal, part1, parameterColor,
                expositionList[activeExpositionItem], pallete.signal, part2}, 
                activeExpositionItem == 1,
                activeExpositionItem == #expositionList
        end,

        onright = function()
            if activeExpositionItem + 1 <= #expositionList then
                activeExpositionItem = activeExpositionItem + 1
            end
            local fullStr = i18n("setupMenu.expTime_plural", {count = tonumber(expositionList[activeExpositionItem])})
            local part1, _, part2 = string.match(fullStr, "(.+)(%d)(.+)")
            return {pallete.signal, part1, parameterColor,
                expositionList[activeExpositionItem], pallete.signal, part2},
                activeExpositionItem == 1,
                activeExpositionItem == #expositionList
        end})

    -- выбор уровня эн-назад
    self.setupmenu:addItem({
        oninit = function() return {pallete.signal, i18n("setupMenu.diffLevel"),
            parameterColor, tostring(nbackLevel)}, 
            nbackLevel == 1,
            nbackLevel == maxLevel
        end,

        onleft = function()
            if nbackLevel - 1 >= 1 then nbackLevel = nbackLevel - 1 end
            return {pallete.signal, i18n("setupMenu.diffLevel"), parameterColor,
                tostring(nbackLevel)},
                nbackLevel == 1,
                nbackLevel == maxLevel
        end,

        onright = function()
            if nbackLevel + 1 <= maxLevel then nbackLevel = nbackLevel + 1 end
            return {signal.color, i18n("setupMenu.diffLevel"), parameterColor,
                tostring(nbackLevel)},
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

function nback:init(save_name)
    readSettings()
    self.volume = settings.volume
    love.audio.setVolume(settings.volume)
    self.save_name = save_name
    self.timer = Timer()

    local w, h = gr.getDimensions()
    local fieldSize = 5
    local rad = math.floor((math.min(w, h) / fieldSize) / 2)
    --local fieldW = rad * 2 * fieldSize
    local testHex = newHexPolygon(0, 0, rad)
    print(getHexPolygonWidth(testHex))
    print(getHexPolygonHeight(testHex))
    self.startcx = (w - getHexPolygonWidth(testHex) * fieldSize) / 2 + 
        getHexPolygonWidth(testHex) / 2
    self.startcy = (h - getHexPolygonHeight(testHex) * fieldSize) / 2 + 
        getHexPolygonHeight(testHex)

    self.map = {
            {1, 0, 1, 0, 1},
             {0, 1, 1, 0, 0},
            {0, 1, 0, 1, 0},
             {0, 1, 1, 0, 0},
            {1, 0, 1, 0, 1},
        }
    --self.startcx, self.startcy = fieldW, 100
    print("self.startcx, self.startcy", self.startcx, self.startcy)
    self.hexField, self.hexMesh = newHexField(self.startcx,
        self.startcy, self.map, rad, {1, 0, 1, 1})
    --self.hexField, self.hexMesh = require "hex".newHexField(100, 100, 10, 10,
        --rad, {1, 0, 1, 1})

    self.signal = signal.new(self.startcx, self.startcy, self.map, 
        self.cell_width, "alphabet")

    self:createSetupMenu()
    self:resize(g.getDimensions())
    self:initShaders()
    self:initShadersTimer()
    self.gooiState = storeGooi()
end

function nback:initShadersTimer()
    self.shaderTimer = 0
    self.shaderTimeEnabled = true -- непутевое название переменной
    self.timer:during(2, function(dt, time, delay) 
        --print("time, delay, shaderTimer", time, delay, self.shaderTimer)
        local delta = 0.4 * dt
        if self.shaderTimer + delta <= 1 then
            self.shaderTimer = self.shaderTimer + delta
        end
    end, function() 
        self.shaderTimeEnabled = false
    end)
end

function nback:processSignal()
    local time = love.timer.getTime()
    if (time - self.timestamp >= self.pause_time) then
        self.timestamp = time

        self.current_sig = self.current_sig + 1
        self.can_press = true

        -- setup timer for figure alpha channel animation
        --self.figure_alpha = 1
        self.figure_alpha = 0.1

        local tween_time = self.pause_time / 2
        print("tween_time", tween_time)
        print("time delta = " .. self.pause_time - tween_time)
        local after = self.pause_time - tween_time - 0.1
        --local after = 0.1
        print("after", after)

        --self.timer:tween(tween_time, self, {figure_alpha = 0}, "out-linear")
        self.timer:tween(self.pause_time / 3, self, {figure_alpha = 1}, "out-linear")

        self.timer:after(after, function()
            print("figure_alpha before", self.figure_alpha)
            print("tween_time", tween_time)
            self.timer:tween(tween_time, self, {figure_alpha = 0}, "out-linear")
            print("figure_alpha after", self.figure_alpha)
        end)

        self.signal:play(self.signals.sound[self.current_sig])
    end
end

function drawButtonCapture(button, nback)
    g.setColor{0, 0, 0}
    g.setFont(nback.buttonsFont)
    g.printf(button.title, button.textx, button.texty, button.w, "center")
end

local drawButton = function(button, nback)
    --yield()

    local ok, errmsg = pcall(function()

    local self = nback
    local ret
    repeat
        local oldwidth = g.getLineWidth()
        g.setColor(pallete.buttonColor)
        g.rectangle("fill", button.x, button.y, button.w, button.h, 6, 6)
        g.setColor{0, 0, 0}
        g.setLineWidth(2)
        g.rectangle("line", button.x, button.y, button.w, button.h, 6, 6)

        drawButtonCapture(button, nback)
        g.setLineWidth(oldwidth)
        ret = yield()
    until ret == "exit"

    end)
    --print("ok, errmsg", ok, errmsg)

end

local drawButtonClicked = function(button, nback)
    --yield()

    local ok, errmsg = pcall(function()

    local btnColor = table.copy(pallete.buttonColor)
    --btnColor[4] = 1
    local ret
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

        ret = yield()
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

        ret = yield()
    until ret == "exit"

    end)
    --print("ok, errmsg", ok, errmsg)

end

function nback:initButtons()
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
            menu:goBack()
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
            if self.is_run then
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
            if self.is_run then
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
            if self.is_run then
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
            if self.is_run then
                self:check("color") 
            end
        end})

    self:setupButtonsTextPosition()

    for k, v in pairs(self.buttons) do
        self.processor:push(v.coroName, drawButton, v, self)
        --self.processor:push(v.coroName, drawButtonClicked, v, self)
    end

    self.namedButtons = {}
    for k, v in pairs(self.buttons) do
        self.namedButtons[v.coroName] = v
    end
end

function nback:setupButtonsTextPosition()
    for k, v in pairs(self.buttons) do
        v.textx = v.x
        v.texty = v.y + (v.h / 2 - self.font:getHeight() / 2)
    end
end

function nback:drawButtons()
    -- эта строчка необходима так как initButtons() вызывается не в саммом
    -- подходящем месте. Найдешь место лучше, эта строчка не будет нужна.
    if not self.buttons then return end

    local oldwidth = g.getLineWidth()
    for k, v in pairs(self.buttons) do
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

function drawTouches()
    local touches = love.touch.getTouches()
    for i, id in ipairs(touches) do
        local x, y = love.touch.getPosition(id)
        g.setColor{0, 0, 0}
        g.circle("fill", x, y, 20)
    end
end

function nback:draw()
    love.graphics.clear(pallete.background)

    --g.push("all")

    --[[
       [g.setShader(self.shader)
       [if self.shaderTimeEnabled then
       [    self.shader:send("time", self.shaderTimer)
       [end
       ]]

    if self.is_run then
        if self.start_pause then
            tiledback:draw(0.3)
            self:drawField()
            self:printStartPause()
        else
            tiledback:draw(0.3)
            --self:drawField()

            gr.draw(self.hexMesh)

            self:drawActiveSignal()
            --self.processor:update()
            --self:drawButtons()
        end
    else
        if self.show_statistic then 
            tiledback:draw(0.3)
            self.statisticRender:draw()
        else
            tiledback:draw(0.3)
            self.setupmenu:draw()
        end
    end

    drawTouches()

    if useKeyboard then
        linesbuf:pushi("[a] - sound [f] - color [j] - form [;] - position")
    end

    --g.setShader()
    --g.pop()

    --g.setColor{0, 0, 0}
    --[[drawHierachy(self.layout)]]
end

function nback:checkTouchButtons(x, y)
    if self.buttons then
        for k, v in pairs(self.buttons) do
            if pointInRect(x, y, v.x, v.y, v.w, v.h) then
                v.ontouch()
                self.processor:sendMessage(v.coroName, "exit")
                self.processor:push(v.coroName, drawButtonClicked, v, self)
            end
        end
    end
end

function nback:processTouches()
    local touches = love.touch.getTouches()
    for i, id in pairs(touches) do
        local x, y = love.touch.getPosition(id)
        self:checkTouchButtons(x, y)
    end
end

function nback:update(dt)
    self:fillLinesbuf()
    self.timer:update(dt)
    self.processor:update()

    if self.pause or self.start_pause then 
        self.timestamp = love.timer.getTime() - self.pause_time
        -- подумай, нужен ли здесь код строчкой выше. 
        -- Могут ли возникнуть проблемы с таймером отсчета если 
        -- продолжительноть паузы больше self.pause_time?
        return 
    end

    if onAndroid then
        self:processTouches()
    end

    if self.is_run then
        if self.current_sig < #self.signals.pos then
            self:processSignal()
        else
            self:stop()
        end
    else
        if not self.show_statistic then
            self.setupmenu:update(dt)
        end
    end
end

function nback:save_to_history()
    if self.written then
        return
    else
        self.written = true
    end

    local history = {}
    local data, size = love.filesystem.read(self.save_name)
    if data ~= nil then
        ok, history = serpent.load(data)
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
                            pause_time = self.pause_time,
                            percent = self.percent})
    love.filesystem.write(self.save_name, serpent.dump(history))
    collectgarbage()
end

function nback:stop(byescape)
    print("stop")
    local q = pallete.field
    -- амимация альфа-канала игрового поля
    self.timer:tween(2, self.field_color, { q[1], q[2], q[3], 0.1 }, "linear")

    self.is_run = false
    self.show_statistic = true

    -- зачем нужна эта проверка? Расчет на то, что раунд был начат?
    if self.signals and self.signals.pos then
        self.stopppedSignal = self.current_sig 
    end

    print("byescape", byescape)
    if not byescape then
        local duration = love.timer.getTime() - self.startTime
        self.durationMin = math.floor(duration / 60)
        self.durationSec = duration - self.durationMin * 60
        print(string.format("durationMin %f, durationSec %f", self.durationMin, self.durationSec))

        -- Раунд полностью закончен? - записываю историю
        if self.signals and self.current_sig == #self.signals.pos then 
            self:save_to_history() 
        end

        self.statisticRender = require "drawstat".new({
            signals = self.signals,
            pressed = self.pressed,
            level = self.level,
            pause_time = self.pause_time,

            x0 = self.x0,
            y0 = self.y0,
            font = self.font,
            durationMin = self.durationMin,
            durationSec = self.durationSec,
            buttons = true, -- флажок - показывать ли кнопку "вернуться"
        })
    end
end

function nback:quit(byescape)
    self.timer:destroy()
    self:stop(byescape)
    settings.volume = self.volume
    settings.level = self.level
    settings.pause_time = self.pause_time
    settings.dim = self.dim
    writeSettings()
    menu:goBack()
end

function nback:keyreleased(_, scancode)
    --print(string.format("nback:keyreleased(%s)", scancode))
    if not self.is_run and not self.show_statistic then
        if scancode == "left" or scancode == "h" then
            self.setupmenu:leftReleased()
        elseif scancode == "right" or scancode == "l" then
            self.setupmenu:rightReleased()
        end
    end
end

-- use scancode, Luke!
function nback:keypressed(_, scancode)
    if useKeyboard then 
        if self.is_run then
            if scancode == "a" then
                self:check("sound")
                self.processor:push("soundBtn", drawButtonClicked, self.namedButtons["soundBtn"], self)
                self.processor:sendMessage("soundBtn", "exit")
            elseif scancode == "f" then
                self:check("color")
                self.processor:push("colorBtn", drawButtonClicked, self.namedButtons["colorBtn"], self)
                self.processor:sendMessage("colorBtn", "exit")
            elseif scancode == "j" then
                self:check("form")
                self.processor:push("formBtn", drawButtonClicked, self.namedButtons["formBtn"], self)
                self.processor:sendMessage("formBtn", "exit")
            elseif scancode == ";" then
                self:check("pos")
                self.processor:push("posBtn", drawButtonClicked, self.namedButtons["posBtn"], self)
                self.processor:sendMessage("posBtn", "exit")
            end
        else
            if not self.show_statistic then
                if scancode == "space" or scancode == "return" then
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
    else
        if scancode == "escape" or "achome" then
            if self.is_run then
                print("stop by escape")
                self:stop()
            else
                self:quit(true)
            end
        end
    end
end

local soundVolumeStep = 0.05

function nback:loverVolume()
    if self.volume - soundVolumeStep >= 0 then
        self.volume = self.volume - soundVolumeStep
        love.audio.setVolume(self.volume)
    end
end

function nback:raiseVolume()
    if self.volume + soundVolumeStep <= 1 then
        self.volume = self.volume + soundVolumeStep
        love.audio.setVolume(self.volume)
    end
end

-- signal type may be "pos", "sound", "color", "form"
function nback:check(signalType)
    -- эта проверка должна выполняться в другом месте, снаружи данной функции.
    if not self.is_run then
        return
    end

    local signals = self.signals[signalType]
    local cmp = function(a, b) return a == b end
    if signalType == "pos" then
        cmp = function(a, b)
            return a[1] == b[1] and a[2] == b[2]
        end
    end

    self.pressed[signalType][self.current_sig] = true
    if self.current_sig - self.level > 1 then
        if cmp(signals[self.current_sig], signals[self.current_sig - self.level]) then
            --print(inspect(nback))
            if self.can_press then
                print(signalType .. " hit!")
                self.can_press = false
            end
        end
    end
end

function nback:resize(neww, newh)
    print(string.format("resized to %d * %d", neww, newh))
    self:buildLayout()

    w, h = neww, newh

    self.cell_width = self.layout.center.h / self.dim
    self.bhupur_h = self.cell_width * self.dim 
    self.x0, self.y0 = self.layout.center.x + (self.layout.center.w - self.layout.center.h) / 2, self.layout.center.y
    self.processor = require "coroprocessor".new()

    if self.signal then
        self.signal:setCorner(self.x0, self.y0)
        self.signal:resize(self.cell_width)
    end

    if self.statisticRender then
        self.statisticRender:buildLayout(self.border)
    end
end

local draw_iteration = 0 -- debug variable

function nback:inspectSignals()
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
end

function nback:fillLinesbuf()
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

    linesbuf:pushi("current_sig = " .. self.current_sig)
    linesbuf:pushi("nback.can_press = " .. tostring(self.can_press))
    linesbuf:pushi("volume %.3f", self.volume)
    linesbuf:pushi("Mem: %.3f MB", collectgarbage("count") / 1024)
    linesbuf:pushi("signal.width %d", self.signal.width)
end

-- draw active signal quad
function nback:drawActiveSignal()
    local x, y = unpack(self.signals.pos[self.current_sig])
    local sig_color = colorConstants[self.signals.color[self.current_sig]]
    if self.figure_alpha then
        sig_color[4] = self.figure_alpha
    else
        print("no self.figure_alpha")
    end
    --print("sig_color[4]", sig_color[4])
    local type = self.signals.form[self.current_sig]
    self.signal:draw(x, y, type, sig_color)
end

function nback:drawField()
    local field_h = self.dim * self.cell_width
    g.setColor(self.field_color)
    local oldwidth = g.getLineWidth()
    g.setLineWidth(2)
    for i = 0, self.dim do
        -- horizontal
        g.line(self.x0, self.y0 + i * self.cell_width, self.x0 + field_h, self.y0 + i * self.cell_width)
        -- vertical
        g.line(self.x0 + i * self.cell_width, self.y0, self.x0 + i * self.cell_width, self.y0 + field_h)
    end
    --g.setLineWidth(oldwidth)
end

-- draw central_text - Press Space key
function nback:printStartPause()
    local central_text = i18n("waitFor", { self.start_pause_rest })
    g.setFont(self.centralFont)
    g.setColor(pallete.signal)
    local x = (w - self.centralFont:getWidth(central_text)) / 2
    local y = self.y0 + (self.dim - 1) * self.cell_width
    g.print(central_text, x, y)
end

function nback:mousemoved(x, y, dx, dy, istouch)
    if not self.is_run and not self.show_statistic then
        self.setupmenu:mousemoved(x, y, dx, dy, istouch)
    end
end

function nback:mousereleased(x, y, btn)
    if self.statisticRender then
        self.statisticRender:mousereleased(x, y, btn)
    end
end

function nback:mousepressed(x, y, btn, istouch)
    if not self.is_run and not self.show_statistic then
        self.setupmenu:mousepressed(x, y, btn, istouch)
    elseif self.statisticRender then
        self.statisticRender:mousepressed(x, y, btn, istouch)
    elseif not onAndroid then
        self:checkTouchButtons(x, y)
    end
end

function nback:touchpressed(id, x, y, dx, dy, pressure)
end

function nback:touchreleased(id, x, y, dx, dy, pressure)
end

function nback:touchmoved(id, x, y, dx, dy, pressure)
end

return {
    new = nback.new,
}
