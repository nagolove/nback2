local inspect = require "libs.inspect"
local lume = require "libs.lume"
local math = require "math"
local os = require "os"
local string = require "string"
local table = require "table"
local class = require "libs.30log"
local Timer = require "libs.Timer"
local Kons = require "kons"
local pallete = require "pallete"
local bhupur = require "bhupur"

local g = love.graphics
local w, h = g.getDimensions()
local linesbuf = Kons(0, 0)

local color_constants = {
        ["brown"] = {136 / 255, 55 / 255, 41 / 255},
        ["green"] = {72 / 255, 180 / 255, 66 / 255},
        ["blue"] = {27 / 255, 30 / 255, 249 / 255},
        ["red"] = {241 / 255, 30 / 255, 27 / 255},
        ["yellow"] = {231 / 255, 227 / 255, 11 / 255},
        ["purple"] = {128 / 255, 7 / 255, 128 / 255},
}

local AlignedLabels = class("AlignedLabels")

function AlignedLabels:init(font, screenwidth, color)
    self:clear(font, screenwidth, color)
end

function AlignedLabels:clear(font, screenwidth, color)
    self.screenwidth = screenwidth or self.screenwidth
    self.font = font or self.font
    self.data = {}
    self.colors = {}
    self.default_color = color or {1, 1, 1, 1}
    self.maxlen = 0
end

