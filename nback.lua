local inspect = require "libs.inspect"
local serpent = require "serpent"
local lume = require "libs.lume"
local math = require "math"
local os = require "os"
local string = require "string"
local table = require "table"
local Timer = require "libs.Timer"
local Kons = require "kons"
local pallete = require "pallete"
local bhupur = require "bhupur"
local g = love.graphics
local w, h = g.getDimensions()
local linesbuf = Kons(0, 0)
local alignedlabels = require "alignedlabels"
local setupmenu = require "setupmenu"
local signal = require "signal"
local generate = require "generator".generate

local color_constants = {
        ["brown"] = {136 / 255, 55 / 255, 41 / 255},
        ["green"] = {72 / 255, 180 / 255, 66 / 255},
        ["blue"] = {27 / 255, 30 / 255, 249 / 255},
        ["red"] = {241 / 255, 30 / 255, 27 / 255},
        ["yellow"] = {231 / 255, 227 / 255, 11 / 255},
        ["purple"] = {128 / 255, 7 / 255, 128 / 255},
}

local function safesend(shader, name, ...)
  if shader:hasUniform(name) then
    shader:send(name, ...)
  end
end

local nback = {}
nback.__index = nback

function nback.new()
    local self = {
        dim = 5,    -- количество ячеек поля
        cell_width = 100,  -- width of game field in pixels
        current_sig = 1, -- номер текущего сигнала, при начале партии равен 1
        sig_count = 8, -- количество сигналов
        level = 2, -- уровень, на сколько позиций назад нужно нажимать клавишу сигнала
        is_run = false, -- индикатор запуска рабочего цикла
        pause_time = 2.0, -- задержка между сигналами, в секундах
        can_press = false, -- XXX FIXME зачем нужна эта переменная?
        show_statistic = false, -- индикатор показа статистики в конце сета
        sounds = {},
        font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 25),
        central_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 42),
        statistic_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
        field_color = table.copy(pallete.field) -- копия таблицы по значению
    }

    return setmetatable(self, nback)
end

