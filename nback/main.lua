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

function love.load()
    lovebird.update()
    lovebird.maxlines = 500

    love.window.setTitle("nback trainer!")

    layout.init()

    menu.load()
    nback.load()
    pviewer.load()
    help.load()

    states.push(menu)
end

function love.update(dt)
    lovebird.update()
    states.top().update(dt)
end

function love.keypressed(key)
    if key == "`" then
        lurker.scan()
    else
        states.top().keypressed(key)
    end
end

function love.draw()
    states.top().draw()
    layout.draw()
end
