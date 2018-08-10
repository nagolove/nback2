local lovebird = require "libs.lovebird"
local lume = require "libs.lume"
local lurker = require "libs.lurker"

states = {
    a = {}
}

function states.push(s)
    states.a[#states.a + 1] = s
end

function states.pop()
    local last = states.a[#states.a]
    if last.leave then last.leave() end
    states.a[#states.a] = nil
end

function states.top()
    return states.a[#states.a]
end

local help = require "help"
local layout = require "layout"
local menu = require "menu"
local nback = require "nback"
local pviewer = require "pviewer"
local colorpicker = require "colorpicker"

local picker = nil

function love.load()
    lovebird.update()
    lovebird.maxlines = 500

    love.window.setTitle("nback")

    layout.init()

    menu.init()
    nback.init()
    pviewer.init()
    help.init()

    states.push(menu)
end

function love.update(dt)
    if love.keyboard.isDown("ralt", "lalt") and love.keyboard.isDown("return") then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
    if picker then
        picker:update(dt)
    end

    lovebird.update()
    states.top().update(dt)
end

function love.resize(w, h)
    for k, v in pairs(states.a) do
        if v["resize"] then v.resize(w, h) end
    end
    layout.resize(w, h)
end

function love.keypressed(key)
    if key == "`" then
        lurker.scan()
    elseif key == "1" then
        if not picker then
            picker = colorpicker:new()
        else
            picker = nil
            print("picker deleted")
        end
    else
        states.top().keypressed(key)
    end
end

function love.mousepressed(x, y, button, istouch)
    if picker then
        picker:mousepressed(x, y, button, istouch)
    end
end

function love.draw()
    local dr_func = states.top().draw()
    if dr_func then dr_func() end
    --layout.draw()
    if picker then
        picker:draw()
    end
end