-- ... - list of pairs of color and text
-- AlignedLabels:add("helllo", {200, 100, 10}, "wwww", {0, 0, 100})
-- плохо, что функция не проверяет параметры на количество и тип
function AlignedLabels:add(...)
    --assert(type(text) == "string")
    local args = {...}
    local nargs = select("#", ...)
    --print("AlignedLabels:add() args = " .. inspect(args))
    if nargs > 2 then
        local colored_text_data = {}
        local colors = {}
        local text_len = 0
        for i = 1, nargs, 2 do
            local text = select(i, ...)
            local color = select(i + 1, ...)
            text_len = text_len + text:len()
            colored_text_data[#colored_text_data + 1] = text
            colors[#colors + 1] = color
        end
        self.data[#self.data + 1] = colored_text_data
        --assert(check_color_t(select(i + 1, ...)))
        self.colors[#self.colors + 1] = colors
        if text_len > self.maxlen then
            self.maxlen = text_len
        end
    else
        self.data[#self.data + 1] = select(1, ...)
        self.colors[#self.colors + 1] = select(2, ...) or self.default_color
    end
end

function AlignedLabels:draw(x, y)
    local dw = self.screenwidth / (#self.data + 1)
    local i = x + dw
    local f = g.getFont()
    local c = {g.getColor()}
    g.setFont(self.font)
    for k, v in pairs(self.data) do
        if type(v) == "string" then
            g.setColor(self.colors[k])
            g.print(v, i - self.font:getWidth(v) / 2, y)
            i = i + dw
        elseif type(v) == "table" then
            local width = 0
            for _, g in pairs(v) do
                width = width + self.font:getWidth(g)
            end
            assert(#v == #self.colors[k])
            local xpos = i - width / 2
            for j, p in pairs(v) do
                --print(type(self.colors[k]), inspect(self.colors[k]), k, j)
                g.setColor(self.colors[k][j])
                g.print(p, xpos, y)
                xpos = xpos + self.font:getWidth(p)
            end
            i = i + dw
        else
            error(string.format("AlignedLabels:draw() : Incorrect type %s in self.data", self.data))
        end
    end
    g.setFont(f)
    g.setColor(c)
end

local minimum_nb_level = 1
local maximum_nb_level = 5
local max_pause_time = 15
local min_pause_time = 0.6

local nback = {
    dim = 5,    -- количество ячеек поля
    cell_width = 100,  -- width of game field in pixels
    current_sig = 1, -- номер текущего сигнала, при начале партии равен 1
    sig_count = 6, -- количество сигналов
    level = 2, -- уровень, на сколько позиций назад нужно нажимать клавишу сигнала
    is_run = false, -- индикатор запуска рабочего цикла
    pause_time = 2.5, -- задержка между сигналами, в секундах
    can_press = false, -- XXX FIXME зачем нужна эта переменная?
    save_name = "nback-v0.2.lua", -- имя файла с логом пройденных тренировок
    statistic = { -- блок статистики, записываемый в файл save_name
        pos_hits = 0,
        color_hits = 0,
        sound_hits = 0,
        form_hits = 0,
        success = 0,
    },
    show_statistic = false, -- индикатор показа статистики в конце сета
    sounds = {},
    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 25),
    central_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 42),
    statistic_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
    field_color = table.copy(pallete.field) -- копия таблицы по значению
}

function create_false_array(len)
    local ret = {}
    for i = 1, len do
        ret[#ret + 1] = false
    end
    return ret
end

function generate_signals()
    local color_arr = {}
    for k, _ in pairs(color_constants) do
        color_arr[#color_arr + 1] = k
    end

    function genArrays()
        nback.pos_signals = generate_nback(nback.sig_count, 
            function() return {math.random(1, nback.dim - 1), math.random(1, nback.dim - 1)} end,
            function(a, b) return  a[1] == b[1] and a[2] == b[2] end)
        print("pos", inspect(nback.pos_signals))
        nback.form_signals = generate_nback(nback.sig_count,
            function()
                local arr = {"trup", "trdown", "trupdown", "quad", "circle", "rhombus"}
                return arr[math.random(1, 6)]
            end,
            function(a, b) return a == b end)
        print("form", inspect(nback.form_signals))
        nback.sound_signals = generate_nback(nback.sig_count, 
            function() return math.random(1, #nback.sounds) end,
            function(a, b) return a == b end)
        print("snd", inspect(nback.sound_signals))
        nback.color_signals = generate_nback(nback.sig_count,
            function() return color_arr[math.random(1, 6)] end,
            function(a, b)
                print(string.format("color comparator a = %s, b = %s", a, inspect(b)))
                return a == b end)
        print("color", inspect(nback.color_signals))

        nback.pos_eq = make_hit_arr(nback.pos_signals, function(a, b) return a[1] == b[1] and a[2] == b[2] end)
        nback.sound_eq = make_hit_arr(nback.sound_signals, function(a, b) return a == b end)
        nback.color_eq = make_hit_arr(nback.color_signals, function(a, b) return a == b end)
        nback.form_eq = make_hit_arr(nback.form_signals, function(a, b) return a == b end)
    end

    -- попытка балансировки массивов от множественного совпадения(более двух сигналов на фрейм)
    -- случайной перегенерацией
    function balance(forIterCount)
        local i = 0
        local changed = false
        repeat
            i = i + 1
            genArrays()
            for k, v in pairs(nback.pos_eq) do
                local n = 0
                n = n + (v and 1 or 0)
                n = n + (nback.sound_eq[k] and 1 or 0)
                n = n + (nback.form_eq[k] and 1 or 0)
                n = n + (nback.color_eq[k] and 1 or 0)
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

function nback.start()
    local q = pallete.field
    -- запуск анимации цвета игрового поля
    nback.timer:tween(3, nback, { field_color = {q[1], q[2], q[3], 1}}, "linear")

    print("start")

    nback.pause = false
    nback.is_run = true

    generate_signals()

    nback.current_sig = 1
    nback.timestamp = love.timer.getTime() - nback.pause_time
    nback.statistic.pos_hits  = 0
    nback.show_statistic = false

    -- массивы хранящие булевские значения - нажат сигнал вот время обработки или нет?
    nback.pos_pressed_arr = create_false_array(#nback.pos_signals)
    nback.color_pressed_arr = create_false_array(#nback.color_signals)
    nback.form_pressed_arr = create_false_array(#nback.form_signals)
    nback.sound_pressed_arr = create_false_array(#nback.sound_signals)
    print(inspect(nback.pos_pressed_arr))
    print(inspect(nback.color_pressed_arr))
    print(inspect(nback.form_pressed_arr))
    print(inspect(nback.sound_pressed_arr))

    nback.start_pause_rest = 4
    nback.start_pause = true
    nback.timer:every(1, function() 
        nback.start_pause_rest = nback.start_pause_rest - 1 
    end, 4, function()
        nback.start_pause = false
    end)
    print("end of start")
end

function nback.enter()
    -- установка альфа канала цвета сетки игрового поля
    nback.field_color[4] = 0.2
end

function nback.leave()
    nback.show_statistic = false
end

function generate_nback(sig_count, gen, cmp)
    local ret = {}
    local ratio = 8 --TODO FIXME XXX
    local range = {1, 3}
    local count = sig_count
    local null = {}

    for i = 1, ratio * sig_count do
        table.insert(ret, null)
    end

    repeat
        local i = 1
        repeat
            if count > 0 then
                local prob = math.random(unpack(range))
                if prob == range[2] then
                    if i + nback.level <= #ret and ret[i] == null and ret[i + nback.level] == null then
                        ret[i] = gen()
                        if type(ret[i]) == "table" then
                            ret[i + nback.level] = lume.clone(ret[i])
                        else
                            ret[i + nback.level] = ret[i]
                        end
                        count = count - 1
                    end
                end
            end
            i = i + 1
        until i > #ret
    until count == 0

    -- замена пустых мест в массиве случайно сгенерированным сигналом так, что-бы 
    -- он не совпадал на текущем уровне n-назад
    for i = 1, #ret do
        if ret[i] == null then
            repeat
                ret[i] = gen()
            until not (i + nback.level <= #ret and cmp(ret[i], ret[i + nback.level]))
        end
    end

    return ret
end

function nback.init()
    nback.timer = Timer()
    math.randomseed(os.time())

    wave_path = "sfx/alphabet"
    for k, v in pairs(love.filesystem.getDirectoryItems(wave_path)) do
        table.insert(nback.sounds, love.audio.newSource(wave_path .. "/" .. v, "static"))
    end

    nback.resize(g.getDimensions())
    
    local data, _ = love.filesystem.read("settings.lua")
    if data then
        local settings = lume.deserialize(data, "all")
        print("settings loaded", inspect(settings))
        nback.level = settings.level
        nback.pause_time = settings.level
        nback.volume = settings.volume
    else
        nback.volume = 0.2 -- XXX какое значение должно быть по-дефолту?
    end
    love.audio.setVolume(nback.volume)
end

function nback.update(dt)
    nback.timer:update(dt)
    if nback.pause or nback.start_pause then 
        nback.timestamp = love.timer.getTime() - nback.pause_time
        -- подумай, нужен ли здесь код строчкой выше. Могут ли возникнуть проблемы с таймером отсчета
        -- если продолжительноть паузы больше nback.pause_time?
        return 
    end

    if nback.is_run then
        if nback.current_sig < #nback.pos_signals then
            local time = love.timer.getTime()
            if (time - nback.timestamp >= nback.pause_time) then
                nback.timestamp = love.timer.getTime()

                nback.current_sig = nback.current_sig + 1
                nback.can_press = true

                -- setup timer for figure alpha channel animation
                nback.figure_alpha = 1
                local tween_time = 0.5
                print("time delta = " .. nback.pause_time - tween_time)
                nback.timer:after(nback.pause_time - tween_time - 0.1, function()
                    nback.timer:tween(tween_time, nback, {figure_alpha = 0}, "out-linear")
                end)

                local snd = nback.sounds[nback.sound_signals[nback.current_sig]]
                --print("snd", inspect(nback.sound_signals[nback.current_sig]), snd:getVolume(), snd:getDuration())
                snd:play()

                nback.pos_pressed = false
                nback.sound_pressed = false
                nback.form_pressed = false
                nback.color_pressed = false
            end
        else
            nback.stop()
        end
    end
end

function calc_percent(eq, pressed_arr)
    if not eq then return 0 end --XXX hack against crash

    local p = 0
    local success = 0
    for k, v in pairs(eq) do
        if v then
            success = success + 1
        end
        if v and pressed_arr[k] then
            p = p + 1
        end
    end
    return p / success
end

function nback.save_to_history()
    print("nback.current_sig = ", nback.current_sig)
    print("#nback.pos_signals = ", #nback.pos_signals)
    local data, size = love.filesystem.read(nback.save_name)
    local history = {}
    if data ~= nil then
        history = lume.deserialize(data)
    end
    --print("history", inspect(history))
    local d = os.date("*t")
    table.insert(history, { date = d, 
                            pos_signals = nback.pos_signals,
                            form_signals = nback.form_signals,
                            sound_signals = nback.sound_signals,
                            color_signals = nback.color_signals,
                            pos_pressed_arr = nback.pos_pressed_arr,
                            form_pressed_arr = nback.form_pressed_arr,
                            sound_pressed_arr = nback.sound_pressed_arr,
                            color_pressed_arr = nback.color_pressed_arr,
                            time = os.time(d), 
                            stat = nback.statistic,
                            nlevel = nback.level,
                            pause = nback.pause_time,
                            percent = nback.percent})
    love.filesystem.write(nback.save_name, lume.serialize(history))
end

function nback.stop()
    local q = pallete.field
    -- амимация альфа-канала игрового поля
    nback.timer:tween(2, nback.field_color, { q[1], q[2], q[3], 0.1 }, "linear")

    nback.is_run = false
    nback.show_statistic = true

    print("stop")
    print(inspect(nback.sound_pressed_arr))
    print(inspect(nback.color_pressed_arr))
    print(inspect(nback.form_pressed_arr))
    print(inspect(nback.pos_pressed_arr))

    nback.sound_percent = calc_percent(nback.sound_eq, nback.sound_pressed_arr)
    nback.color_percent = calc_percent(nback.color_eq, nback.color_pressed_arr)
    nback.form_percent = calc_percent(nback.form_eq, nback.form_pressed_arr)
    nback.pos_percent = calc_percent(nback.pos_eq, nback.pos_pressed_arr)
    nback.percent = (nback.sound_percent + nback.color_percent + nback.form_percent + nback.pos_percent) / 4
    -- Раунд полностью закончен? - записываю историю
    if nback.pos_signals and nback.current_sig == #nback.pos_signals then nback.save_to_history() end
end

function nback.quit()
    nback.timer:destroy()
    local settings_str = lume.serialize { 
        ["volume"] = love.audio.getVolume(), 
        ["level"] = nback.level, 
        ["pause_time"] = nback.pause_time }
    ok, msg = love.filesystem.write("settings.lua", settings_str, settings_str:len())
    nback.stop()
    states.pop()
end

-- key or scancode?
function nback.keypressed(key)
    if key == "escape" then
        if nback.is_run then
            nback.stop()
        else
            nback.quit()
        end
    elseif key == "space" or key == "return" then
            nback.start()

    --[[
       [elseif key == "0" then
       [    nback.pause = not nback.pause
       [elseif key == "9" then
       [    nback.show_statistic = not nback.show_statistic
       [    if nback.show_statistic then
       [       nback.pause = true
       [    end
       ]]

    elseif key == "p" then
        nback.check("pos")
    elseif key == "s" then
        nback.check("sound")
    elseif key == "f" then
        nback.check("form")
    elseif key == "c" then
        nback.check("color")
    end

    if not nback.is_run and not nback.show_statistic then
        if key == "left" and nback.level > minimum_nb_level then
            nback.level = nback.level - 1
        elseif key == "right" and nback.level < maximum_nb_level then
            nback.level = nback.level + 1
        end
        if key == "up" and nback.pause_time < max_pause_time then
            nback.pause_time = nback.pause_time + 0.2
        elseif key == "down" and nback.pause_time > min_pause_time then
            nback.pause_time = nback.pause_time - 0.2
        end
    end

    if key == "-" then 
        print("love.audio.getVolume() = ", love.audio.getVolume())
        love.audio.setVolume(love.audio.getVolume() - 0.05)
    elseif key == "=" then
        print("love.audio.getVolume() = ", love.audio.getVolume())
        love.audio.setVolume(love.audio.getVolume() + 0.05)
    end

    if key == "2" then linesbuf.show = not linesbuf.show end
end

-- signal type may be "pos", "sound", "color", "form"
function nback.check(signalType)
    if not nback.is_run then
        return
    end
    local signals = nback[signalType .. "_signals"]
    local cmp = function(a, b) return a == b end
    if signalType == "pos" then
        cmp = function(a, b)
            return a[1] == b[1] and a[2] == b[2]
        end
    end
    nback[signalType .. "_pressed"] = true
    -- ненадолго включаю подсветку введеной клавиши на игровом поле
    nback.timer:after(0.1, function() 
        nback[signalType .. "_pressed"] = false 
    end)
    nback[signalType .. "_pressed_arr"][nback.current_sig] = true
    if nback.current_sig - nback.level > 1 then
        if cmp(signals[nback.current_sig], signals[nback.current_sig - nback.level]) then
            --print(inspect(nback))
            if nback.can_press then
                print(signalType .. " hit!")
                print(nback.statistic[signalType .. "_hits"])
                nback.statistic[signalType .. "_hits"] = nback.statistic[signalType .. "_hits"]  + 1
                nback.can_press = false
            end
        end
    end
end

function nback.resize(neww, newh)
    print(string.format("nback resized to %d * %d", neww, newh))
    w = neww
    h = newh
    local pixels_border = 130 -- size of border around main game field
    nback.cell_width = (newh - pixels_border) / nback.dim
    nback.bhupur_h = nback.cell_width * nback.dim 
end

-- return array of boolean values in succesful indices
function make_hit_arr(signals, comparator)
    local ret = {}
    for k, v in pairs(signals) do
        ret[#ret + 1] = k > nback.level and comparator(v, signals[k - nback.level])
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

function draw_field_grid(x0, y0, field_h)
    g.setColor(nback.field_color)
    for i = 0, nback.dim do
        -- horizontal
        g.line(x0, y0 + i * nback.cell_width, x0 + field_h, y0 + i * nback.cell_width)
        -- vertical
        g.line(x0 + i * nback.cell_width, y0, x0 + i * nback.cell_width, y0 + field_h)
    end
end

function draw_hit_rects(x, y, arr, eq, rect_size, border)
    --print("border = " .. border)
    local hit_color = {200 / 255, 10 / 255, 10 / 255}
    for k, v in pairs(arr) do
        g.setColor(pallete.field)
        g.rectangle("line", x + rect_size * (k - 1), y, rect_size, rect_size)
        g.setColor(pallete.inactive)
        g.rectangle("fill", x + rect_size * (k - 1) + border, y + border, rect_size - border * 2, rect_size - border * 2)
        if v then
            g.setColor(hit_color)
            g.rectangle("fill", x + rect_size * (k - 1) + border, y + border, rect_size - border * 2, rect_size - border * 2)
        end
        -- draw circle in center of quad if it is successful
        if eq[k] then
            local radius = 4
            g.setColor({0, 0, 0})
            g.circle("fill", x + rect_size * (k - 1) + rect_size / 2, y + rect_size / 2, radius)
        end
    end
    y = y + rect_size + 6
    return x, y
end

local draw_iteration = 0 -- debug variable

-- drawing horizontal string with signal numbers
function draw_horizontal_string(x, y, rect_size)
    g.setColor({0.5, 0.5, 0.5})
    g.setFont(nback.statistic_font)
    for k, _ in pairs(nback.pos_pressed_arr) do
        local delta = (rect_size - g.getFont():getWidth(tostring(k))) / 2
        g.print(tostring(k), x + rect_size * (k - 1) + delta, y) -- п
    end
    return x, y
end

-- draw one big letter in left side of draw_hit_rects() output
function print_signal_type(x, y, rect_size, str, pixel_gap, delta)
    local delta = (rect_size - g.getFont():getHeight()) / 2
    g.print(str, x - g.getFont():getWidth(str) - pixel_gap, y + delta)
    y = y + rect_size + 6
    return x, y
end

function print_percents(x, y, rect_size, pixel_gap, border, starty)
    local sx = x + rect_size * (#nback.pos_signals - 1) + border + rect_size - border * 2 + pixel_gap
    g.setColor({200 / 255, 0, 200 / 255})
    g.setFont(nback.font)
    g.print(string.format("%.2f", nback.sound_percent), sx, y)
    y = y + rect_size + 6
    g.print(string.format("%.2f", nback.color_percent), sx, y)
    y = y + rect_size + 6
    g.print(string.format("%.2f", nback.form_percent), sx, y)
    y = y + rect_size + 6
    g.print(string.format("%.2f", nback.pos_percent), sx, y)
    y = starty + 4 * (rect_size + 20)
    g.printf(string.format("rating %0.2f", nback.percent), 0, y, w, "center")
    return x, y
end

function print_debug_info()
    linesbuf:push_text_i("fps " .. love.timer.getFPS())
    linesbuf:push_text_i("pos " .. inspect(nback.pos_signals))
    linesbuf:push_text_i("sound " .. inspect(nback.sound_signals))
    linesbuf:push_text_i("form " .. inspect(nback.form_signals))
    linesbuf:push_text_i("color " .. inspect(nback.color_signals))
    linesbuf:push_text_i("current_sig = " .. nback.current_sig)
    linesbuf:push_text_i("nback.can_press = " .. tostring(nback.can_press))
    linesbuf:draw()
end

function print_set_results(x0, y0)
        print(x0, y0)
        local y = y0 + nback.font:getHeight()
        g.printf(string.format("Set results:"), 0, y, w, "center")
        y = y + nback.font:getHeight()
        g.printf(string.format("level %d", nback.level), 0, y, w, "center")
        y = y + nback.font:getHeight()
        g.printf(string.format("Pause time %.1f sec", nback.pause_time), 0, y, w, "center")
end

function draw_level_welcome()
    g.setFont(nback.font)
    --FIXME Dissonance with color and variable name
    g.setColor(pallete.tip_text) 
    local y = (h - g.getFont():getHeight() * 4) / 2.5
    g.printf(string.format("nback level is %d", nback.level), 0, y, w, "center")
    y = y + nback.font:getHeight()
    g.printf("Use ←→ arrows to setup", 0, y, w, "center")
    y = y + nback.font:getHeight() * 2
    g.printf(string.format("delay time is %.1f sec", nback.pause_time), 0, y, w, "center")
    y = y + nback.font:getHeight()
    g.printf("Use ↑↓ arrows to setup", 0, y, w, "center")
end

-- draw central_text - Press Space key
function print_press_space_to_new_round(y0)
    local central_text = "Press Space to new round"
    g.setFont(nback.central_font)
    g.setColor(pallete.signal)
    local x = (w - nback.central_font:getWidth(central_text)) / 2
    --y = h - nback.central_font:getHeight() * 2
    local y = y0 + (nback.dim - 1) * nback.cell_width
    g.print(central_text, x, y)
end

function print_control_tips(bottom_text_line_y)
    local keys_tip = AlignedLabels:new(nback.font, w)
    local pressed_color = pallete.active
    local unpressed_color = pallete.inactive
    if nback.sound_pressed then
        keys_tip:add("Sound", pressed_color)
    else
        keys_tip:add("S", {200 / 255, 0, 200 / 255}, "ound", unpressed_color)
    end
    if nback.color_pressed then
        keys_tip:add("Color", pressed_color)
    else
        keys_tip:add("C", {200 / 255, 0, 200 / 255}, "olor", unpressed_color)
    end
    if nback.form_pressed then
        keys_tip:add("Form", pressed_color)
    else
        keys_tip:add("F", {200 / 255, 0, 200 / 255}, "orm", unpressed_color)
    end
    if nback.pos_pressed then
        keys_tip:add("Position", pressed_color)
    else
        keys_tip:add("P", {200 / 255, 0, 200 / 255}, "osition", unpressed_color)
    end
    keys_tip:draw(0, bottom_text_line_y)
end

-- draw escape tip
function print_escape_tip(bottom_text_line_y)
    g.setFont(nback.font)
    g.setColor(pallete.tip_text)
    g.printf("Escape - go to menu", 0, bottom_text_line_y + nback.font:getHeight(), w, "center")
end

-- draw active signal quad
function draw_active_signal(x0, y0)
    local x, y = unpack(nback.pos_signals[nback.current_sig])
    local sig_color = color_constants[nback.color_signals[nback.current_sig]]
    if nback.figure_alpha then
        sig_color[4] = nback.figure_alpha
    end
    draw_signal_form(x0, y0, nback.form_signals[nback.current_sig], x, y, sig_color)
end

function draw_bhupur(x0, y0)
    local delta = 5
    bhupur.color = nback.field_color
    bhupur.draw(x0 - delta, y0 - delta, nback.bhupur_h + delta * 2)
end

-- рисовать статистику после конца сета
function draw_statistic(x0, y0)
    g.setFont(nback.font)
    g.setColor(pallete.statistic)

    print("x0 = " .. x0 .. " y0 = " .. y0)

    local width_k = 3 / 4
    local rect_size = w * width_k / #nback.pos_signals -- XXX depend on screen resolution
    local x = (w - w * width_k) / 2
    local starty = 200
    local y = starty
    local border = 2
    --print("x", x)
    --print("screenW = ", w)
    --print("rect_size, nback.sig_count", rect_size, nback.sig_count)
    x, y = draw_horizontal_string(x, y, rect_size)

    y = y + g.getFont():getHeight() * 1.5
    ----------------------------------------
    local freeze_y = y

    x, y = draw_hit_rects(x, y, nback.sound_pressed_arr, nback.sound_eq, rect_size, border)
    x, y = draw_hit_rects(x, y, nback.color_pressed_arr, nback.color_eq, rect_size, border)
    x, y = draw_hit_rects(x, y, nback.form_pressed_arr, nback.form_eq, rect_size, border)
    x, y = draw_hit_rects(x, y, nback.pos_pressed_arr, nback.pos_eq, rect_size, border)

    -- drawing left column with letters
    g.setColor({200 / 255, 0, 200 / 255})
    g.setFont(nback.font)

    local y = freeze_y
    local pixel_gap = 10
    x, y = print_signal_type(x, y, rect_size, "S", pixel_gap, delta) 
    x, y = print_signal_type(x, y, rect_size, "C", pixel_gap, delta) 
    x, y = print_signal_type(x, y, rect_size, "F", pixel_gap, delta) 
    x, y = print_signal_type(x, y, rect_size, "P", pixel_gap, delta)
    x, y = print_percents(x, freeze_y + 0, rect_size, pixel_gap, border, starty)
end

-- draw central_text - Press Space key
function print_start_pause(y0)
    local central_text = string.format("Wait for %d second.", nback.start_pause_rest)
    g.setFont(nback.central_font)
    g.setColor(pallete.signal)
    local x = (w - nback.central_font:getWidth(central_text)) / 2
    --y = h - nback.central_font:getHeight() * 2
    local y = y0 + (nback.dim - 1) * nback.cell_width
    g.print(central_text, x, y)
end

function nback.draw()
    love.graphics.clear(pallete.background)

    local delta = 20 -- for avoiding intersection between field and bottom lines of text
    local x0 = (w - nback.dim * nback.cell_width) / 2
    local y0 = (h - nback.dim * nback.cell_width) / 2 - delta

    g.push("all")
    draw_field_grid(x0, y0, nback.dim * nback.cell_width)
    draw_bhupur(x0, y0)
    print_debug_info()
    if nback.is_run then
        if nback.start_pause then
            print_start_pause(y0)
        else
            draw_active_signal(x0, y0)
        end
    else
        if nback.show_statistic then 
            draw_statistic(x0, y0)
            print_set_results(x0, y0)
        else
            draw_level_welcome()
        end
        print_press_space_to_new_round(y0)
    end

    local bottom_text_line_y = h - nback.font:getHeight() * 3
    print_control_tips(bottom_text_line_y)
    print_escape_tip(bottom_text_line_y)
    g.pop()
end

return nback
