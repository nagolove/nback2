local math = require "math"
local os = require "os"
local table = require "table"
local string = require "string"
local debug = require "debug"
local inspect = require "inspect"
local lume = require "lume"
local lovebird = require "lovebird"
local tween = require "tween"

current_state = {}
menu = {
    active_color = {255, 255, 255, 255},
    inactive_color = {100, 200, 70, 255},
    active_item = 1,
    background_color = {20, 40, 80, 255},
}

function menu.play()
    nback.enter()
    current_state = nback
end

function menu.view_progress()
end

function menu.quit()
    love.event.quit()
end

function menu.load()
    menu.font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 32)
    menu.items = {"play", "view progress", "quit"}
    menu.actions = { menu.play, menu.view_progress, menu.quit }
end

function menu.keypressed(key)
    print("pressed", key)
    if key == "up" then
        if menu.active_item - 1 >= 1 then
            menu.active_item = menu.active_item - 1
        else
            menu.active_item = #menu.actions
        end
    elseif key == "down" then
        if menu.active_item + 1 <= #menu.items then
            menu.active_item = menu.active_item + 1
        else
            menu.active_item = 1
        end
    elseif key == "escape" then
        menu.quit()
    elseif key == "return" or key == " " then
        menu.actions[menu.active_item]()
    end
end

function menu.update()
end

function menu.draw()
    local g = love.graphics
    g.push("all")

    w, h = g.getDimensions()
    y = (h - #menu.items * menu.font:getHeight()) / 2

    g.setFont(menu.font)
    g.setBackgroundColor(menu.background_color)
    g.clear()

    for i, k in ipairs(menu.items) do
        x = (w - menu.font:getWidth(k)) / 2
        if (menu.active_item == i) then
            g.setColor(menu.inactive_color)
        else
            g.setColor(menu.active_color)
        end
        g.print(k, x, y)
        y = y + menu.font:getHeight()
    end

    g.pop()
end

nback = {
    dim = 5,
    cell_width = 90,                                -- width of game field in pixels
    background_color = {20, 40, 80, 255},
    field_color = {20, 80, 80, 255},
    pos_color = {200, 80, 80, 255},
    sound_text_color_disabled = {255, 255, 0, 255},
    sound_text_color_enabled = {0, 240, 0, 255},
    current_sig = 1,
    sig_count = 5,                                  -- number of signals.
    level = 2,
    is_run = false,
    pause_time = 1,                                 -- delay beetween signals, in seconds
    central_text = "",
    use_sound_text = "",
    use_sound = true,
    save_name = "nback-v0.1.lua",
    set_statistic = { successful_count = 0 },       -- statistic which loaded from file and saved
}

function nback.enter()
    data, size = love.filesystem.read(nback.save_name)
    if data ~= nil then
        nback.set_statistic = lume.deserialize(data)
    end
    nback.central_text = "Press Space to new round"
    nback.change_sound();
end

function nback.change_sound()
    if nback.use_sound then
        nback.use_sound_text = "For enable sound - press S"
    else
        nback.use_sound_text = "For disable sound - press S"
    end
    nback.use_sound = not nback.use_sound
end

function nback.gen_tuple()
    return {math.random(1, nback.dim - 1), math.random(1, nback.dim - 1)}
end

function nback.generate_pos(sig_count)
    ret = {}
    ratio = 4
    range = {1, 3}
    count = sig_count

    for i = 1, ratio * sig_count, 1 do
        table.insert(ret, {-1, -1})
    end

    repeat
        i = 1
        repeat
            if count > 0 then
                prob = math.random(unpack(range))
                if prob == range[2] then
                    if i + nback.level <= #ret and ret[i][1] == -1 and ret[i + nback.level][1] == -1 then
                        tuple = nback.gen_tuple()
                        ret[i] = lume.clone(tuple)
                        ret[i + nback.level] = lume.clone(tuple)
                        count = count - 1
                    end
                end
            end
            i = i + 1
            print(inspect(ret))
        until i > #ret
    until count == 0

    for i = 1, #ret, 1 do
        if ret[i][1] == -1 then
            repeat
                ret[i] = nback.gen_tuple()
            until not (i + nback.level <= #ret and 
                    ret[i][1] == ret[i + nback.level][1] and 
                    ret[i][2] == ret[i + nback.level][2])
        end
    end

    print(inspect(ret))

    return ret
end

function nback.load()
    nback.font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 13)
    nback.central_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 42)
    math.randomseed(os.time())
end

