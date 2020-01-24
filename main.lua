onAndroid = love.system.getOS() == "Android" or false
onAndroid = true
netLogging = true
--netLogging = false

require("common")

local Timer = require "libs/Timer"
local inspect = require "libs/inspect"
local lovebird = require "libs/lovebird"
local lume = require "libs/lume"
local pallete = require "pallete"

--[[
  Диапазон портов:
  10081 - cmdclient
  10082 - logclient
]]--
--local ntwk
if netLogging then
    --ntwk = require "ntwk".new("visualdoj.ru", 10081, true)
    --ntwk = require "ntwk".new("127.0.0.1", 10081)
else
    --ntwk = require "ntwk".dummy()
end

help = require "help".new()
menu = require "menu".new()
nback = require "nback".new()
pviewer = require "pviewer".new()

function print2log()
    --ntwk:print("getSaveDirectory() = " .. 
        --love.filesystem.getSaveDirectory() .. "\n")

    --local w, h = love.graphics.getDimensions()
    --ntwk:print(string.format("screen resolution %d x %d\n", w, h))

    --ntwk:print(string.format("cpu count %d\n", 
        --love.system.getProcessorCount()))

    --ntwk:print(string.format("os %s\n", love.system.getOS()))
end

function love.quit()
end

local save_name = "nback-v0.3.lua"

function love.load()
    math.randomseed(os.time())
    lovebird.update()
    lovebird.maxlines = 2000
    love.window.setTitle("nback")
    --require "splash".init()

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

    if onAndroid then
        love.window.setMode(0, 0, {fullscreen = true})
        --love.window.setMode(0, 0, {fullscreen = true, 
            --fullscreentype = "exclusive"})
        screenMode = "fs"
        dispatchWindowResize(love.graphics.getDimensions())
    end

    print2log()
end

function love.update(dt)
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
    if onAndroid then return end

    -- ctrl-d hotkey to start debugger
    if love.keyboard.isScancodeDown("lctrl") and scancode == "d" then
        debug.debug()
    end
    -- ctrl-s hotkey for save gamedata to file
    if love.keyboard.isScancodeDown("lctrl") and scancode == "s" then
        nback:save_to_history()
    end

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
    end
    if key == "f12" then make_screenshot()
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
    love.timer.sleep(0.01)
end

function love.mousemoved(x, y, dx, dy, istouch)
    menu:mousemoved(x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch)
    menu:mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    if menu.mousereleased then
        menu:mousereleased(x, y, button, istouch)
    end
end
