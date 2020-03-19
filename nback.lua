-- vim: set foldmethod=indent

require "common"
require "layout"

local Timer = require "libs.Timer"
local alignedlabels = require "alignedlabels"
local bhupur = require "bhupur"
local g = love.graphics
local generator = require "generator"
local inspect = require "libs.inspect"
local linesbuf = require "kons"(0, 0)
local lume = require "libs.lume"
local math = require "math"
local os = require "os"
local pallete = require "pallete"
local serpent = require "serpent"
local setupmenu = require "setupmenu"
local signal = require "signal"
local string = require "string"
local table = require "table"
local w, h = g.getDimensions()
local colorConstants = require "colorconstants"

local coros = {}

function processCoroutines()
    local alive = {}
    for k, v in pairs(coros) do
        local r = coroutine.resume()
        if r then
            table.insert(alive, v)
        end
    end
    coros = alive
end

local function safesend(shader, name, ...)
  if shader:hasUniform(name) then
    shader:send(name, ...)
  end
end

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
    sounds = {},
    field_color = table.copy(pallete.field), -- копия таблицы по значению
    -- хорошо-бы закешировать загрузку этих ресурсов
    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 25),
    central_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 42),
    statistic_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
}

-- создать объект и загрузить в него статистику из таблицы, загруженной из
-- файла истории. Теперь можно рисовать статистику результатов.
function nback.newStatisticRender(data)
    local self = deepcopy(nbackSelf)
    setmetatable(self, nback)
   
    self.signals = deepcopy(data.signals)
    self.percent = data.percent

    print("self.signals", inspect(self.signals))

    seld.pressed = deepcopy(data.pressed)

    --[[self.statisticRender = true]]
    self.signals.eq = generator.makeEqArrays(self.signals, self.level)

    self:resize(g.getDimensions())

    return self
end

function nback.new()
    local self = deepcopy(nbackSelf)
    self.statisticRender = require "drawstat".new()
    print("self.statisticRender", inspect(self.statisticRender))
    return setmetatable(self, nback)
end

function create_false_array(len)
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
    self.layout = screen
    --[[print("self.layout", inspect(self.layout))]]
end

