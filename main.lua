local math = require "math"
local os = require "os"
local table = require "table"
local string = require "string"
local debug = require "debug"
local inspect = require "inspect"
local lume = require "lume"
local lovebird = require "lovebird"
local tween = require "tween"

current_state = {}

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

    current_state = menu
end

function love.update()
    lovebird.update()
    current_state.update()
end

function love.keypressed(key)
    current_state.keypressed(key)
end

function love.draw()
    current_state.draw()
end
