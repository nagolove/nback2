local math = require "math"
local os = require "os"
local table = require "table"
local string = require "string"
local debug = require "debug"
local inspect = require "inspect"
local lume = require "lume"
local lovebird = require "lovebird"
local tween = require "tween"

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

local nback = require "nback"
local menu = require "menu"
local pviewer = require "pviewer"
local help = require "help"

function love.load()
    lovebird.update()
    love.window.setTitle("nback trainer!")

    menu.load()
    nback.load()
    pviewer.load()
    help.load()

    states.push(menu)
end

function love.update()
    lovebird.update()
    states.top().update()
end

function love.keypressed(key)
    states.top().keypressed(key)
end

function love.draw()
    states.top().draw()
end