function create_false_array(len)
    local ret = {}
    for i = 1, len do
        ret[#ret + 1] = false
    end
    return ret
end

function nback:generate_signals()
    local color_arr = {}
    for k, _ in pairs(color_constants) do
        color_arr[#color_arr + 1] = k
    end

    function genArrays()
        self.pos_signals = generate(self.sig_count, 
            function() return {math.random(1, self.dim - 1), 
                               math.random(1, self.dim - 1)} end,
            function(a, b) return  a[1] == b[1] and a[2] == b[2] end,
            self.level)
        print("pos", inspect(self.pos_signals))
        self.form_signals = generate(self.sig_count,
            function()
                local arr = {"trup", 
                             "trdown", 
                             "trupdown", 
                             "quad", 
                             "circle", 
                             "rhombus"}
                return arr[math.random(1, 6)]
            end,
            function(a, b) return a == b end,
            self.level)
        print("form", inspect(self.form_signals))
        self.sound_signals = generate(self.sig_count, 
            function() return math.random(1, #self.sounds) end,
            function(a, b) return a == b end,
            self.level)
        print("snd", inspect(self.sound_signals))
        self.color_signals = generate(self.sig_count,
            function() return color_arr[math.random(1, 6)] end,
            function(a, b)
                print(string.format("color comparator a = %s, b = %s", 
                    a, inspect(b)))
                return a == b end,
            self.level)
        print("color", inspect(self.color_signals))

        self.pos_eq = self:make_hit_arr(self.pos_signals, 
            function(a, b) return a[1] == b[1] and a[2] == b[2] end)
        self.sound_eq = self:make_hit_arr(self.sound_signals, 
            function(a, b) return a == b end)
        self.color_eq = self:make_hit_arr(self.color_signals, 
            function(a, b) return a == b end)
        self.form_eq = self:make_hit_arr(self.form_signals, 
            function(a, b) return a == b end)
    end

    -- попытка балансировки массивов от множественного совпадения(более двух сигналов на фрейм)
    -- случайной перегенерацией
    function balance(forIterCount)
        local i = 0
        local changed = false
        repeat
            i = i + 1
            genArrays()
            for k, v in pairs(self.pos_eq) do
                local n = 0
                n = n + (v and 1 or 0)
                n = n + (self.sound_eq[k] and 1 or 0)
                n = n + (self.form_eq[k] and 1 or 0)
                n = n + (self.color_eq[k] and 1 or 0)
                if n > 2 then
                    changed = true
                    print("changed")
                end
            end
            print("changed = " .. tostring(changed))
        until i >= forIterCount or not changed
        print("balanced for " .. i .. " iterations")
    end

    balance(5)
end

function nback:start()
    local q = pallete.field
    -- запуск анимации цвета игрового поля
    self.timer:tween(3, self, { field_color = {q[1], q[2], q[3], 1}}, "linear")

    print("start")

    self.pause = false
    self.is_run = true

    self:generate_signals()

    self.current_sig = 1
    self.timestamp = love.timer.getTime() - self.pause_time
    self.show_statistic = false

    -- массивы хранящие булевские значения - нажат сигнал вот время обработки или нет?
    self.pos_pressed_arr = create_false_array(#self.pos_signals)
    self.color_pressed_arr = create_false_array(#self.color_signals)
    self.form_pressed_arr = create_false_array(#self.form_signals)
    self.sound_pressed_arr = create_false_array(#self.sound_signals)
    print(inspect(self.pos_pressed_arr))
    print(inspect(self.color_pressed_arr))
    print(inspect(self.form_pressed_arr))
    print(inspect(self.sound_pressed_arr))

    self.start_pause_rest = 4
    self.start_pause = true
    self.timer:every(1, function() 
        self.start_pause_rest = self.start_pause_rest - 1 
    end, 4, function()
        self.start_pause = false
    end)
    print("end of start")
end

function nback:enter()
    -- установка альфа канала цвета сетки игрового поля
    self.field_color[4] = 0.2
end

function nback:leave()
    self.show_statistic = false
end

--nback.setupmenu = nil 

-- изменяется в пределах 0..1
local fragmentCode = [[
extern float time;
vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
    vec4 pixel = Texel(image, uvs);
    float av = (pixel.r + pixel.g + pixel.b) / time;
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

function nback:init(save_name)
    self.save_name = save_name

    -- фигачу кастомную менюшку на лету
    self.setupmenu = setupmenu.new(
        love.graphics.newFont("gfx/DejaVuSansMono.ttf", 25),
        pallete.tip_text)

    local mnu = self.setupmenu

    -- какие тут могут быть параметры?
    -- что выдает пункт меню для рисовки? статичный текст?
    local pauseTimeList = {
        "1.4s .. 1.8s",
        "1.8s .. 2.2s",
        "2.2s .. 2.6s",
    }
    local activePauseTimeListItem = 2

    -- возвращает строку для рисовки после перемотки влево.
    function onleft()
        -- эта строчка должна попадать во внутренний буфер вызывающего меню
        if activePauseTimeListItem - 1 >= 1 then
            activePauseTimeListItem = activePauseTimeListItem - 1
        end
        return pauseTimeList[activePauseTimeListItem]
    end

    -- возвращает строку для рисовки после перемотки вправо.
    function onright()
        if activePauseTimeListItem + 1 <= #pauseTimeList then
            activePauseTimeListItem = activePauseTimeListItem + 1
        end
        return pauseTimeList[activePauseTimeListItem]
    end

    -- непонятно, рисовать прямо в функции или только возвращать строчку
    -- текста для рисовки
    -- какой структуры должен быть объект?
    function ondraw(item, x, y, w, h)
        local text = item.pauseTimeList[item.activePauseTimeListItem]
        love.graphics.print(text)
    end

    -- добавить здесь создание объекта, обеспечивающего внутри себя перемотку
    -- состояний.
    mnu:addItem()

    math.randomseed(os.time())
    self.timer = Timer()

    wave_path = "sfx/alphabet"
    for k, v in pairs(love.filesystem.getDirectoryItems(wave_path)) do
        table.insert(self.sounds, love.audio.newSource(wave_path .. "/" .. v, "static"))
    end

    self.signal = signal.new(self.cell_width, "alphabet")

    self:resize(g.getDimensions())
    self:readSettings()
    self:initShaders()
end

function nback:processSignal()
    local time = love.timer.getTime()
    if (time - self.timestamp >= self.pause_time) then
        self.timestamp = love.timer.getTime()

        self.current_sig = self.current_sig + 1
        self.can_press = true

        -- setup timer for figure alpha channel animation
        self.figure_alpha = 1
        local tween_time = 0.5
        print("time delta = " .. self.pause_time - tween_time)
        self.timer:after(self.pause_time - tween_time - 0.1, function()
            self.timer:tween(tween_time, self, {figure_alpha = 0}, "out-linear")
        end)

        local snd = self.sounds[self.sound_signals[self.current_sig]]
        --print("snd", inspect(self.sound_signals[self.current_sig]), snd:getVolume(), snd:getDuration())
        snd:play()

        self.pos_pressed = false
        self.sound_pressed = false
        self.form_pressed = false
        self.color_pressed = false
    end
end

function nback:update(dt)
    self.timer:update(dt)

    if self.pause or self.start_pause then 
        self.timestamp = love.timer.getTime() - self.pause_time
        -- подумай, нужен ли здесь код строчкой выше. Могут ли возникнуть проблемы с таймером отсчета
        -- если продолжительноть паузы больше self.pause_time?
        return 
    end

    if self.is_run then
        if self.current_sig < #self.pos_signals then
            self:processSignal()
        else
            self:stop()
        end
    end

end

function calc_percent(eq, pressed_arr)
    if not eq then return 0 end --0% если не было нажатий

    local count = 0
    local succ = 0
    local mistake = 0
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
    print(string.format("calc_percent() count = %d, succ = %d, mistake = %d", 
        count, succ, mistake))
    return succ / count - mistake / count
end

-- считывает и устанавливает набор состояний сигналов и нажатий клавиша на 
-- сигналы. Функция необходима для установки состояния из внещнего источника 
-- при необходимости последующей отрисовки экрана статистики, загруженного из
-- файла.
function nback:loadFromHistory(signals, presses)
    --вопрос - как из истории загружать?
end

function nback:save_to_history()
    local history = {}
    local data, size = love.filesystem.read(self.save_name)
    if data ~= nil then
        ok, history = serpent.load(data)
    end
    table.insert(history, { date = d, 
                            pos_signals = self.pos_signals,
                            form_signals = self.form_signals,
                            sound_signals = self.sound_signals,
                            color_signals = self.color_signals,
                            pos_pressed_arr = self.pos_pressed_arr,
                            form_pressed_arr = self.form_pressed_arr,
                            sound_pressed_arr = self.sound_pressed_arr,
                            color_pressed_arr = self.color_pressed_arr,
                            time = os.time(d), 
                            nlevel = self.level,
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
    print(inspect(self.sound_pressed_arr))
    print(inspect(self.color_pressed_arr))
    print(inspect(self.form_pressed_arr))
    print(inspect(self.pos_pressed_arr))

    local p =  calc_percent(self.sound_eq, self.sound_pressed_arr)
    self.sound_percent = p > 0.0 and p or 0.0

    p = calc_percent(self.color_eq, self.color_pressed_arr)
    self.color_percent = p > 0.0 and p or 0.0

    p = calc_percent(self.form_eq, self.form_pressed_arr)
    self.form_percent = p > 0.0 and p or 0.0

    p = calc_percent(self.pos_eq, self.pos_pressed_arr)
    self.pos_percent = p > 0.0 and p or 0.0

    self.percent = (self.sound_percent + self.color_percent + 
        self.form_percent + self.pos_percent) / 4

    -- Раунд полностью закончен? - записываю историю
    if self.pos_signals and self.current_sig == #self.pos_signals then 
        self:save_to_history() 
    end
end

function nback:quit()
    self.timer:destroy()
    local settings_str = lume.serialize { 
        ["volume"] = love.audio.getVolume(), 
        ["level"] = self.level, 
        ["pause_time"] = self.pause_time }
    ok, msg = love.filesystem.write("settings.lua", settings_str, 
        settings_str:len())
    self:stop()
    menu:goBack()
end

-- use scancode, Luke!
function nback:keypressed(key, scancode)
    if key == "escape" then
        if self.is_run then
            self:stop()
        else
            self:quit()
        end
    elseif key == "space" or key == "return" then
            self:start()

        elseif key == "a" then
            self:check("sound")
        elseif key == "f" then
            self:check("color")
        elseif key == "j" then
            self:check("form")
        elseif key == ";" then
            self:check("pos")
        end

        -- здесь другое игровое состояние, почему используется условие и булев
        -- флаг?
        if not self.is_run and not self.show_statistic then
            if key == "up" then
                self.setupmenu:scrollUp()
            elseif key == "down" then 
                self.setupmenu:scrollDown()
            elseif key == "left" then
                self.setupmenu:leftPressed()
            elseif key == "right" then
                self.setupmenu:rightPressed()
            end
        end

        if key == "-" then 
            self:loverVolume()
        elseif key == "=" then
            self:raiseVolume()
        end

    if key == "2" then linesbuf.show = not linesbuf.show end
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
    if not self.is_run then
        return
    end
    local signals = self[signalType .. "_signals"]
    local cmp = function(a, b) return a == b end
    if signalType == "pos" then
        cmp = function(a, b)
            return a[1] == b[1] and a[2] == b[2]
        end
    end
    self[signalType .. "_pressed"] = true
    -- ненадолго включаю подсветку введеной клавиши на игровом поле
    self.timer:after(0.2, function() 
        nback[signalType .. "_pressed"] = false 
    end)
    self[signalType .. "_pressed_arr"][self.current_sig] = true
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

    w = neww
    h = newh

    local pixels_border = 130 -- size of border around main game field
    self.cell_width = (newh - pixels_border) / self.dim
    self.signal.width = self.cell_width
    self.bhupur_h = self.cell_width * self.dim 

    local delta = 20 -- for avoiding intersection between field and bottom lines of text
    self.x0 = (w - self.dim * self.cell_width) / 2
    self.y0 = (h - self.dim * self.cell_width) / 2 - delta

    self.signal:setCorner(self.x0, y0)
end

-- return array of boolean values in succesful indices
function nback:make_hit_arr(signals, comparator)
    local ret = {}
    for k, v in pairs(signals) do
        ret[#ret + 1] = k > self.level and comparator(v, signals[k - self.level])
    end
    return ret
end

function draw_signal_form(x0, y0, formtype, xdim, ydim, color)
    local border = 5
    local x, y = x0 + xdim * nback.cell_width + border, y0 + ydim * nback.cell_width + border
    local w, h = nback.cell_width - border * 2, nback.cell_width - border * 2
    g.setColor(color)

    if formtype == "quad" then
        local delta = 5
        g.rectangle("fill", x + delta, y + delta, w - delta * 2, h - delta * 2)
    elseif formtype == "circle" then
        --g.circle("fill", x + w / 2, y + h / 2, w / 2)
        --g.setColor({1, 0, 1})
        g.circle("fill", x + w / 2, y + h / 2, w / 2.3)
    elseif formtype == "trup" then
        --g.polygon("fill", {x, y + h * (2 / 3), x + w / 2, y, x + w, y + h * (2 / 3)})
        --g.polygon("fill", {x, y + h * (2.2 / 3), x + w / 2, y, x + w, y + h * (2.2 / 3)})
        local tri = {}
        local rad = w / 2
        for i = 1, 3 do
            local alpha = 2 * math.pi * i / 3
            local sx = x + w / 2 + rad * math.sin(alpha)
            local sy = y + h / 2 + rad * math.cos(alpha)
            tri[#tri + 1] = sx
            tri[#tri + 1] = sy
        end
        g.polygon("fill", tri)
    elseif formtype == "trdown" then
        --g.polygon("fill", {x, y + h / 3, x + w / 2, y + h, x + w, y + h / 3})
        local tri = {}
        local rad = w / 2
        for i = 1, 3 do
            local alpha = math.pi + 2 * math.pi * i / 3
            local sx = x + w / 2 + rad * math.sin(alpha)
            local sy = y + h / 2 + rad * math.cos(alpha)
            tri[#tri + 1] = sx
            tri[#tri + 1] = sy
        end
        g.polygon("fill", tri)
    elseif formtype == "trupdown" then
        --g.polygon("fill", {x, y + h * (2 / 3), x + w / 2, y, x + w, y + h * (2 / 3)})
        --g.polygon("fill", {x, y + h / 3, x + w / 2, y + h, x + w, y + h / 3})
        --g.setColor({0, 1, 1})
        local tri_up, tri_down = {}, {}
        local rad = w / 2
        for i = 1, 3 do
            local alpha = 2 * math.pi * i / 3
            local sx = x + w / 2 + rad * math.sin(alpha)
            local sy = y + h / 2 + rad * math.cos(alpha)
            tri_up[#tri_up + 1] = sx
            tri_up[#tri_up + 1] = sy
            local alpha = math.pi + 2 * math.pi * i / 3
            local sx = x + w / 2 + rad * math.sin(alpha)
            local sy = y + h / 2 + rad * math.cos(alpha)
            tri_down[#tri_down + 1] = sx
            tri_down[#tri_down + 1] = sy
        end
        g.polygon("fill", tri_up)
        g.polygon("fill", tri_down)
    elseif formtype == "rhombus" then
        --g.polygon("fill", {x, y + h / 2, x + w / 2, y + h,  x + w, y + h / 2, x + w / 2, y})
        --g.setColor({0, 1, 1})
        local delta = 0
        g.polygon("fill", {x + delta, y + h / 2, 
                           x + w / 2, y + h - delta,
                           x + w - delta, y + h / 2,
                           x + w / 2, y + delta})
    end
    function draw_central_circle()
        local rad = 3
        g.setColor({0, 0, 0})
        g.circle("fill", x + w / 2 - rad / 2, y + h / 2 - rad / 2, rad)
    end
    --draw_central_circle()
end

function nback:draw_field_grid(x0, y0, field_h)
    g.setColor(self.field_color)
    for i = 0, self.dim do
        -- horizontal
        g.line(self.x0, self.y0 + i * self.cell_width, 
            self.x0 + field_h, self.y0 + i * self.cell_width)
        -- vertical
        g.line(self.x0 + i * self.cell_width, self.y0, 
            self.x0 + i * self.cell_width, self.y0 + field_h)
    end
end

-- x, y - координаты левого верхнего угла отрисовываемой картинки.
-- arr - массив со значениями чего?
-- eq - массив-наложение на arr, для успешных попаданий?
-- rect_size - размер отображаемого в сетке прямоугольника
-- border - зазор между прямоугольниками.
function nback:draw_hit_rects(x, y, arr, eq, rect_size, border)
    local hit_color = {200 / 255, 10 / 255, 10 / 255}
    for k, v in pairs(arr) do
        g.setColor(pallete.field)
        g.rectangle("line", x + rect_size * (k - 1), y, rect_size, rect_size)
        g.setColor(pallete.inactive)
        g.rectangle("fill", 
            x + rect_size * (k - 1) + border, 
            y + border, rect_size - border * 2, 
            rect_size - border * 2)
        if v then
            g.setColor(hit_color)
            g.rectangle("fill", 
                x + rect_size * (k - 1) + border, 
                y + border, rect_size - border * 2, 
                rect_size - border * 2)
        end
        -- draw circle in center of quad if it is successful
        if eq[k] then
            local radius = 4
            g.setColor({0, 0, 0})
            g.circle("fill", 
                x + rect_size * (k - 1) + rect_size / 2, 
                y + rect_size / 2, 
                radius)
        end
    end
    y = y + rect_size + 6
    return x, y
end

local draw_iteration = 0 -- debug variable

-- draw one big letter in left side of draw_hit_rects() output
function nback:print_signal_type(x, y, rect_size, str, pixel_gap, delta)
    local delta = (rect_size - g.getFont():getHeight()) / 2
    g.print(str, x - g.getFont():getWidth(str) - pixel_gap, y + delta)
    y = y + rect_size + 6
    return x, y
end

-- Почему название функции не draw_percents()?
function nback:print_percents(x, y, rect_size, pixel_gap, border, starty)
    local sx = x + rect_size * (#self.pos_signals - 1) + border + rect_size 
        - border * 2 + pixel_gap
    g.setColor({200 / 255, 0, 200 / 255})
    g.setFont(nback.font)
    local formatStr = "%.3f"
    g.print(string.format(formatStr, self.sound_percent), sx, y)
    y = y + rect_size + 6
    g.print(string.format(formatStr, self.color_percent), sx, y)
    y = y + rect_size + 6
    g.print(string.format(formatStr, self.form_percent), sx, y)
    y = y + rect_size + 6
    g.print(string.format(formatStr, self.pos_percent), sx, y)
    y = starty + 4 * (rect_size + 20)
    g.printf(string.format("rating " .. formatStr, self.percent), 0, y, w, "center")
    return x, y
end

function nback:print_debug_info()
    linesbuf:pushi("fps " .. love.timer.getFPS())
    linesbuf:pushi("pos " .. inspect(self.pos_signals))
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

function nback:print_set_results(x0, y0)
    print(x0, y0)
    local y = y0 + self.font:getHeight()
    g.printf(string.format("Set results:"), 0, y, w, "center")
    y = y + self.font:getHeight()
    g.printf(string.format("level %d", self.level), 0, y, w, "center")
    y = y + self.font:getHeight()
    g.printf(string.format("Pause time %.1f sec", self.pause_time), 
        0, y, w, "center")
end

function nback:draw_level_welcome()
    g.setFont(self.font)
    --FIXME Dissonance with color and variable name
    g.setColor(pallete.tip_text) 

    local y = (h - g.getFont():getHeight() * 4) / 2.5
    g.printf(string.format("nback level is %d", self.level), 0, y, w, "center")

    y = y + self.font:getHeight()
    g.printf("Use ←→ arrows to setup", 0, y, w, "center")

    y = y + self.font:getHeight() * 2
    -- почему здесь используется два разных слова? Переименовать переменную или
    -- переписать строку вывода
    g.printf(string.format("delay time is %.1f sec", self.pause_time), 0, y, w, "center")

    y = y + self.font:getHeight()
    g.printf("Use ↑↓ arrows to setup", 0, y, w, "center")
end

-- draw central_text - Press Space key
function nback:print_press_space_to_new_round(y0)
    local central_text = "Press Space to new round"
    g.setFont(self.central_font)
    g.setColor(pallete.signal)
    local x = (w - self.central_font:getWidth(central_text)) / 2
    --y = h - self.central_font:getHeight() * 2
    local y = self.y0 + (self.dim - 1) * self.cell_width
    g.print(central_text, x, y)
end

function nback:print_control_tips(bottom_text_line_y)
    local keys_tip = alignedlabels.new(self.font, w)

    local color = self.sound_pressed and pallete.active or pallete.inactive
    keys_tip:add("Sound [", color, "a", pallete.highLightedTextColor, "]", color)

    color = self.color_pressed and pallete.active or pallete.inactive
    keys_tip:add("Color [", color, "f", pallete.highLightedTextColor, "]", color)

    color = self.form_pressed and pallete.active or pallete.inactive
    keys_tip:add("Form [", color, "j", pallete.highLightedTextColor, 
        "]", color)

    color = self.pos_pressed and pallete.active or pallete.inactive
    keys_tip:add("Position [", color, ";", pallete.highLightedTextColor, "]", color)

    keys_tip:draw(0, bottom_text_line_y)
end

-- draw escape tip
function nback:print_escape_tip(bottom_text_line_y)
    g.setFont(self.font)
    g.setColor(pallete.tip_text)
    g.printf("Escape - go to menu", 0, bottom_text_line_y + self.font:getHeight(), w, "center")
end

-- draw active signal quad
function nback:draw_active_signal(x0, y0)
    local x, y = unpack(self.pos_signals[self.current_sig])
    local sig_color = color_constants[self.color_signals[self.current_sig]]
    if self.figure_alpha then
        sig_color[4] = self.figure_alpha
    end
    local type = self.form_signals[self.current_sig]
    self.signal:draw(self.x0, self.y0, type, sig_color)
    --draw_signal_form(x0, y0, nback.form_signals[nback.current_sig], x, y, sig_color)
end

function nback:draw_bhupur(x0, y0)
    local delta = 5
    bhupur.color = self.field_color
    bhupur.draw(self.x0 - delta, self.y0 - delta, self.bhupur_h + delta * 2)
end

-- рисовать статистику после конца сета
function nback:draw_statistic(x0, y0)
    g.setFont(self.font)
    g.setColor(pallete.statistic)

    local width_k = 3 / 4
    local rect_size = w * width_k / #self.pos_signals -- XXX depend on screen resolution
    local x = (w - w * width_k) / 2
    local starty = 200
    local y = starty
    local border = 2

    y = y + g.getFont():getHeight() * 1.5

    local freeze_y = y
    x, y = self:draw_hit_rects(x, y, self.sound_pressed_arr, self.sound_eq, rect_size, border)
    x, y = self:draw_hit_rects(x, y, self.color_pressed_arr, self.color_eq, rect_size, border)
    x, y = self:draw_hit_rects(x, y, self.form_pressed_arr, self.form_eq, rect_size, border)
    x, y = self:draw_hit_rects(x, y, self.pos_pressed_arr, self.pos_eq, rect_size, border)

    -- drawing left column with letters
    g.setColor({200 / 255, 0, 200 / 255})
    g.setFont(self.font)

    local y = freeze_y
    local pixel_gap = 10
    x, y = self:print_signal_type(x, y, rect_size, "S", pixel_gap, delta) 
    x, y = self:print_signal_type(x, y, rect_size, "C", pixel_gap, delta) 
    x, y = self:print_signal_type(x, y, rect_size, "F", pixel_gap, delta) 
    x, y = self:print_signal_type(x, y, rect_size, "P", pixel_gap, delta)
    x, y = self:print_percents(x, freeze_y + 0, rect_size, pixel_gap, border, starty)
end

-- draw central_text - Press Space key
function nback:print_start_pause(y0)
    local central_text = string.format("Wait for %d second.", self.start_pause_rest)
    g.setFont(self.central_font)
    g.setColor(pallete.signal)
    local x = (w - self.central_font:getWidth(central_text)) / 2
    --y = h - self.central_font:getHeight() * 2
    local y = self.y0 + (self.dim - 1) * self.cell_width
    g.print(central_text, x, y)
end

function nback:draw()
    love.graphics.clear(pallete.background)

    --self.signal:setCorner(x0, y0)

    g.push("all")
    g.setShader(self.shader)

    -- этим вызовом рисуются только полосы сетки
    self:draw_field_grid(x0, y0, self.dim * self.cell_width)
    self:draw_bhupur(x0, y0)
    self:print_debug_info()
    if self.is_run then
        if self.start_pause then
            self:print_start_pause(y0)
        else
            self:draw_active_signal(x0, y0)
        end
    else
        if self.show_statistic then 
            self:draw_statistic(x0, y0)
            self:print_set_results(x0, y0)
        else
            self:draw_level_welcome()
        end
        self:print_press_space_to_new_round(y0)
    end

    local bottom_text_line_y = h - self.font:getHeight() * 3

    self:print_control_tips(bottom_text_line_y)
    self:print_escape_tip(bottom_text_line_y)

    g.setShader()
    g.pop()
end

return {
    new = nback.new
}
