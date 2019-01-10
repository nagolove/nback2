local lovebird = require "libs.lovebird"
local pallete = require "pallete"
local inspect = require "libs.inspect"
local lume = require "libs.lume"
local lurker = require "libs.lurker"
--local ldebug = require "libs.lovedebug"
local dbg = require "dbg"

states = {
    a = {}
}

function states.push(s)
    local prev = states.top()
    if prev and prev.leave then prev.leave() end
    if s.enter then s.enter() end
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
local menu = require "menu"
local nback = require "nback"
local pviewer = require "pviewer"
local colorpicker = require "colorpicker"

local picker = nil
local to_resize = {}

function love.load()
    lovebird.update()
    lovebird.maxlines = 500

    love.window.setTitle("nback")

    menu.init()
    nback.init()
    pviewer.init()
    help.init()

    to_resize[#to_resize + 1] = menu
    to_resize[#to_resize + 1] = nback
    to_resize[#to_resize + 1] = pviewer
    to_resize[#to_resize + 1] = help

    states.push(menu)
end

function love.update(dt)
    if picker then
        picker:update(dt)
    end

    lovebird.update()
    states.top().update(dt)
end

function love.resize(w, h)
    for k, v in pairs(to_resize) do
        if v["resize"] then v.resize(w, h) end
    end
end

function make_screenshot()
    local i = 0
    local fname
    repeat
        i = i + 1
        fname = love.filesystem.getInfo("screenshot" .. i .. ".png")
    until not fname
    love.graphics.captureScreenshot("screenshot" .. i .. ".png")
end

function love.keypressed(key)
    print(key)
    if love.keyboard.isDown("ralt", "lalt") and key == "return" then
        love.window.setFullscreen(not love.window.getFullscreen())
    elseif key == "`" then
        lurker.scan()
    elseif key == "f12" then make_screenshot()
    elseif key == "1" then
        if not picker then
            picker = colorpicker:new()
        else
            picker = nil
            print("picker deleted")
        end
    elseif key == "2" then
        dbg.show = not dbg.show
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
    love.graphics.clear(pallete.background)
    local dr_func = states.top().draw
    if dr_func then dr_func() end
    if picker then
        picker:draw()
    end
end
