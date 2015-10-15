﻿local inspect = require "inspect"
local lume = require "lume"
local math = require "math"
local os = require "os"
local string = require "string"
local table = require "table"

local colors = require "colors"

local nback = {
    dim = 5,
    cell_width = 90,                                -- width of game field in pixels
    current_sig = 1,
    sig_count = 3,                                  -- number of signals.
    level = 2,
    is_run = false,
    pause_time = 1.5,                               -- delay beetween signals, in seconds
    central_text = "",
    use_sound_text = "",
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

    nback.sound_signals = generate_nback(nback.sig_count, 
        function()
            return math.random(1, #nback.sounds)
        end,
        function(a, b)
            return a == b
        end)

    nback.current_sig = 1
    nback.timestamp = love.timer.getTime()
    nback.central_text = ""
    nback.use_sound_text = ""
    nback.statistic.hits  = 0
    nback.show_statistic = false
end

function nback.enter()
    nback.central_text = "Press Space to new round"
    nback.change_sound();
end

function nback.change_sound()
    if nback.is_run then return end

    if nback.use_sound then
        nback.use_sound_text = "For enable sound - press S"
    else
        nback.use_sound_text = "For disable sound - press S"
    end
    nback.use_sound = not nback.use_sound
end

function generate_nback(sig_count, gen, cmp)
    local ret = {}
    local ratio = 4
    local range = {1, 3}
    local count = sig_count
    local null = {}

    for i = 1, ratio * sig_count, 1 do
        table.insert(ret, null)
    end

    repeat
        local i = 1
        repeat
            if count > 0 then
                prob = math.random(unpack(range))
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

    for i = 1, #ret, 1 do
        if ret[i] == null then
            repeat
                ret[i] = gen()
            until not (i + nback.level <= #ret and cmp(ret[i], ret[i + nback.level]))
        end
    end

    print("positions", inspect(ret))

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
        time = love.timer.getTime()
        if (time - nback.timestamp >= nback.pause_time) then
            nback.timestamp = love.timer.getTime()

            if (nback.current_sig <= #nback.pos_signals) then
                nback.current_sig = nback.current_sig + 1
                nback.can_press = true
            end
            
            if nback.use_sound then
                nback.sounds[nback.sound_signals[nback.current_sig]]:play()
            end
        end

        if nback.current_sig == #nback.pos_signals then
            nback.central_text = "Press Space to new round"
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
        table.insert(history, { date = os.date("*t"), stat = nback.statistic })
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
    elseif key == " " then
        if not nback.is_run then 
            nback.start()
        else
            nback.stop()
        end
    elseif key == "s" then
        nback.change_sound()
    elseif key == "a" then
        nback.check_position()
    elseif key == "l" then
        nback.check_sound()
    end

    if not nback.is_run then
        if key == "left" and nback.level > 2 then
            nback.level = nback.level - 1
        elseif key == "right" and nback.level < 8 then
            nback.level = nback.level + 1
        end
    end
end

function tuple_cmp(a, b)
    return a[1] == b[1] and a[2] == b[2]
end

function nback.check_position()
    if not nback.is_run then return end

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

function nback.draw()
    local g = love.graphics
    local w, h = g.getDimensions()
    local x0 = (w - nback.dim * nback.cell_width) / 2
    local y0 = (h - nback.dim * nback.cell_width) / 2

    g.push("all")

    --draw background
    g.setBackgroundColor(colors.background)
    g.clear()
    --

    --draw game field grid
    g.setColor(colors.field)
    for i = 0, nback.dim, 1 do
        g.line(x0, y0 + i * nback.cell_width, 
            x0 + nback.dim * nback.cell_width, y0 + i * nback.cell_width)
        g.line(x0 + i * nback.cell_width, y0,
            x0 + i * nback.cell_width, y0 + nback.dim * nback.cell_width)
    end
    --

    if nback.is_run then
        -- draw active signal quad
        g.setColor(colors.signal)
        local x, y = unpack(nback.pos_signals[nback.current_sig])
        border = 5
        g.rectangle("fill", x0 + x * nback.cell_width + border, 
        y0 + y * nback.cell_width + border,
        nback.cell_width - border * 2, nback.cell_width - border * 2)
        --

        --draw upper text - progress of evaluated signals
        g.setFont(nback.font)
        g.setColor(colors.signal)
        text = string.format("%d / %d", nback.current_sig, #nback.pos_signals)
        x = (w - nback.font:getWidth(text)) / 2
        y = y0 - nback.font:getHeight()
        g.print(text, x, y)
        --
    else
        --draw nback level setup invitation
        g.setFont(nback.font)
        --FIXME Dissonance with color and variable name
        g.setColor(colors.sound_text_enabled) 
        local y = 20
        g.printf(string.format("nback level is %d", nback.level),
            0, y, w, "center")
        y = y + nback.font:getHeight()
        g.printf("Use ←→ arrows to setup", 0, y, w, "center")
    end

    -- draw central_text - Press Space key
    g.setFont(nback.central_font)
    g.setColor(colors.signal)
    x = (w - nback.central_font:getWidth(nback.central_text)) / 2
    y = (h - nback.central_font:getHeight()) / 2
    g.print(nback.central_text, x, y)
    --

    -- draw use_sound_text
    if not nback.is_run then
        if nback.use_sound then
            -- draw with enabled color
            g.setFont(nback.font)
            g.setColor(colors.sound_text_enabled)
            x = (w - nback.font:getWidth(nback.use_sound_text)) / 2
            local field_h = nback.dim * nback.cell_width
            y = y0 + field_h + nback.font:getHeight()
            g.print(nback.use_sound_text, x, y)
            --
        else
            -- draw with disabled color
            g.setFont(nback.font)
            g.setColor(colors.sound_text_disabled)
            x = (w - nback.font:getWidth(nback.use_sound_text)) / 2
            local field_h = nback.dim * nback.cell_width
            y = y0 + field_h + nback.font:getHeight()
            g.print(nback.use_sound_text, x, y)
            --
        end
    end
    --

    -- draw statistic of a set
    if nback.show_statistic then
        g.setFont(nback.statistic_font)
        g.setColor(colors.statistic)

        y = y0 + nback.statistic_font:getHeight()
        g.printf(string.format("Set results:"), 0, y, w, "center")

        y = y + nback.statistic_font:getHeight()
        local percent = nback.statistic.hits  / nback.sig_count * 100
        g.printf(string.format("hits %d/%d successful %d%%", nback.statistic.hits ,
            nback.sig_count, percent), 0, y, w, "center")
    end
    --

    g.pop()
end

return nback
