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
    active_index = 1,
    background_color = {20, 40, 80, 255}
}

function menu.play()
    print("play")
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
        if menu.active_index - 1 >= 1 then
            menu.active_index = menu.active_index - 1
        else
            menu.active_index = #menu.actions
        end
    elseif key == "down" then
        if menu.active_index + 1 <= #menu.items then
            menu.active_index = menu.active_index + 1
        else
            menu.active_index = 1
        end
    elseif key == "escape" then
        menu.quit()
    elseif key == "return" or key == " " then
        menu.actions[menu.active_index]()
    end
end

function menu.update()
end

function menu.draw()
    --for setFont() and colors
    love.graphics.push("all")

    w, h = love.graphics.getDimensions()
    y = (h - #menu.items * menu.font:getHeight()) / 2

    love.graphics.setFont(menu.font)
    love.graphics.setBackgroundColor(menu.background_color)
    love.graphics.clear()

    for i, k in ipairs(menu.items) do
        x = (w - menu.font:getWidth(k)) / 2
        if (menu.active_index == i) then
            love.graphics.setColor(menu.inactive_color)
        else
            love.graphics.setColor(menu.active_color)
        end
        love.graphics.print(k, x, y)
        y = y + menu.font:getHeight()
    end

    --restore settings
    love.graphics.pop()
end

nback = {
    dim = 5,
    cell_width = 90, --width of game field in pixels
    background_color = {20, 40, 80, 255},
    field_color = {20, 80, 80, 255},
    pos_color = {200, 80, 80, 255},
    current_sig = 1,
    sig_count = 5, -- number of signals. 
    level = 2,
    is_run = false,
    pause_time = 1, -- delay beetween signals, in secs
}

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
end

function nback.stop()
    nback.is_run = false
end

function nback.quit()
    nback.stop()
    current_state = menu
end

function nback.keypressed(key)
    if key == "escape" then
        nback.quit()
    elseif key == " " then
        print("kp")
        if not nback.is_run then 
            nback.is_run = true
            print("start")
            nback.start()
        else
            nback.is_run = false
            nback.stop()
        end
    end
end

function nback.draw()
    w, h = love.graphics.getDimensions()
    x0 = (w - nback.dim * nback.cell_width) / 2
    y0 = (h - nback.dim * nback.cell_width) / 2

    local g = love.graphics
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

    -- draw active signal quad
    if nback.is_run then
        g.setColor(nback.pos_color)
        x, y = unpack(nback.pos_signals[nback.current_sig])
        border = 5
        g.rectangle("fill", x0 + x * nback.cell_width + border, 
        y0 + y * nback.cell_width + border,
        nback.cell_width - border * 2, nback.cell_width - border * 2)
        --

        --draw upper text - progress of evaluated signals
        love.graphics.setFont(nback.font)
        love.graphics.setColor(nback.pos_color)
        text = string.format("%d / %d", nback.current_sig, #nback.pos_signals)
        x = (w - nback.font:getWidth(text)) / 2
        y = y0 - nback.font:getHeight()
        love.graphics.print(text, x, y)
        --
    end

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
