local inspect = require "libs.inspect"
local lume = require "libs.lume"
local math = require "math"
local os = require "os"
local string = require "string"
local table = require "table"

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
        hits = 0,
    },
    show_statistic = false,
    sounds = {},
    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 13),
    central_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 42),
    statistic_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
}

function nback.start()
    nback.is_run = true

    nback.pos_signals = generate_nback(nback.sig_count, 
        function()
            return {math.random(1, nback.dim - 1), math.random(1, nback.dim - 1)}
        end,
        function(a, b)
            return  a[1] == b[1] and a[2] == b[2]
        end)
    print("pos", inspect(nback.pos_signals))

    nback.sound_signals = generate_nback(nback.sig_count, 
        function()
            return math.random(1, #nback.sounds)
        end,
        function(a, b)
            return a == b
        end)
    print("snd", inspect(nback.sound_signals))

    nback.current_sig = 1
    nback.timestamp = love.timer.getTime()
    nback.use_sound_text = ""
    nback.statistic.hits  = 0
    nback.show_statistic = false
end

function nback.enter()
    nback.change_sound();
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

    wave_path = "sfx/alphabet/"
    for k, v in pairs(love.filesystem.getDirectoryItems(wave_path)) do
        table.insert(nback.sounds, love.audio.newSource(wave_path .. v))
    end
end

function nback.update()
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
            nback.snd_pressed = false
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

function nback.keypressed(key)
    if key == "escape" then
        nback.quit()
    elseif key == "space" or key == "return" then
        if not nback.is_run then 
            nback.start()
        else
            nback.stop()
            nback.enter()
        end
    --elseif key == "s" then
        --nback.change_sound()
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
                print(nback.statistic.hits )
                nback.statistic.hits  = nback.statistic.hits  + 1
                nback.can_press = false
            end
        end
    end
end

function nback.check_sound()
    if not nback.is_run then return end

    nback.snd_pressed = true

    if nback.use_sound and nback.current_sig - nback.level > 1 then
        if nback.sound_signals[nback.current_sig] == nback.sound_signals[nback.current_sig - nback.level] then
            if nback.can_press then
                print("sound hit!")
                print(nback.statistic.hits )
                nback.statistic.hits  = nback.statistic.hits  + 1
                nback.can_press = false
            end
        end
    end
end

function nback.check_color()
end

function nback.check_form()
end

function nback.draw()
    local x0 = (w - nback.dim * nback.cell_width) / 2
    local y0 = (h - nback.dim * nback.cell_width) / 2
    local field_h = nback.dim * nback.cell_width
    local bottom_text_line_y = y0 + field_h + nback.font:getHeight()
    local side_column_w = (w - field_h) / 2

    function draw_statistic()
        if nback.show_statistic then
            g.setFont(nback.statistic_font)
            g.setColor(pallete.statistic)

            y = y0 + nback.statistic_font:getHeight()
            g.printf(string.format("Set results:"), 0, y, w, "center")

            local percent = nback.sig_count / nback.statistic.hits * 100
            y = y + nback.statistic_font:getHeight()
            g.printf(string.format("rating %d%%", percent), 0, y, w, "center")
        end
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

        g.print(use_sound_text, (w - nback.font:getWidth(use_sound_text)) / 2, bottom_text_line_y)
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

    if nback.is_run then
        -- draw active signal quad
        g.setColor(pallete.signal)
        local x, y = unpack(nback.pos_signals[nback.current_sig])
        local border = 5
        g.rectangle("fill", x0 + x * nback.cell_width + border, 
            y0 + y * nback.cell_width + border,
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
    g.printf("A: position", 0, bottom_text_line_y, side_column_w, "center")
    if nback.snd_pressed and nback.is_run then
        g.setColor(pallete.tip_text_alt)
    else 
        g.setColor(pallete.tip_text)
    end
    g.printf("L: sound", w - side_column_w, bottom_text_line_y, side_column_w, "center")

    -- draw escape tip
    g.setFont(nback.font)
    g.setColor(pallete.tip_text)
    g.printf("Escape - to go back", 0, bottom_text_line_y + nback.font:getHeight(), w, "center")
    --
    
    draw_statistic()

    g.pop()
end

return nback
