﻿local pallete = require "pallete"
local nback = require "nback"

local help = {
    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 15),
    init = function() end,
    update = function() end,
}

local g = love.graphics

function help.draw()
    g.clear(pallete.background)
    g.push("all")
    g.setFont(help.font)
    local w, h = g.getDimensions()
    local y = 20
    g.printf("This is a bla-bla", 0, y, w, "center")
    y = y + help.font:getHeight()
    g.printf("Put description here!", 0, y, w, "center")
    --FIXME Not work, using nil table nback here
    --g.printf("Escape - to go back", 0, bottom_text_line_y + nback.font:getHeight(), w, "center")
    g.pop()
end

function help.keypressed(key)
    if key == "escape" then
        states.pop()
    end
end

return help