require("common")

local Timer = require "libs/Timer"
local inspect = require "libs/inspect"
local lovebird = require "libs/lovebird"
local lume = require "libs/lume"
local lurker = require "libs/lurker"
local pallete = require "pallete"
--local splash = require "splash"

--local ldebug = require "libs.lovedebug"
local dbg = require "dbg"

states = {
    a = {}
}

function states.push(s)
    xassert(type(s) == "table", function() return "'s' should be a table" end)
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

local timer = Timer()
local help = require "help".new()
local menu = require "menu".new()
local nback = require "nback".new()
local pviewer = require "pviewer".new()
local colorpicker = require "colorpicker"
local picker = nil

function love.load()
    lovebird.update()
    lovebird.maxlines = 2000
    love.window.setTitle("nback")
    -- Ручная инициализация модулей
    --splash.init()
    menu:init()

    local save_name = "nback-v0.3.lua"
    --game = nback.new(save_name)
    nback:init(save_name)

    pviewer:init(save_name)
    help:init()
    states.push(menu)
    --states.push(splash)
end

function love.update(dt)
    if picker then
        picker:update(dt)
    end

    lovebird.update()
    timer:update()
    states.top().update(dt)
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

local screenMode = "win" -- or "fs"
local to_resize = {menu, pviewer, help}

function dispatchWindowResize(w, h)
    game:resize(w, h)
    for k, v in pairs(to_resize) do
        if v["resize"] then v:resize(w, h) end
    end
end

function love.keypressed(key, scancode)
    print(string.format("key %s, scancode %s", key, scancode))
    if love.keyboard.isDown("ralt", "lalt") and key == "return" then
        -- код дерьмовый, но работает
        if screenMode == "fs" then
            love.window.setMode(800, 600, {fullscreen = false})
            screenMode = "win"
            dispatchWindowResize(love.graphics.getDimensions())
        else
            love.window.setMode(0, 0, {fullscreen = true,
                                       fullscreentype = "exclusive"})
            screenMode = "fs"
            dispatchWindowResize(love.graphics.getDimensions())
        end
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
    else
        states.top().keypressed(key, scancode)
    end
end

function love.mousepressed(x, y, button, istouch)
    if picker then
        picker:mousepressed(x, y, button, istouch)
    end
end

function love.draw()
    local dr_func = states.top().draw or function() end
    if picker then
        picker:draw(dr_func)
    else
        dr_func()
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if states.top().mousemoved then states.top().mousemoved(x, y, dx, dy, istouch) end
end

function love.mousepressed(x, y, button, istouch)
    if states.top().mousepressed then states.top().mousepressed(x, y, button, istouch) end
end

function love.mousereleased(x, y, button, istouch)
    if states.top().mousereleased then states.top().mousereleased(x, y, button, istouch) end
end
