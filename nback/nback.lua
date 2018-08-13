local inspect = require "libs.inspect"
local lume = require "libs.lume"
local math = require "math"
local os = require "os"
local string = require "string"
local table = require "table"
local class = require "libs.30log"

local pallete = require "pallete"

local g = love.graphics
local w, h = g.getDimensions()

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
    self.default_color = color or {255, 255, 255, 255}
    self.maxlen = 0
end

function check_color_t(t)
    if t[1] and t[2] and t[3] and t[4] and 
        t[1] >= 0 and t[1] <= 255 and
        t[2] >= 0 and t[2] <= 255 and
        t[3] >= 0 and t[3] <= 255 and
        t[4] >= 0 and t[4] <= 255 then 
            return true
    elseif t[1] and t[2] and t[3] and 
        t[1] >= 0 and t[1] <= 255 and
        t[2] >= 0 and t[2] <= 255 and
        t[3] >= 0 and t[3] <= 255 then 
            return true
    else
            return false
    end
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
            error(string.format("Incorrect type %s in self.data"))
        end
    end
    g.setFont(f)
    g.setColor(c)
end

local nback = {
    dim = 5,
    cell_width = 100,  -- width of game field in pixels
    current_sig = 1,
    sig_count = 6,                                  -- number of signals.
    level = 2,
    is_run = false,
    pause_time = 1.5, -- delay beetween signals, in seconds
    can_press = false,
    save_name = "nback-v0.1.lua",
    statistic = {                                   -- statistic which saving to file
        pos_hits = 0,
        color_hits = 0,
        sound_hits = 0,
        form_hits = 0,
        success = 0,
    },
    show_statistic = false,
    sounds = {},
    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 13),
    central_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 42),
    statistic_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
}

