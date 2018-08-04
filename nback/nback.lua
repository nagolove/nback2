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

state_stack = {}

function state_stack:new()

    local self = {
        a = {}
    }

    function self:push(s)
        self.a[#self.a + 1] = s
    end

    function self.pop()
        self.a[#self.a] = nil
    end

    function self.top()
        return self.a[#self.a]
    end

    return self
end

local color_constants = {
        ["brown"] = {136, 55, 41},
        ["green"] = {72, 180, 66},
        ["blue"] = {27, 30, 249},
        ["red"] = {241, 30, 27},
        ["yellow"] = {231, 227, 11},
        ["purple"] = {128, 7, 128},
}

local nback = {
    dim = 5,
    cell_width = 100,                                -- width of game field in pixels
    current_sig = 1,
    sig_count = 6,                                  -- number of signals.
    level = 2,
    is_run = false,
    pause_time = 1.5,                               -- delay beetween signals, in seconds
    use_sound = true,
    can_press = false,
    save_name = "nback-v0.1.lua",
    statistic = {                                   -- statistic which saving to file
        pos_hits = 0,
        color_hits = 0,
        sound_hits = 0,
        form_hits = 0
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
    print("form", inspect(nback.form_signal))
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
    nback.use_sound_text = ""
    nback.statistic.pos_hits  = 0
    nback.show_statistic = false

    debug_print_init()
end

function nback.enter()
    --nback.change_sound();
end

function nback.change_sound()
    if nback.is_run then return end
    nback.use_sound = not nback.use_sound
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

function nback.load()
    math.randomseed(os.time())

    wave_path = "sfx/alphabet"
    for k, v in pairs(love.filesystem.getDirectoryItems(wave_path)) do
        table.insert(nback.sounds, love.audio.newSource(wave_path .. "/" .. v))
    end
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
            
            if nback.use_sound then
                nback.sounds[nback.sound_signals[nback.current_sig]]:play()
            end

            nback.pos_pressed = false
            nback.sound_pressed = false
            nback.form_pressed = false
            nback.color_pressed = false
        end

        if nback.current_sig == #nback.pos_signals then
            nback.show_statistic = true
            nback.stop()
        end
    end
end

function nback.stop()
    nback.is_run = false

    if nback.pos_signals and nback.current_sig == #nback.pos_signals then
        local data, size = love.filesystem.read(nback.save_name)
        local history = {}
        if data ~= nil then
            history = lume.deserialize(data)
        end
        --print("history", inspect(history))
        table.insert(history, { date = os.date("*t"), 
                                stat = nback.statistic,
                                nlevel = nback.level,
                                use_sound = nback.use_sound})
        love.filesystem.write(nback.save_name, lume.serialize(history))
    end
end

function nback.quit()
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

function nback.keypressed(key)
    if key == "escape" then
        nback.quit()
    elseif key == "space" or key == "return" and not (love.keyboard.isDown("ralt", "lalt")) then
        if not nback.is_run then 
            nback.start()
        else
            nback.stop()
            nback.enter()
        end
    --elseif key == "s" then
        --nback.change_sound()
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
    local maximum_nb_level = 8

    if not nback.is_run then
        if key == "left" and nback.level > minimum_nb_level then
            nback.level = nback.level - 1
        elseif key == "right" and nback.level < maximum_nb_level then
            nback.level = nback.level + 1
        end
    end
end

function nback.check_position()

    function tuple_cmp(a, b)
        return a[1] == b[1] and a[2] == b[2]
    end

    if not nback.is_run then return end
    nback.pos_pressed = true

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

    if nback.use_sound and nback.current_sig - nback.level > 1 then
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

local AlignedLabels = class("AlignedLabels")

function nback.draw()
    local x0 = (w - nback.dim * nback.cell_width) / 2
    local y0 = (h - nback.dim * nback.cell_width) / 2
    local field_h = nback.dim * nback.cell_width
    local bottom_text_line_y = y0 + field_h + nback.font:getHeight()
    local side_column_w = (w - field_h) / 2

    -- рисовать статистику после конца сета
    function draw_statistic()
            g.setFont(nback.statistic_font)
            g.setColor(pallete.statistic)

            y = y0 + nback.statistic_font:getHeight()
            g.printf(string.format("Set results:"), 0, y, w, "center")

            --local percent = nback.sig_count / nback.statistic.pos_hits * 100
            --y = y + nback.statistic_font:getHeight()
            --g.printf(string.format("rating %d%%", percent), 0, y, w, "center")
    end

    function draw_use_sound_text()
        local use_sound_text = "For enable sound - press S"

        g.setFont(nback.font)

        if nback.use_sound then
            g.setColor(pallete.tip_text_alt)
        else
            g.setColor(pallete.tip_text)
            use_sound_text = "For disable sound - press S"
        end

        --g.print(use_sound_text, (w - nback.font:getWidth(use_sound_text)) / 2, bottom_text_line_y)
    end

    g.push("all")

    --draw background
    g.setBackgroundColor(pallete.background)
    g.clear()
    --

    --draw game field grid
    g.setColor(pallete.field)
    for i = 0, nback.dim do
        g.line(x0, y0 + i * nback.cell_width, x0 + field_h, y0 + i * nback.cell_width)
        g.line(x0 + i * nback.cell_width, y0, x0 + i * nback.cell_width, y0 + field_h)
    end
    --

    function draw_signal_form(formtype, x, y, w, h)
        if formtype == "quad" then
            g.rectangle("fill", x, y, w, h)
        elseif formtype == "circle" then
            g.circle("fill", x + w / 2, y + h / 2, w / 2)
        elseif formtype == "trup" then
            g.polygon("fill", {x, y + h * (2 / 3), x + w / 2, y, x + w, y + h * (2 / 3)})
        elseif formtype == "trdown" then
            g.polygon("fill", {x, y + h / 3, x + w / 2, y + h, x + w, y + h / 3})
        elseif formtype == "trupdown" then
            g.polygon("fill", {x, y + h * (2 / 3), x + w / 2, y, x + w, y + h * (2 / 3)})
            g.polygon("fill", {x, y + h / 3, x + w / 2, y + h, x + w, y + h / 3})
        elseif formtype == "rhombus" then
            g.polygon("fill", {x, y + h / 2, x + w / 2, y + h,  x + w, y + h / 2, x + w / 2, y})
        end
    end

    if nback.is_run then
        debug_print_y = 0
        debug_print_text("pos " .. inspect(nback.pos_signals))
        debug_print_text("sound " .. inspect(nback.sound_signals))
        debug_print_text("form " .. inspect(nback.form_signals))
        debug_print_text("color " .. inspect(nback.color_signals))
        debug_print_text(string.format("current_sig %d", nback.current_sig))
        debug_print_text("nback.can_press = " .. tostring(nback.can_press))
        --debug_print_text(inspect(nback.color_signals))
        debug_print_text("--------------")
        debug_print_signals()
        --debug_print_signals()
        debug_print_text("--------------")

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
        --draw nback level setup invitation
        g.setFont(nback.font)
        --FIXME Dissonance with color and variable name
        g.setColor(pallete.tip_text) 
        local y = 20
        g.printf(string.format("nback level is %d", nback.level),
            0, y, w, "center")
        y = y + nback.font:getHeight()
        g.printf("Use ←→ arrows to setup", 0, y, w, "center")

        -- draw central_text - Press Space key
        local central_text = "Press Space to new round"
        g.setFont(nback.central_font)
        g.setColor(pallete.signal)
        x = (w - nback.central_font:getWidth(central_text)) / 2
        y = (h - nback.central_font:getHeight()) / 2
        g.print(central_text, x, y)
        --

        draw_use_sound_text()
    end

    -- draw left&right help texts
    g.setFont(nback.font)
    if nback.pos_pressed and nback.is_run then
        g.setColor(pallete.tip_text_alt)
    else 
        g.setColor(pallete.tip_text)
    end
    --[[
       [if nback.sound_pressed and nback.is_run then
       [    g.setColor(pallete.tip_text_alt)
       [else 
       [    g.setColor(pallete.tip_text)
       [end
       ]]
    local keys_tip = AlignedLabels:new(nback.font, w)
    local pressed_color = pallete.active
    local unpressed_color = pallete.inactive
    if nback.sound_pressed then
        keys_tip:add("S: sound", pressed_color)
    else
        keys_tip:add("S: sound", unpressed_color)
    end
    if nback.color_pressed then
        keys_tip:add("C: color", pressed_color)
    else
        keys_tip:add("C: color", unpressed_color)
    end
    if nback.form_pressed then
        keys_tip:add("F: form", pressed_color)
    else
        keys_tip:add("F: form", unpressed_color)
    end
    if nback.pos_pressed then
        keys_tip:add("P: position", pressed_color)
    else
        keys_tip:add("P: position", unpressed_color)
    end
    keys_tip:add("kek", {200, 0, 200}, "kak", {0, 200, 0})
    keys_tip:draw(0, bottom_text_line_y)

    --g.printf("A: position", 0, bottom_text_line_y, side_column_w, "center")
    --g.printf("L: sound", w - side_column_w, bottom_text_line_y, side_column_w, "center")

    -- draw escape tip
    g.setFont(nback.font)
    g.setColor(pallete.tip_text)
    g.printf("Escape - to go back", 0, bottom_text_line_y + nback.font:getHeight(), w, "center")
    --
    
    if nback.show_statistic then draw_statistic() end

    g.pop()
end

function AlignedLabels:init(font, screenwidth, color)
    self.screenwidth = screenwidth
    self.font = font
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
function AlignedLabels:add(...)
    --assert(type(text) == "string")
    local args = {...}
    local nargs = select("#", ...)
    if nargs > 2 then
        for i = 1, nargs do
            self.data[#self.data + 1] = select(i, ...)
            assert(check_color_t(select(i + 1, ...)))
            self.colors[#self.colors + 1] = select(i + 1, ...)
            if text:len() > self.maxlen then
                self.maxlen = text:len()
            end
        end
    else
        self.data[#self.data + 1] = select(1, ...)
        self.colors[#self.colors + 1] = select(i + 1, ...) or self.default_color
    end
end

function AlignedLabels:draw(x, y)
    local dw = self.screenwidth / (#self.data + 1)
    local i = x + dw
    local f = g.getFont()
    local c = {g.getColor()}
    g.setFont(self.font)
    for k, v in pairs(self.data) do
        --print(string.format("i = %d, dw = %d", i, dw))
        --print("AlignedLabels:draw()")
        --print(v, i - self.font:getWidth(v) / 2, y)
        g.setColor(self.colors[k])
        g.print(v, i - self.font:getWidth(v) / 2, y)
        i = i + dw
    end
    g.setFont(f)
    g.setColor(c)
end

return nback