function nback:start()
    print("nback:start()")
    local q = pallete.field
    -- запуск анимации цвета игрового поля
    self.timer:tween(3, self, { field_color = {q[1], q[2], q[3], 1}}, "linear")
    self.written = false
    self.pause = false
    self.is_run = true
    self.signals = generator.generateAll(self.sig_count, self.level, self.dim, #self.signal.sounds)
    print("self.signals", inspect(self.signals))
    self.current_sig = 1
    self.timestamp = love.timer.getTime() - self.pause_time
    self.show_statistic = false

    -- массивы хранящие булевские значения - нажат сигнал вот время обработки или нет?
    local signalsCount = #self.signals.pos
    self.pressed = {
        pos = create_false_array(signalsCount),
        color = create_false_array(signalsCount),
        form = create_false_array(signalsCount),
        sound = create_false_array(signalsCount),
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
        -- фиксирую время начала игры
        self.startTime = love.timer.getTime()
    end)
    self:initButtons()
end

function nback:enter()
    -- установка альфа канала цвета сетки игрового поля
    self.field_color[4] = 0.2
end

function nback:leave()
    self.show_statistic = false
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

function nback:readSettings()
    local data, _ = love.filesystem.read("settings.lua")
    if data then
        local settings = lume.deserialize(data, "all")
        print("settings loaded", inspect(settings))
        self.level = settings.level
        self.pause_time = settings.pause_time
        self.volume = settings.volume
    else
        self.volume = 0.2 -- XXX какое значение должно быть по-дефолту?
    end
    love.audio.setVolume(self.volume)
end

-- фигачу кастомную менюшку на лету
function nback:createSetupMenu()
    -- начальное значение. Можно менять исходя из
    -- предыдущих игр, брать из файла настроек и т.д.
    local nbackLevel = self.level 
    -- значение должно поддерживаться генератором, 
    -- больше значение - длиннее последовательность и(или)
    -- меньше целевых сигналов в итоге.
    local maxLevel = 8   
    
    local dim = 4
    local minDim, maxDim = 4, 20
        
    local expositionList = { "1", "2", "3", "4", "5", "6", }
    local activeExpositionItem = 2

    local parameterColor = {0, 0.9, 0}

    self.setupmenu = setupmenu(
        love.graphics.newFont("gfx/DejaVuSansMono.ttf", 30), pallete.signal, 
        linesbuf)

    -- пункт меню - поехали!
    self.setupmenu:addItem({
        oninit = function() return {"Start"} end,
        onselect = function() --  точка входа в игру
            self.level = nbackLevel
            self.dim = dim
            self:resize(g.getDimensions())
            self.pause_time = tonumber(expositionList[activeExpositionItem])
            self:start()
        end})

    -- выбор продолжительности экспозиции
    self.setupmenu:addItem({
        oninit = function() return 
            {pallete.signal, "Exposition time ", parameterColor, 
            expositionList[activeExpositionItem], pallete.signal, " sec."},
            activeExpositionItem == 1,
            activeExpositionItem == #expositionList
        end,

        onleft = function()
            if activeExpositionItem - 1 >= 1 then
                activeExpositionItem = activeExpositionItem - 1
            end
            return {pallete.signal, "Exposition time ", parameterColor,
                expositionList[activeExpositionItem], pallete.signal, " sec."}, 
                activeExpositionItem == 1,
                activeExpositionItem == #expositionList
        end,

        onright = function()
            if activeExpositionItem + 1 <= #expositionList then
                activeExpositionItem = activeExpositionItem + 1
            end
            return {pallete.signal, "Exposition time ", parameterColor,
                expositionList[activeExpositionItem], pallete.signal, " sec."},
                activeExpositionItem == 1,
                activeExpositionItem == #expositionList
        end})

    -- выбор уровня эн-назад
    self.setupmenu:addItem({
        oninit = function() return {pallete.signal, "Difficulty level: ",
            parameterColor, tostring(nbackLevel)}, 
            nbackLevel == 1,
            nbackLevel == maxLevel
        end,

        onleft = function()
            if nbackLevel - 1 >= 1 then nbackLevel = nbackLevel - 1 end
            return {pallete.signal, "Difficulty level: ", parameterColor,
                tostring(nbackLevel)},
                nbackLevel == 1,
                nbackLevel == maxLevel
        end,

        onright = function()
            if nbackLevel + 1 <= maxLevel then nbackLevel = nbackLevel + 1 end
            return {signal.color, "Difficulty level: ", parameterColor,
                tostring(nbackLevel)},
                nbackLevel == 1,
                nbackLevel == maxLevel
        end})
    
    --  выбор разрешения поля клеток для сигнала "позиция". 
    --  Рабочее значение : от 4 до 8-10-20?
    self.setupmenu:addItem({
        oninit = function() return {pallete.signal, "Dim level: ",
            parameterColor, tostring(dim)}, 
            dim == 1,
            dim == maxDim
        end,

        onleft = function()
            if dim - 1 >= minDim then dim = dim - 1 end
            return {pallete.signal, "Dim level: ", parameterColor,
                tostring(dim)},
                dim == 1,
                dim == maxLevel
        end,

        onright = function()
            if dim + 1 <= maxDim then dim = dim + 1 end
            return {signal.color, "Dim level: ", parameterColor,
                tostring(dim)},
                dim == 1,
                dim == maxLevel
        end})
end

function nback:init(save_name)
    self.save_name = save_name
    self.timer = Timer()
    self.signal = signal.new(self.cell_width, "alphabet")
    self:readSettings()
    self:createSetupMenu()
    self:resize(g.getDimensions())

    self:initShaders()
    self.shaderTimer = 0
    self.shaderTimeEnabled = true -- непутевое название переменной
    self.timer:during(2, function(dt, time, delay) 
        print(time, delay, self.shaderTimer)
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
        self.figure_alpha = 1
        local tween_time = self.pause_time / 2
        print("time delta = " .. self.pause_time - tween_time)
        self.timer:after(self.pause_time - tween_time - 0.1, function()
            self.timer:tween(tween_time, self, {figure_alpha = 0}, "out-linear")
        end)

        self.signal:play(self.signals.sound[self.current_sig])
    end
end

function nback:initButtons()
    self.buttons = {}
    -- клавиша выхода слева
    table.insert(self.buttons, { 
        x = self.layout.leftTop.x, 
        y = self.layout.leftTop.y, 
        w = self.layout.leftTop.w,
        h = self.layout.leftTop.h,
        title = "Quit",
        ontouch = function() 
            love.event.quit() 
        end})

    -- клавиша дополнительных настроек справа
    table.insert(self.buttons, { 
        x = self.layout.rightTop.x, 
        y = self.layout.rightTop.y, 
        w = self.layout.rightTop.w, 
        h = self.layout.rightTop.h,
        title = "Settings",
        ontouch = function() 
            love.event.quit() 
        end})

    -- левая верхняя клавиша управления
    table.insert(self.buttons, { 
        x = self.layout.leftMiddle.x, 
        y = self.layout.leftMiddle.y, 
        w = self.layout.leftMiddle.w, 
        h = self.layout.leftMiddle.h, 
        title = "Sound",
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
        title = "Position",
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
        title = "Form",
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
        title = "Color",
        ontouch = function() 
            if self.is_run then
                self:check("color") 
            end
        end})

    self:setupButtonsTextPositions()
end

function nback:setupButtonsTextPositions()
    for k, v in pairs(self.buttons) do
        v.textx = v.x
        v.texty = v.y + (v.h / 2 - self.font:getHeight() / 2)
    end
end

local buttonColor = {1, 0.42, 0.5}

function nback:drawButtons()
    -- эта строчка необходима так как initButtons() вызывается не в саммом
    -- подходящем месте. Найдешь место лучше, эта строчка не будет нужна.
    if not self.buttons then return end

    local oldwidth = g.getLineWidth()
    for k, v in pairs(self.buttons) do
        g.setColor(buttonColor)
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

    g.push("all")

    g.setShader(self.shader)
    if self.shaderTimeEnabled then
        self.shader:send("time", self.shaderTimer)
    end

    self:draw_field()

    if self.is_run then
        if self.start_pause then
            self:print_start_pause()
        else
            self:draw_active_signal()
            self:drawButtons()
        end
    else
        if self.show_statistic then 
            --[[self:draw_statistic()]]
            --[[require "drawstat".draw_statistic()]]
            self.statisticRender:draw()
        else
            self.setupmenu:draw()
        end
    end

    drawTouches()

    g.setShader()
    g.pop()

    drawHierachy(self.layout)
    --self:fill_linesbuf()
end

function nback:checkButtonsTouch(x, y)
    if self.buttons then
        for k, v in pairs(self.buttons) do
            if pointInRect(x, y, v.x, v.y, v.w, v.h) then
                v.ontouch()
            end
        end
    end
end

function nback:update(dt)
    self.timer:update(dt)
    processCoroutines()

    if self.pause or self.start_pause then 
        self.timestamp = love.timer.getTime() - self.pause_time
        -- подумай, нужен ли здесь код строчкой выше. 
        -- Могут ли возникнуть проблемы с таймером отсчета если 
        -- продолжительноть паузы больше self.pause_time?
        return 
    end

    local touches = love.touch.getTouches()
    for i, id in pairs(touches) do
        local x, y = love.touch.getPosition(id)
        self:checkButtonsTouch(x, y)
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

-- считывает и устанавливает набор состояний сигналов и нажатий клавиша на 
-- сигналы. Функция необходима для установки состояния из внешнего источника 
-- при необходимости последующей отрисовки экрана статистики, загруженного из
-- файла.
function nback:loadFromHistory(signals, presses)
    --вопрос - как из истории загружать?
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
    --[[
    -- Здесь добавляется информация к уже загруженной таблице со всеми данными.
    -- Плохой способ так как непонятно как рассортировать данные.
    -- И считывать приходится все подряд. Как можно сделать лучше?
    -- Хранить результаты в отдельных файлах - так себе вариант, может
    -- накопиться много файлов. serpent записывает компактно.
    --]]
    os.setlocale("C")
    local date = os.date("*t")
    print("date", inspect(date))
    table.insert(history, { date = date, 
                            signals = self.signals,
                            pressed = self.pressed,
                            level = self.level,
                            pause_time = self.pause_time,
                            percent = self.percent})
    love.filesystem.write(self.save_name, serpent.dump(history))
end

function nback:stop()
    local q = pallete.field
    -- амимация альфа-канала игрового поля
    self.timer:tween(2, self.field_color, { q[1], q[2], q[3], 0.1 }, "linear")

    self.is_run = false
    self.show_statistic = true

    print("stop")

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

    -- зачем нужна эта проверка? Расчет на то, что раунд был начат?
    if self.signals.pos then
        self.stopppedSignal = self.current_sig 
    end

    if self.startTime then
        local time = love.timer.getTime() - self.startTime
        self.durationMin = math.floor(time / 60)
        self.durationSec = time - self.durationMin * 60
        print(string.format("durationMin %f, durationSec %f", self.durationMin,
            self.durationSec))
    end

    -- Раунд полностью закончен? - записываю историю
    if self.signals and self.current_sig == #self.signals.pos then 
        self:save_to_history() 
    end
end

function nback:quit()
    self.timer:destroy()
    self:stop()
    local settings_str = lume.serialize { 
        ["volume"] = love.audio.getVolume(), 
        ["level"] = self.level, 
        ["pause_time"] = self.pause_time }
    ok, msg = love.filesystem.write("settings.lua", settings_str, 
        settings_str:len())
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
    if not useKeyboard then return end

    if scancode == "escape" then
        if self.is_run then
            print("stop by escape")
            self:stop()
        else
            self:quit()
        end
    end

    if self.is_run then
        if scancode == "a" then
            self:check("sound")
        elseif scancode == "f" then
            self:check("color")
        elseif scancode == "j" then
            self:check("form")
        elseif scancode == ";" then
            self:check("pos")
        end
    else
        -- здесь другое игровое состояние, почему используется условие и булев
        -- флаг?
        -- состояние - регулировка в меню перед игрой
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
    elseif scancode == "2" then 
        linesbuf.show = not linesbuf.show 
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

    w, h = neww, newh

    local pixels_border = 130 -- size of border around main game field
    self.cell_width = (newh - pixels_border) / self.dim
    self.bhupur_h = self.cell_width * self.dim 

    self.x0 = (w - self.dim * self.cell_width) / 2
    self.y0 = (h - self.dim * self.cell_width) / 2

    if self.signal then
        self.signal:setCorner(self.x0, self.y0)
        self.signal:resize(self.cell_width)
    end

    self:buildLayout()
    self.statisticRender:buildLayout()
end

-- return array of boolean values in succesful indices
function nback:make_hit_arr(signals, comparator)
    local ret = {}
    if signals then
        print("make_hit_arr")
        for k, v in pairs(signals) do
            ret[#ret + 1] = k > self.level and comparator(v, 
                signals[k - self.level])
        end
    end
    return ret
end

local draw_iteration = 0 -- debug variable

-- draw one big letter in left side of hit rects output
function nback:print_signal_type(x, y, rect_size, str, pixel_gap, delta)
    local delta = (rect_size - g.getFont():getHeight()) / 2
    g.print(str, x - g.getFont():getWidth(str) - pixel_gap, y + delta)
    y = y + rect_size + 6
    return x, y
end

function nback:draw_percents(x, y, rect_size, pixel_gap, border, starty)
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

function nback:fill_linesbuf()
    linesbuf:pushi("fps " .. love.timer.getFPS())
    linesbuf:pushi("pos " .. inspect(self.signals.pos))
    linesbuf:pushi("sound " .. inspect(self.sound_signals))
    linesbuf:pushi("form " .. inspect(self.form_signals))
    linesbuf:pushi("color " .. inspect(self.color_signals))
    linesbuf:pushi("current_sig = " .. self.current_sig)
    linesbuf:pushi("nback.can_press = " .. tostring(self.can_press))
    linesbuf:pushi("volume %.3f", self.volume)
    linesbuf:pushi("Mem: %.3f MB", collectgarbage("count") / 1024)
    linesbuf:pushi("signal.width %d", self.signal.width)
    linesbuf:draw()
end

-- draw active signal quad
function nback:draw_active_signal()
    local x, y = unpack(self.signals.pos[self.current_sig])
    local sig_color = colorConstants[self.signals.color[self.current_sig]]
    if self.figure_alpha then
        sig_color[4] = self.figure_alpha
    end
    local type = self.signals.form[self.current_sig]
    self.signal:draw(x, y, type, sig_color)
end

function nback:draw_field()
    local delta, field_h = 1, self.dim * self.cell_width
    g.setColor(self.field_color)
    for i = 0, self.dim do
        -- horizontal
        g.line(self.x0, self.y0 + i * self.cell_width, self.x0 + field_h, self.y0 + i * self.cell_width)
        -- vertical
        g.line(self.x0 + i * self.cell_width, self.y0, self.x0 + i * self.cell_width, self.y0 + field_h)
    end
end

-- рисовать статистику после конца сета
function nback:draw_statistic()
    -- условие нужно что-бы не падала программа при создании рендера истории.
    -- но из-за этого пункта может быть неправильное отображение графики?
    if not self.signals then
        return
    end

    g.setFont(self.font)
    g.setColor(pallete.statistic)

    local width_k = 3 / 4
    -- XXX depend on screen resolution
    local rect_size = math.floor(w * width_k / #self.signals.pos)

    --print("rect_size", rect_size)
    --print("self.statisticRender", self.statisticRender)

    local x = self.statisticRender and 0 or (w - w * width_k) / 2
    --local x = (w - w * width_k) / 2 

    local starty = self.statisticRender and 0 or 200
    local y = starty
    local border = 2

    y = y + g.getFont():getHeight() * 1.5

    local freezedY = y

    -- массивы вида self.**_eq содержат значения истина на тех индексах, где
    -- должны быть нажаты обработчики сигналов
    local draw_hit_rects = require "drawstat".draw_hit_rects
    x, y = draw_hit_rects(x, y, self.pressed.sound, self.signals.eq.sound, rect_size, border, self.level)
    x, y = draw_hit_rects(x, y, self.pressed.color, self.signals.eq.color, rect_size, border, self.level)
    x, y = draw_hit_rects(x, y, self.pressed.form, self.signals.eq.form, rect_size, border, self.level)
    x, y = draw_hit_rects(x, y, self.pressed.pos, self.signals.eq.pos, rect_size, border, self.level)

    -- drawing left column with letters
    g.setColor({200 / 255, 0, 200 / 255})

    local y = freezedY
    local pixel_gap = 10
    x, y = self:print_signal_type(x, y, rect_size, "S", pixel_gap, delta) 
    x, y = self:print_signal_type(x, y, rect_size, "C", pixel_gap, delta) 
    x, y = self:print_signal_type(x, y, rect_size, "F", pixel_gap, delta) 
    x, y = self:print_signal_type(x, y, rect_size, "P", pixel_gap, delta)

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
end

-- draw central_text - Press Space key
function nback:print_start_pause()
    local central_text = string.format("Wait for %d second.", self.start_pause_rest)
    g.setFont(self.central_font)
    g.setColor(pallete.signal)
    local x = (w - self.central_font:getWidth(central_text)) / 2
    --y = h - self.central_font:getHeight() * 2
    local y = self.y0 + (self.dim - 1) * self.cell_width
    g.print(central_text, x, y)
end

function nback:mousemoved(x, y, dx, dy, istouch)
    if not self.is_run and not self.show_statistic then
        self.setupmenu:mousemoved(x, y, dx, dy, istouch)
    end
end

function nback:mousepressed(x, y, btn, istouch)
    if not self.is_run and not self.show_statistic then
        self.setupmenu:mousepressed(x, y, btn, istouch)
    end
end

return {
    new = nback.new,
    newStatisticRender = nback.newStatisticRender,
}
