onAndroid = love.system.getOS() == "Android" or false
useKeyboard = true
onAndroid = true

require "common"

local profi = require "ProFi"
local lg = love.graphics
local inspect = require "libs/inspect"
local pallete = require "pallete"
local splash = require "splash"
local timer = require "libs/Timer"()

keyconfig = require "keyconfig"
i18n = require "i18n"
linesbuf = require "kons".new()
cam = require "camera".new()
profiCam = require "camera".new()
help = require "help".new()
menu = require "menu".new()
nback = require "nback".new()
pviewer = require "pviewer".new()
save_name = "nback-v0.4.lua"

function love.quit()
end

function loadLocales()
    local files = love.filesystem.getDirectoryItems("locales")
    print("locale files", inspect(files))
    for _, v in pairs(files) do 
        i18n.loadFile("locales/" .. v, function(path)
            local chunk, errmsg = love.filesystem.load(path)
            if not chunk then
                error(errmsg)
            end
            return chunk
        end) 
    end
end

function setupLocale(locale)
    print("setupLocale", locale)
    i18n.setLocale(locale)
end

function love.load(arg)
    print("arg", inspect(arg))
    loadLocales()
    local locale = "en"
    if arg[1] then
        locale = string.match(arg[1], "locale=(%S+)") or "en"
    end
    setupLocale(locale)
    bindKeys()

    math.randomseed(os.time())
    love.window.setTitle("nback")
    --require "splash".init()

    -- Ручная инициализация модулей
    nback:init()
    pviewer:init()
    menu:init()
    help:init()

    -- проблема в том, что два раза определяю список состояний для одного меню.
    -- Нужно как-то обойтись одним списком.
    -- Задача - как выйти из текущего объекта состояния? Скажеи из pviewer'а?
    -- Для этого нужно позвонить в объект меню, если он хранит весь список
    -- состояний через метод, к примеру - menu:goBack()
    menu:addItem(i18n("mainMenu.play"), nback)
    menu:addItem(i18n("mainMenu.viewProgress"), pviewer)
    menu:addItem(i18n("mainMenu.help"), help)
    menu:addItem(i18n("mainMenu.exit"), function() love.event.quit() end)

    if onAndroid then
        love.window.setMode(0, 0, {fullscreen = true})
        --love.window.setMode(0, 0, {fullscreen = true, fullscreentype = "exclusive"})
        cam = require "camera".new()
        screenMode = "fs"
        dispatchWindowResize(love.graphics.getDimensions())
    end

    profiReportFont = lg.newFont("gfx/DroidSansMono.ttf", 20)
    linesbuf.show = false
end

function love.update(dt)
    menu:update(dt)
    timer:update(dt)
    linesbuf:update(dt)
end

local screenMode = "win" -- or "fs"
local to_resize = {nback, menu, pviewer, help}

function dispatchWindowResize(w, h)
    for k, v in pairs(to_resize) do
        if v["resize"] then v:resize(w, h) end
    end
end

function stopProfiling()
    if profiStartTime then
        local res = love.timer.getTime() - profiStartTime

        profi:stop()
        local fname = "profile_report.txt"
        profi:writeReport(fname)
        profiReportText = nil
        profiReportText = lg.newText(profiReportFont)
        profiReportHeight = 0
        local maxIndex = 0
        local x, y = 0, 0 -- FIXME а если захочется отобразить в других координатах?
        local i = 5
        for line in io.lines(fname) do
            if i < 0 then
                maxIndex = profiReportText:add(line, x, y)
                y = y + profiReportFont:getHeight()
                profiReportHeight = profiReportHeight + profiReportFont:getHeight()
            else
                i = i - 1
            end
        end
        -- выбираю максимальную ширину строки и сохраняю ее в переменной
        profiReportWidth = 0
        for i = 1, maxIndex do
            local w = profiReportText:getWidth(i)
            profiReportWidth = w > profiReportWidth and w or profiReportWidth
        end
    end

    return res or 0
end

function drawProfilingReport()
    if profiReportText then
        profiCam:attach()
        lg.setColor{0.1, 0.1, 0.1}
        lg.rectangle("fill", 0, 0, profiReportWidth, profiReportHeight)
        lg.setColor{1, 1, 1}
        lg.draw(profiReportText)
        profiCam:detach()
    end
end

function startProfiling()
    profi:start("once")
    profiStartTime = love.timer.getTime()
end

function bindKeys()
    local kc = keyconfig
    kc.bindKeyPressed("startprofi", {"9"}, function()
        startProfiling()
        linesbuf:push(1, "profiler started.")
    end, "start program profiling.")
    kc.bindKeyPressed("stopprofi", {"0"}, function()
        local time = stopProfiling()
        linesbuf:push(1, "profiler stoped. gathered for %d seconds.", time)
    end, "stop program profiling.")
    kc.bindKeyPressed("dbg", {"d", "lctrl"}, function()
        debug.debug()
    end, "Start debugger.")
    kc.bindKeyPressed("savehistory", {"s", "lctrl"}, function()
        nback:save_to_history()
    end, "save statistic file in history file.")
    kc.bindKeyPressed("changescreenmode", {"return", "lalt"}, function()
        -- код дерьмовый, но работает
        if screenMode == "fs" then
            love.window.setMode(800, 600, {fullscreen = false}) screenMode = "win"
            dispatchWindowResize(love.graphics.getDimensions())
        else
            love.window.setMode(0, 0, {fullscreen = true, fullscreentype = "exclusive"})
            screenMode = "fs"
            dispatchWindowResize(love.graphics.getDimensions())
        end
    end, "Turn to fullscreen or windowed mode.")
    kc.bindKeyPressed("screenshot", {"f12"}, function()
        make_screenshot()
    end, "Save screenshot in data folder.")
end

function love.keypressed(_, scancode)
    --if onAndroid then return end
    keyconfig.checkPressedKeys(scancode)
    menu:keypressed(_, scancode)
end

function love.keyreleased(key, scancode)
    menu:keyreleased(_, scancode)
end

fpsCounter = 0

function countAverageFPS()
    fpsSum = love.timer.getFPS()
    fpsCounter = fpsCounter + 1
end

function love.draw()
    cam:attach()
    menu:draw()
    cam:detach()
    drawProfilingReport()
    linesbuf:pushi("FPS %d", love.timer.getFPS())
    --linesbuf:pushi("average FPS for 30 seconds")
    linesbuf:draw()
    countAverageFPS()
    love.timer.sleep(0.01)
end

function love.wheelmoved(_, y)
    if y == 1 then
        profiCam:zoom(0.98)
    elseif y == -1 then
        profiCam:zoom(1.02)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if love.keyboard.isDown("lshift") and love.mouse.isDown("1") then
        profiCam:move(-dx, -dy)
    end
    menu:mousemoved(x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch)
    menu:mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    menu:mousereleased(x, y, button, istouch)
end
