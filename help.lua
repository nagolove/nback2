﻿local colors = require "colors"

local help = {
    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 15),
    load = function() end,
    update = function() end,
}

function help.draw()
    local g = love.graphics

    g.push("all")

    g.setBackgroundColor(colors.background)
    g.clear()

    g.setFont(help.font)
    local w, h = g.getDimensions()
    local y = 20
    g.printf("Thhis is a bla-bla", 0, y, w, "center")
    y = y + help.font:getHeight()
    g.printf("Put description here!", 0, y, w, "center")

    g.pop()
end

function help.keypressed(key)
    if key == "escape" then
        states.pop()
    end
end

return help
