require "math"

lume = require "lume"
lovebird = require "lovebird"
tween = require "tween"

menu = {}

function menu.load()
    menu.font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 24)
    menu.items = {"play", "view progress", "quit"}
end

function menu.update()
end

function menu.draw()
    w, h = love.graphics.getDimensions()

    y = (h - #menu.items * menu.font.getHeight()) / 2

    print "OK"
    for i, k in ipairs(menu.items) do
        x = (w - menu.font.getWidth()) / 2
        love.graphics.setFont(menu.font)
        print(k, x, y)
        love.graphics.print(k, x, y)
        y = y + menu.font.getHeight()
    end
end

function menu.draw()
    love.graphics.setFont(menu.font)
    love.graphics.print("ou!", 10, 10)
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
end

function love.draw()
    menu.draw()
end