function nback.start()
    nback.pause = false
    nback.is_run = true

    print("start")
    nback.pos_signals = generate_nback(nback.sig_count, 
        function()
            return {math.random(1, nback.dim - 1), math.random(1, nback.dim - 1)}
        end,
        function(a, b)
            return  a[1] == b[1] and a[2] == b[2]
        end)
    print("pos", inspect(nback.pos_signals))
    nback.form_signals = generate_nback(nback.sig_count,
        function()
            local arr = {"trup", "trdown", "trupdown", "quad", "circle", "rhombus"}
            return arr[math.random(1, 6)]
        end,
        function(a, b)
            return a == b
        end)
    print("form", inspect(nback.form_signals))
    nback.sound_signals = generate_nback(nback.sig_count, 
        function()
            return math.random(1, #nback.sounds)
        end,
        function(a, b)
            return a == b
        end)
    print("snd", inspect(nback.sound_signals))
    nback.color_signals = generate_nback(nback.sig_count,
        function()
            local arr = {}
            for k, _ in pairs(color_constants) do
                arr[#arr + 1] = k
            end
            local addr = arr[math.random(1, 6)]
            print("addr", addr)
            return addr
        end,
        function(a, b)
            print(string.format("color comparator a = %s, b = %s", a, inspect(b)))
            return a == b
        end)
    print("color", inspect(nback.color_signals))

    nback.current_sig = 1
    nback.timestamp = love.timer.getTime()
    nback.statistic.pos_hits  = 0
    nback.show_statistic = false

    function create_array(len)
        local ret = {}
        for i = 1, len do
            ret[#ret + 1] = false
        end
        return ret
    end

    -- массивы хранящие булевские значения - нажат сигнал вот время обработки или нет?
    nback.pos_pressed_arr = create_array(#nback.pos_signals)
    nback.color_pressed_arr = create_array(#nback.color_signals)
    nback.form_pressed_arr = create_array(#nback.form_signals)
    nback.sound_pressed_arr = create_array(#nback.sound_signals)

    debug_print_init()
end

function nback.enter()
end

function nback.leave()
    nback.show_statistic = false
end

function generate_nback(sig_count, gen, cmp)
    local ret = {}
    local ratio = 4
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
    end
    love.audio.setVolume(nback.volume)
end

function nback.update()
    if nback.pause then 
         nback.timestamp = love.timer.getTime()
        -- подумай, нужен ли здесь код строчкой выше. Могут ли возникнуть проблемы с таймером отсчета
        -- если продолжительноть паузы больше nback.pause_time?
        return 
    end

    if nback.is_run then
        local time = love.timer.getTime()
        if (time - nback.timestamp >= nback.pause_time) then
            nback.timestamp = love.timer.getTime()

            if (nback.current_sig <= #nback.pos_signals) then
                nback.current_sig = nback.current_sig + 1
                nback.can_press = true
            end
            
            nback.sounds[nback.sound_signals[nback.current_sig]]:play()

            nback.pos_pressed = false
            nback.sound_pressed = false
            nback.form_pressed = false
            nback.color_pressed = false
        end

        if nback.current_sig == #nback.pos_signals then
            nback.stop()
        end
    end
end

function nback.stop()
    nback.is_run = false
    nback.show_statistic = true

    if nback.pos_signals and nback.current_sig == #nback.pos_signals then
        local data, size = love.filesystem.read(nback.save_name)
        local history = {}
        if data ~= nil then
            history = lume.deserialize(data)
        end
        --print("history", inspect(history))
        table.insert(history, { date = os.date("*t"), 
                                stat = nback.statistic,
                                nlevel = nback.level})
        love.filesystem.write(nback.save_name, lume.serialize(history))
    end
end

function nback.quit()
    local settings_str = lume.serialize { 
        ["volume"] = love.audio.getVolume(), 
        ["level"] = nback.level, 
        ["pause_time"] = nback.pause_time }
    ok, msg = love.filesystem.write("settings.lua", settings_str, settings_str:len())
    nback.stop()
    states.pop()
end

function nback.keyrelease(key)
    --[[
       [if key == "p" then
       [    nback.pos_pressed = false
       [elseif key == "s" then
       [    nback.sound_pressed = false
       [elseif key == "f" then
       [    nback.form_pressed = false
       [elseif key = "c" then
       [    nback.color_pressed = false
       [end
       ]]
end

-- key or scancode?
function nback.keypressed(key)
    if key == "escape" then
        if nback.is_run then
            nback.stop()
        else
            nback.quit()
        end
    elseif key == "space" or key == "return" and not (love.keyboard.isDown("ralt", "lalt")) then
        if not nback.is_run then 
            nback.start()
        end
    elseif key == "0" then
        nback.pause = not nback.pause
    elseif key == "9" then
        nback.show_statistic = not nback.show_statistic
        if nback.show_statistic then
            nback.pause = true
        end
    elseif key == "p" then
        nback.check_position()
    elseif key == "s" then
        nback.check_sound()
    elseif key == "f" then
        nback.check_form()
    elseif key == "c" then
        nback.check_color()
    end

    local minimum_nb_level = 2
    local maximum_nb_level = 4

    if not nback.is_run and not nback.show_statistic then
        if key == "left" and nback.level > minimum_nb_level then
            nback.level = nback.level - 1
        elseif key == "right" and nback.level < maximum_nb_level then
            nback.level = nback.level + 1
        end
        if key == "up" and nback.pause_time < 3 then
            nback.pause_time = nback.pause_time + 0.2
        elseif key == "down" and nback.pause_time > 0.6 then
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
end

function nback.check_position()

    function tuple_cmp(a, b)
        return a[1] == b[1] and a[2] == b[2]
    end

    if not nback.is_run then return end

    nback.pos_pressed = true
    nback.pos_pressed_arr[nback.current_sig] = true
    if nback.current_sig - nback.level > 1 then
        if tuple_cmp(nback.pos_signals[nback.current_sig], 
                     nback.pos_signals[nback.current_sig - nback.level]) then
            --print(inspect(nback))
            if nback.can_press then
                print("hit!")
                print(nback.statistic.pos_hits)
                nback.statistic.pos_hits  = nback.statistic.pos_hits  + 1
                nback.can_press = false
            end
        end
    end
end

function nback.check_sound()
    if not nback.is_run then return end

    nback.sound_pressed = true
    nback.sound_pressed_arr[nback.current_sig] = true
    if nback.current_sig - nback.level > 1 then
        if nback.sound_signals[nback.current_sig] == nback.sound_signals[nback.current_sig - nback.level] then
            if nback.can_press then
                print("sound hit!")
                print(nback.statistic.sound_hits)
                nback.statistic.sound_hits  = nback.statistic.sound_hits  + 1
                nback.can_press = false
            end
        end
    end
end

function nback.check_color()
    if not nback.is_run then return end

    nback.color_pressed = true
    nback.color_pressed_arr[nback.current_sig] = true
    if nback.current_sig - nback.level > 1 then
        if nback.color_signals[nback.current_sig] == nback.color_signals[nback.current_sig - nback.level] then
            if nback.can_press then
                print("color hit!")
                print(nback.statistic.color_hits)
                nback.statistic.color_hits = nback.statistic.color_hits + 1
                nback.can_press = false
            end
        end
    end
end

function nback.check_form()
    if not nback.is_run then return end

    nback.form_pressed = true
    nback.form_pressed_arr[nback.current_sig] = true
    if nback.current_sig - nback.level > 1 then
        if nback.form_signals[nback.current_sig] == nback.form_signals[nback.current_sig - nback.level] then
            --print(inspect(nback))
            if nback.can_press then
                print("hit!")
                --print(nback.statistic.pos_hits )
                nback.statistic.form_hits  = nback.statistic.form_hits  + 1
                nback.can_press = false
            end
        end
    end
end

function nback.resize(neww, newh)
    w = neww
    h = newh
    local pixels_border = 130
    nback.cell_width = (newh - pixels_border) / nback.dim
end

local debug_print_y = 0

function debug_print_init()
    nback.debug_pos_colors = {}
    nback.debug_form_colors = {}
    nback.debug_color_colors = {}
    nback.debug_sound_colors = {}

    for i = 1, nback.sig_count do
        nback.debug_pos_colors[#nback.debug_pos_colors + 1] = pallete.inactive -- default color
        nback.debug_form_colors[#nback.debug_form_colors + 1] = pallete.inactive -- default color
        nback.debug_color_colors[#nback.debug_color_colors + 1] = pallete.inactive -- default color
        nback.debug_sound_colors[#nback.debug_sound_colors + 1] = pallete.inactive -- default color
    end
    print("debug_pos_colors", inspect(nback.debug_pos_colors))
    print("#debug_pos_colors", #nback.debug_pos_colors)

    local comparator = function(a, b)
        return a[1] == b[1] and a[2] == b[2]
    end

    for k, v in pairs(nback.pos_signals) do
        if k + nback.level < #nback.pos_signals then
            if comparator(v, nback.pos_signals[k + nback.level]) then
                local color = {255, 0, 0}
                --color[1] = color[1] + math.random(1, 255)
                --color[1] = lume.clamp(100 + math.random(1, 255), 1, 255)

                nback.debug_pos_colors[k + nback.level] = color
                nback.debug_pos_colors[k] = color
                print("-----------")
                print(inspect(nback.debug_pos_colors[k + nback.level]))
                print(inspect(nback.debug_pos_colors[k]))
                print("color", inspect(color))
                --print("same signals in debug_print_init()")
            end
        end
    end

    print("debug_pos_colors", inspect(nback.debug_pos_colors))
end

function debug_print_signals()
    local oldcolor = {g.getColor()}
    local ww, hh = 16, 16
    local gap = 2
    local x = 5
    for k, v in pairs(nback.debug_pos_colors) do
        g.setColor(v)
        g.rectangle("fill", x, debug_print_y, ww, hh)
        --g.print(tostring(k), x, debug_print_y)
        x = x + ww + gap
    end
    debug_print_y = debug_print_y + hh
    --[[
       [draw(nback.debug_color_colors)
       [draw(nback.debug_form_colors)
       [draw(nback.debug_sound_colors)
       ]]

    g.setColor(oldcolor)
end

function debug_print_text(text)
    local color = {g.getColor()}
    g.setColor(255, 255, 0)
    g.print(text, 5, debug_print_y)
    local font = g.getFont()
    if font then
        debug_print_y = debug_print_y + font:getHeight()
    end
    g.setColor(unpack(color))
end

function nback.draw()
    local x0 = (w - nback.dim * nback.cell_width) / 2
    local y0 = (h - nback.dim * nback.cell_width) / 2
    local field_h = nback.dim * nback.cell_width
    --local bottom_text_line_y = y0 + field_h + nback.font:getHeight()
    local bottom_text_line_y = h - nback.font:getHeight() * 3
    local side_column_w = (w - field_h) / 2

    -- рисовать статистику после конца сета
    function draw_statistic()
            g.setFont(nback.font)
            g.setColor(pallete.statistic)

            y = y0 + nback.font:getHeight()
            g.printf(string.format("Set results:"), 0, y, w, "center")
            y = y + nback.font:getHeight()
            g.printf(string.format("level %d", nback.level), 0, y, w, "center")
            y = y + nback.font:getHeight()
            g.printf(string.format("delay time %.1f sec", nback.pause_time), 0, y, w, "center")

            local width_k = 3 / 4
            local rect_size = w * width_k / #nback.pos_signals -- XXX depend on screen resolution
            local x = (w - w * width_k) / 2
            local starty = 200
            local y = starty
            local hit_color = {200 / 255, 10 / 255, 10 / 255}
            local border = 2
            --print("x", x)
            --print("screenW = ", w)
            --print("rect_size, nback.sig_count", rect_size, nback.sig_count)

            -- return array of boolean values in succesful indices
            function make_hit_arr(signals, comparator)
                local ret = {}
                for k, v in pairs(signals) do
                    ret[#ret + 1] = k > nback.level and comparator(v, signals[k - nback.level])
                end
                return ret
            end

            function draw_hit_rects(arr, eq)
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
            end

            -- drawing horizontal string with signal numbers
            g.setColor({0.5, 0.5, 0.5})
            g.setFont(nback.statistic_font)
            for k, v in pairs(nback.pos_pressed_arr) do
                local delta = (rect_size - g.getFont():getWidth(tostring(k))) / 2
                g.print(tostring(k), x + rect_size * (k - 1) + delta, y)
            end
            y = y + g.getFont():getHeight() * 1.5
            ----------------------------------------
            local freeze_y = y

            local pos_eq = make_hit_arr(nback.pos_signals, function(a, b) return a[1] == b[1] and a[2] == b[2] end)
            local sound_eq = make_hit_arr(nback.sound_signals, function(a, b) return a == b end)
            local color_eq = make_hit_arr(nback.color_signals, function(a, b) return a == b end)
            local form_eq = make_hit_arr(nback.form_signals, function(a, b) return a == b end)

            draw_hit_rects(nback.sound_pressed_arr, sound_eq)
            draw_hit_rects(nback.color_pressed_arr, color_eq)
            draw_hit_rects(nback.form_pressed_arr, form_eq)
            local sx = draw_hit_rects(nback.pos_pressed_arr, pos_eq)

            -- drawing left column with letters
            g.setColor({200 / 255, 0, 200 / 255})
            g.setFont(nback.font)
            local y = freeze_y
            local delta = (rect_size - g.getFont():getHeight()) / 2
            local gap = 10

            function print_signal_type(str)
                g.print(str, x - g.getFont():getWidth(str) - gap, y + delta)
                y = y + rect_size + 6
            end

            print_signal_type("S") 
            print_signal_type("C") 
            print_signal_type("F") 
            print_signal_type("P")
            ----------------------

            function calc_percent(eq, pressed_arr)
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

            local y = freeze_y
            local sx = x + rect_size * (#nback.pos_signals - 1) + border + rect_size - border * 2 + gap
            g.setColor({200 / 255, 0, 200 / 255})
            g.setFont(nback.font)

            local sound_percent = calc_percent(sound_eq, nback.sound_pressed_arr)
            g.print(string.format("%.3f", sound_percent), sx, y + delta)
            y = y + rect_size + 6
            local color_percent = calc_percent(color_eq, nback.color_pressed_arr)
            g.print(string.format("%.3f", color_percent), sx, y + delta)
            y = y + rect_size + 6
            local form_percent = calc_percent(form_eq, nback.form_pressed_arr)
            g.print(string.format("%.3f", form_percent), sx, y + delta)
            y = y + rect_size + 6
            local pos_percent = calc_percent(pos_eq, nback.pos_pressed_arr)
            g.print(string.format("%.3f", pos_percent), sx, y + delta)

            local percent = (sound_percent + color_percent + form_percent + pos_percent) / 4
            y = starty + 4 * (rect_size + 20)
            g.printf(string.format("rating %0.3f", percent), 0, y, w, "center")
    end

    g.push("all")

    --draw background
    g.setBackgroundColor(pallete.background)
    g.clear()
    --

    --draw game field grid
    local field_color = pallete.field
    -- set up game field alpha color
    if nback.show_statistic then
        -- FIXME Not work properly!
        -- effect on next drawing in draw_statistic()
        --field_color[4] = 0.2
    end
    g.setColor(field_color)
    for i = 0, nback.dim do
        -- horizontal
        g.line(x0, y0 + i * nback.cell_width, x0 + field_h, y0 + i * nback.cell_width)
        -- vertical
        g.line(x0 + i * nback.cell_width, y0, x0 + i * nback.cell_width, y0 + field_h)
    end
    --

    function draw_signal_form(formtype, x, y, w, h)
        if formtype == "quad" then
            g.rectangle("fill", x, y, w, h)
        elseif formtype == "circle" then
            g.circle("fill", x + w / 2, y + h / 2, w / 2)
        elseif formtype == "trup" then
            --g.polygon("fill", {x, y + h * (2 / 3), x + w / 2, y, x + w, y + h * (2 / 3)})
            g.polygon("fill", {x, y + h * (2.2 / 3), x + w / 2, y, x + w, y + h * (2.2 / 3)})
        elseif formtype == "trdown" then
            g.polygon("fill", {x, y + h / 3, x + w / 2, y + h, x + w, y + h / 3})
        elseif formtype == "trupdown" then
            g.polygon("fill", {x, y + h * (2 / 3), x + w / 2, y, x + w, y + h * (2 / 3)})
            g.polygon("fill", {x, y + h / 3, x + w / 2, y + h, x + w, y + h / 3})
        elseif formtype == "rhombus" then
            g.polygon("fill", {x, y + h / 2, x + w / 2, y + h,  x + w, y + h / 2, x + w / 2, y})
        end
    end

    debug_print_y = 0
    debug_print_text("pos " .. inspect(nback.pos_signals))
    debug_print_text("sound " .. inspect(nback.sound_signals))
    debug_print_text("form " .. inspect(nback.form_signals))
    debug_print_text("color " .. inspect(nback.color_signals))
    debug_print_text("current_sig = " .. nback.current_sig)
    debug_print_text("nback.can_press = " .. tostring(nback.can_press))

    if nback.is_run then
        -- draw active signal quad
        --g.setColor(pallete.signal)
        g.setColor(color_constants[nback.color_signals[nback.current_sig]])
        local x, y = unpack(nback.pos_signals[nback.current_sig])
        local border = 5
        --g.rectangle("fill", x0 + x * nback.cell_width + border, 
            --y0 + y * nback.cell_width + border,
            --nback.cell_width - border * 2, nback.cell_width - border * 2)
        draw_signal_form(nback.form_signals[nback.current_sig], x0 + x * nback.cell_width + border, y0 + y * nback.cell_width + border,
            nback.cell_width - border * 2, nback.cell_width - border * 2)
        --

        --draw upper text - progress of evaluated signals
        g.setFont(nback.font)
        g.setColor(pallete.signal)
        text = string.format("%d / %d", nback.current_sig, #nback.pos_signals)
        x = (w - nback.font:getWidth(text)) / 2
        y = y0 - nback.font:getHeight()
        g.print(text, x, y)
        --
    else

        --draw statistic or level setup invitation
        if nback.show_statistic then 
            draw_statistic()
        else
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
        local central_text = "Press Space to new round"
        g.setFont(nback.central_font)
        g.setColor(pallete.signal)
        x = (w - nback.central_font:getWidth(central_text)) / 2
        --y = h - nback.central_font:getHeight() * 2
        y = y0 + (nback.dim - 1) * nback.cell_width
        g.print(central_text, x, y)
        --
    end

    -- draw bottom line hotkeys tips texts
    g.setFont(nback.font)
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
    --

    -- draw escape tip
    g.setFont(nback.font)
    g.setColor(pallete.tip_text)
    g.printf("Escape - go to menu", 0, bottom_text_line_y + nback.font:getHeight(), w, "center")
    --
    
    g.pop()
end

return nback
