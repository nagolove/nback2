require "love"
require "common"
require "layout"
require "cmn"
require "globals"

--local gooi = require "gooi.gooi"
local pallete = require "pallete"
local fonts = require "fonts"
local i18n = require "i18n"

global type Help = record
    record Desc
        x: number
        y: number
        canvas: love.graphics.Canvas
    end
    new: function(): Help
    init: function()
    buildLayout: function
    buildButtons: function
    prepareDrawDescription: function

    gooi: Gooi
    mainMenuBtn: any
    layout: Layout
    desc: Desc
    font: love.graphics.Font
end

local Help_mt: metatable<Help> = {
    __index = Help
}

--help.__index = help

function Help.new(): Help
    local self = {
        font = fonts.help.font,
    }
    return setmetatable(self as Help, Help_mt)
end

local g = love.graphics

function Help:init()
    self:buildLayout()

    --print("gooi", inspect(gooi))
    --print("gooi.setStyle", inspect(gooi.setStyle))

    gooi.setStyle({ font = fonts.help.gooi,
        showBorder = true,
        bgColor = {0.208, 0.220, 0.222},
    })

    self:buildButtons()
    self.gooi = storeGooi() as Gooi

    --gooi.components = {}
    self:prepareDrawDescription()
end

function Help:buildButtons()
    local mainMenuBtnLayout = shrink(self.layout.top, nback.border)
    self.mainMenuBtn = gooi.newButton({ 
        text = i18n("help.backButton"),
        x = mainMenuBtnLayout.x, y = mainMenuBtnLayout.y, 
        w = mainMenuBtnLayout.w, h = mainMenuBtnLayout.h
    }):onRelease(function()
        --linesbuf:push(1, "return to main!")
        menu:goBack()
    end)
end

function Help:buildLayout()
    self.layout = {}
    self.layout.top, self.layout.bottom = splith(makeScreenTable(), 0.1, 0.9)
end

function Help:resize(_: number, _: number)
    self:buildLayout()
end

function Help:enter()
    print("help:enter()")
    --print("help self.gooi", inspect(self.gooi))
    restoreGooi(self.gooi)

    --print("gooi.components", inspect(gooi.components))
    --print("self.gooi", inspect(self.gooi))
end

function Help:leave()
    print("help:leave()")
    self.gooi = storeGooi()
end

function Help:prepareDrawDescription()
    self.desc = {}

    local w, h = g.getDimensions()
    local x, y = math.floor(self.layout.bottom.x), math.floor(self.layout.bottom.y)
    --if not __ONCE__ then
        --__ONCE__ = true
        --print("x, y", x, y)
    --end
    local descText = i18n("help.desc")
    self.desc.x, self.desc.y = x, y
    self.desc.canvas = g.newCanvas(w, h)
    g.setCanvas(self.desc.canvas)

    g.setColor{1, 1, 1, 1}
    g.clear(pallete.background)
    g.setFont(self.font)

    g.printf(descText, x, y, w - 100, "center")
    --g.printf("This is a bla-bla", x, y, w, "center")
    --y = y + self.font:getHeight()
    --g.printf("Put description here!", y, y, w, "center")

    g.setCanvas()
end

function Help:drawDescription()
    g.setColor{1, 1, 1}
    g.draw(self.desc.canvas as love.graphics.Drawable, self.desc.x, self.desc.y)
end

function Help:draw()
    g.clear(pallete.background)
    tiledback:draw(0.3)
    self:drawDescription()

    gooi.draw()

    --g.setColor{0.3, 0.3, 0.34}
    --drawHierachy(self.layout)
end

function Help:update(dt: number)
    gooi.update(dt)
end

function Help:mousepressed(_: number, _: number, _: number, _: boolean)
    print("help:mousepressed()")
    gooi:pressed()
end

function Help:mousereleased(_: number, _: number, _: number, _: boolean)
    print("help:mousereleased()")
    gooi:released()
end

function Help:keypressed(key: string)
    if key == "escape" then
        --restoreGooi(self.gooi)
        menu:goBack()
    end
end

return {
    new = Help.new
}

