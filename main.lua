__DEBUG__ = false
onAndroid = love.system.getOS() == "Android"
useKeyboard = true
preventiveFirstRun = true
--preventiveFirstRun = false
--onAndroid = true

require "common"

local profi = require "ProFi"
local lg = love.graphics
local inspect = require "libs/inspect"
local pallete = require "pallete"
local splash = require "splash"
local timer = require "libs/Timer"()

SETTINGS_FILENAME = "settings.lua"
SAVE_NAME = "nback-v0.4.lua"
keyconfig = require "keyconfig"
i18n = require "i18n"
linesbuf = require "kons".new()
cam = require "camera".new()
profiCam = require "camera".new()
tiledback = require "tiledbackground":new()

fonts = {
    help = {
        font = lg.newFont("gfx/DejaVuSansMono.ttf", 15),
        gooi = lg.newFont("gfx/DejaVuSansMono.ttf", 13),
    },
    profi = lg.newFont("gfx/DejaVuSansMono.ttf", 13),
    drawstat = {
        gooi = lg.newFont("gfx/DejaVuSansMono.ttf", 13),
    },
    pviewer = lg.newFont("gfx/DejaVuSansMono.ttf", 15),
    nback = {
        font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 25),
        buttons = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
        central = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 42),
        setupmenu = lg.newFont("gfx/DejaVuSansMono.ttf", 30),
    },
    languageSelector = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 25),
    menu = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 32),
}

local screenMode = "win" -- or "fs"
local to_resize = {}

function dispatchWindowResize(neww, newh)
    for k, v in pairs(to_resize) do
        if v and v.resize then v:resize(neww, newh) end
    end
end

function love.quit()
    settings.firstRun = false
    writeSettings()
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

function subInit()
    bindKeys()

    help = require "help".new()
    menu = require "menu".new()
    nback = require "nback".new()
    pviewer = require "pviewer".new()

    nback:init(SAVE_NAME)
    pviewer:init(SAVE_NAME)
    menu:init()
    help:init()

    menu:addItem(i18n("mainMenu.play"), nback)
    menu:addItem(i18n("mainMenu.viewProgress"), pviewer)
    menu:addItem(i18n("mainMenu.help"), help)
    if not onAndroid then
        menu:addItem(i18n("mainMenu.exit"), function() love.event.quit() end)
    end
end

function love.load(arg)
    settings = readSettings()
    print("SUUKA")
    print(inspect(settings))
    loadLocales()

    print("arg", inspect(arg))
    local locale = "en"
    if arg[1] then
        locale = string.match(arg[1], "locale=(%S+)") or "en"
    end

    if settings.firstRun or preventiveFirstRun then
        languageSelector = require "languageselector".new()
    end

    setupLocale(locale)
    math.randomseed(os.time())
    love.window.setTitle("nback")
    --require "splash".init()
    
    subInit()
    
    table.insert(to_resize, nback)
    table.insert(to_resize, menu)
    table.insert(to_resize, pviewer)
    table.insert(to_resize, help)
    table.insert(to_resize, languageSelector)
    table.insert(to_resize, tiledback)

    if onAndroid then
        love.window.setMode(0, 0, {fullscreen = true})
        --love.window.setMode(0, 0, {fullscreen = true, fullscreentype = "exclusive"})
        cam = require "camera".new()
        screenMode = "fs"
        dispatchWindowResize(love.graphics.getDimensions())
    end

    profiReportFont = fonts.profi
    linesbuf.show = false
end

function love.update(dt)
    if languageSelector then
        languageSelector:update(dt)
        if languageSelector.locale then
            setupLocale(languageSelector.locale)
            subInit()
            languageSelector = nil
        end
    else
        menu:update(dt)
        timer:update(dt)
    end
    linesbuf:update(dt)
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

    kc.bindKeyPressed("linesbufftoggle", {"2"}, function()
        linesbuf.show = not linesbuf.show 
    end, "show or hide debug output")

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
            love.window.setMode(1024, 768, {fullscreen = false}) screenMode = "win"
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
    if languageSelector and languageSelector.keypressed then
        languageSelector:keypressed(_, scancode)
    else
        keyconfig.checkPressedKeys(scancode)
        menu:keypressed(scancode, scancode)
    end
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
    if languageSelector then
        tiledback:draw()
        languageSelector:draw()
    else
        cam:attach()
        menu:draw()
        cam:detach()
        drawProfilingReport()
        --linesbuf:pushi("average FPS for 30 seconds")
        countAverageFPS()
    end
    linesbuf:pushi("FPS %d", love.timer.getFPS())
    linesbuf:draw()
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
    if languageSelector then
        languageSelector:mousemoved(x, y, dx, dy, istouch)
    else
        menu:mousemoved(x, y, dx, dy, istouch)
    end
end

function love.mousepressed(x, y, button, istouch)
    if languageSelector then
        languageSelector:mousepressed(x, y, button, istouch)
    else
        menu:mousepressed(x, y, button, istouch)
    end
end

function love.mousereleased(x, y, button, istouch)
    if languageSelector then
        languageSelector:mousereleased(x, y, button, istouch)
    else
        menu:mousereleased(x, y, button, istouch)
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if languageSelector then
        languageSelector:touchpressed(id, x, y, dx, dy, pressure)
    else
        menu:touchpressed(id, x, y, dx, dy, pressure)
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    if languageSelector then
        languageSelector:touchreleased(id, x, y, dx, dy, pressure)
    else
        menu:touchreleased(id, x, y, dx, dy, pressure)
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if languageSelector then
        languageSelector:touchmoved(id, x, y, dx, dy, pressure)
    else
        menu:touchmoved(id, x, y, dx, dy, pressure)
    end
end
