local inspect = require "libs.inspect"
local pallete = require "pallete"
require "common"
require "gooi.gooi"

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
    self:buildLayout()

    print("gooi", inspect(gooi))
    print("gooi.setStyle", inspect(gooi.setStyle))

    self.gooi = storeGooi()

    gooi.setStyle({ font = g.newFont("gfx/DroidSansMono.ttf", 13),
        showBorder = true,
        bgColor = {0.208, 0.220, 0.222},
    })

    self:buildButtons()
    gooi.components = {}
end

function help:buildButtons()
    local mainMenuBtnLayout = shrink(self.layout.top, nback.border)
    self.mainMenuBtn = gooi.newButton({ 
        text = "Back to menu",
        x = mainMenuBtnLayout.x, y = mainMenuBtnLayout.y, 
        w = mainMenuBtnLayout.w, h = mainMenuBtnLayout.h
    }):onRelease(function()
        linesbuf:push(1, "return to main!")
        menu:goBack()
    end)
end

function help:buildLayout()
    self.layout = {}
    self.layout.top, self.layout.bottom = splith(makeScreenTable(), 0.1, 0.9)
end

function help:resize(neww, newh)
    self:buildLayout()
end

function help:enter()
    print("help:enter()")
    restoreGooi(self.gooi)

    --print("gooi.components", inspect(gooi.components))
    --print("self.gooi", inspect(self.gooi))
end

function help:leave()
    print("help:leave()")
    self.gooi = storeGooi()
end

function help:drawDescription()
    local w, h = g.getDimensions()
    local x, y = self.layout.bottom.x, self.layout.bottom.y
    g.setColor{1, 1, 1, 1}
    g.clear(pallete.background)
    g.setFont(self.font)
    g.printf("This is a bla-bla", x, y, w, "center")
    y = y + self.font:getHeight()
    g.printf("Put description here!", y, y, w, "center")
end

function help:draw()
    self:drawDescription()

    gooi.draw()

    g.setColor{0.3, 0.3, 0.34}
    drawHierachy(self.layout)
end

function help:update(dt)
    gooi.update(dt)
end

function help:mousepressed(x, y, btn, istouch)
    print("help:mousepressed()")
    gooi:pressed()
end

function help:mousereleased(x, y, btn, istouch)
    print("help:mousereleased()")
    gooi:released()
end

function help:keypressed(key)
    if key == "escape" then
        --restoreGooi(self.gooi)
        menu:goBack()
    end
end

return {
    new = help.new
}