function nback.update()
    if nback.is_run then
        time = love.timer.getTime()
        print("diff", time - nback.timestamp)
        if (time - nback.timestamp >= nback.pause_time) then
            nback.timestamp = love.timer.getTime()
            if (nback.current_sig <= #nback.pos_signals) then
                nback.current_sig = nback.current_sig + 1
                print("step")
            end
        end

        if nback.current_sig == #nback.pos_signals then
            nback.central_text = "Press Space to new round"
            nback.stop()
        end
    end
end

function nback.start()
    print("generate_pos()")
    nback.pos_signals = nback.generate_pos(nback.sig_count)
    print(inspect(nback.pos_signals))
    nback.current_sig = 1
    nback.timestamp = love.timer.getTime()
    nback.central_text = ""
    nback.use_sound_text = ""
end

function nback.stop()
    nback.is_run = false
    love.filesystem.write(nback.save_name, lume.serialize(nback.set_statistic))
end

function nback.quit()
    nback.stop()
    current_state = menu
end

function nback.keypressed(key)
    if key == "escape" then
        nback.quit()
    elseif key == " " then
        if not nback.is_run then 
            nback.is_run = true
            nback.start()
        else
            nback.is_run = false
            nback.stop()
        end
    elseif key == "s" then
        nback.change_sound()
    elseif key == "a" then
        nback.check_position()
    end
end

function tuple_cmp(a, b)
    return a[1] == b[1] and a[2] == b[2]
end

function nback.check_position()
    if nback.current_sig + nback.level <= #nback.pos_signals and
        tuple_cmp(nback.pos_signals[nback.current_sig], nback.pos_signals[nback.current_sig]) then
        nback.set_statistic.successful_count = nback.set_statistic.successful_count + 1
    end
end

function nback.draw()
    local g = love.graphics

    w, h = g.getDimensions()
    x0 = (w - nback.dim * nback.cell_width) / 2
    y0 = (h - nback.dim * nback.cell_width) / 2

    g.push("all")

    --draw background
    g.setBackgroundColor(nback.background_color)
    g.clear()
    --

    --draw game field grid
    g.setColor(nback.field_color)
    for i = 0, nback.dim, 1 do
        g.line(x0, y0 + i * nback.cell_width, 
            x0 + nback.dim * nback.cell_width, y0 + i * nback.cell_width)
        g.line(x0 + i * nback.cell_width, y0,
            x0 + i * nback.cell_width, y0 + nback.dim * nback.cell_width)
    end
    --

    if nback.is_run then
        -- draw active signal quad
        g.setColor(nback.pos_color)
        x, y = unpack(nback.pos_signals[nback.current_sig])
        border = 5
        g.rectangle("fill", x0 + x * nback.cell_width + border, 
        y0 + y * nback.cell_width + border,
        nback.cell_width - border * 2, nback.cell_width - border * 2)
        --

        --draw upper text - progress of evaluated signals
        g.setFont(nback.font)
        g.setColor(nback.pos_color)
        text = string.format("%d / %d", nback.current_sig, #nback.pos_signals)
        x = (w - nback.font:getWidth(text)) / 2
        y = y0 - nback.font:getHeight()
        g.print(text, x, y)
        --
    end

    -- draw central_text - Press Space key
    g.setFont(nback.central_font)
    g.setColor(nback.pos_color)
    x = (w - nback.central_font:getWidth(nback.central_text)) / 2
    y = (h - nback.central_font:getHeight()) / 2
    g.print(nback.central_text, x, y)
    --

    -- draw use_sound_text
    if not nback.use_sound then
        -- draw with disabled color
        g.setFont(nback.font)
        g.setColor(nback.sound_text_color_disabled)
        x = (w - nback.font:getWidth(nback.use_sound_text)) / 2
        local field_h = nback.dim * nback.cell_width
        y = y0 + field_h + nback.font:getHeight()
        g.print(nback.use_sound_text, x, y)
        --
    else
        -- draw with enabled color
        g.setFont(nback.font)
        g.setColor(nback.sound_text_color_enabled)
        x = (w - nback.font:getWidth(nback.use_sound_text)) / 2
        local field_h = nback.dim * nback.cell_width
        y = y0 + field_h + nback.font:getHeight()
        g.print(nback.use_sound_text, x, y)
        --
    end
    --

    g.pop()
end

function love.load()
    lovebird.update()
    love.window.setTitle("nback trainer!")

    menu.load()
    nback.load()

    current_state = menu
end

function love.update()
    lovebird.update()
    current_state.update()
end

function love.keypressed(key)
    current_state.keypressed(key)
end

function love.draw()
    current_state.draw()
end
