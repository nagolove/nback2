require "math"

lume = require "lume"
lovebird = require "lovebird"
tween = require "tween"

menu = {
    active_color = {255, 255, 255, 255},
    inactive_color = {100, 200, 70, 255},
}

function menu.load()
    menu.font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 24)
    menu.items = {"play", "view progress", "quit"}
    menu.active_index = 1
end

function menu.keypressed(key)
    if key == "up" and menu.active_index + 1 <= #menu.items then
        menu.active_index = menu.active_index + 1
    elseif key == "down" and menu.active_index - 1 >= 1 then
        menu.active_index = menu.active_index - 1
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

    love.graphics.pop()
end

function love.load()
    lovebird.update()

    menu.load()
end

function love.update()
    lovebird.update()
    menu.update()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    menu.keypressed()
end

function love.draw()
    menu.draw()
end
