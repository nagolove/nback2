local math = require "math"
local table = require "table"
local inspect = require "inspect"

lume = require "lume"
lovebird = require "lovebird"
tween = require "tween"

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
    if key == "up" and menu.active_index - 1 >= 1 then
        menu.active_index = menu.active_index - 1
    elseif key == "down" and menu.active_index + 1 <= #menu.items then
        menu.active_index = menu.active_index + 1
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
    sig_count = 10,
    is_run = false,
}

function nback.generate_pos(len)
    ret = {}
    for i = 1, len, 1 do
        table.insert(ret, {math.random(1, nback.dim - 1), math.random(1, nback.dim - 1)})
    end
    return ret
end

function nback.load()
end

function nback.update()
end

function nback.start()
    print("generate_pos()")
    nback.pos_signals = nback.generate_pos(nback.sig_count)
    nback.current_sig = 1
end

function nback.stop()
end

function nback.quit()
    current_state = menu
end

function nback.keypressed(key)
    if key == "escape" then
        nback.quit()
    elseif key == " " then
        nback.is_run = not nback.is_run
        if nback.is_run then 
            nback.start()
        else
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

    g.setBackgroundColor(nback.background_color)
    g.clear()
    g.setColor(nback.field_color)

    for i = 0, nback.dim, 1 do
        g.line(x0, y0 + i * nback.cell_width, 
            x0 + nback.dim * nback.cell_width, y0 + i * nback.cell_width)
        g.line(x0 + i * nback.cell_width, y0,
            x0 + i * nback.cell_width, y0 + nback.dim * nback.cell_width)
    end

    if nback.is_run then
        g.setColor(nback.pos_color)
        x, y = unpack(nback.pos_signals[nback.current_sig])
        g.rectangle("fill", x0 + x * nback.cell_width, y0 + y * nback.cell_width,
            nback.cell_width, nback.cell_width)
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
