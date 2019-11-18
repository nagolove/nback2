local pallete = require "pallete"

local help = {}
help.__index = help

function help.new()
    local self = {
        font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 15),
    }
    return setmetatable(self, help)
end

local g = love.graphics

function help:init()
end

function help:draw()
    local w, h = g.getDimensions()
    local y = 20
    g.push("all")
    g.setColor(1, 1, 1, 1)
    g.clear(pallete.background)
    g.setFont(help.font)
    g.printf("This is a bla-bla", 0, y, w, "center")
    y = y + help.font:getHeight()
    g.printf("Put description here!", 0, y, w, "center")
    g.pop()
end

function help:update()
end

function help:keypressed(key)
    if key == "escape" then
        menu:goBack()
    end
end

return {
    new = help.new
}
