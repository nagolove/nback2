require "math"

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

nback = {}

function nback.load()
end

function nback.update()
end

function nback.quit()
    current_state = menu
end

function nback.keypressed(key)
    if key == "escape" then
        nback.quit()
    end
end

function nback.draw()
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
