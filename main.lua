require("common")

local Timer = require "libs/Timer"
local inspect = require "libs/inspect"
local lovebird = require "libs/lovebird"
local lume = require "libs/lume"
local lurker = require "libs/lurker"
local pallete = require "pallete"
local serpent = require "serpent"
--local splash = require "splash"

local dbg = require "dbg"

help = require "help".new()
menu = require "menu".new()
nback = require "nback".new()
pviewer = require "pviewer".new()

function love.load()
    math.randomseed(os.time())
    lovebird.update()
    lovebird.maxlines = 2000
    love.window.setTitle("nback")
    --splash.init()

    local save_name = "nback-v0.3.lua"

    -- Ручная инициализация модулей
    nback:init(save_name)
    pviewer:init(save_name)
    menu:init()
    help:init()

    -- проблема в том, что два раза определяю список состояний для одного меню.
    -- Нужно как-то обойтись одним списком.
    -- Задача - как выйти из текущего объекта состояния? Скажеи из pviewer'а?
    -- Для этого нужно позвонить в объект меню, если он хранит весь список
    -- состояний через метод, к примеру - menu:goBack()
    menu:addItem("play", nback)
    menu:addItem("view progress", pviewer)
    menu:addItem("help", help)
    menu:addItem("quit", function() love.event.quit() end)
end

function love.update(dt)
    lovebird.update()
    menu:update(dt)
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
local to_resize = {nback, menu, pviewer, help}

function dispatchWindowResize(w, h)
    for k, v in pairs(to_resize) do
        if v["resize"] then v:resize(w, h) end
    end
end

function love.keypressed(key, scancode)
    if love.keyboard.isScancodeDown("lctrl") and scancode == "d" then
        debug.debug()
    end

    print(string.format("key %s, scancode %s", key, scancode))

    -- переключение режимов экрана
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
    else
        menu:keypressed(key, scancode)
    end
end

function love.keyreleased(key, scancode)
    menu:keyreleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch)
end

function love.draw()
    menu:draw()
end

function love.mousemoved(x, y, dx, dy, istouch)
    menu:mousemoved(x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch)
    menu:mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    menu:mousereleased(x, y, button, istouch)
end
