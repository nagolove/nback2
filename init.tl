love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";?.lua;?/init.lua;scenes/nback3/?.lua")

require "globals"
require "menu-main"
require "common"
require "help"
require "languageselector"
require "love"
require "nbtypes"
require "pviewer"
require "tiledbackground"

--preventiveFirstRun = false
--onAndroid = true

--require "common"

--local profi = require "ProFi"
--local lg = love.graphics
local inspect = require "inspect"
--local pallete = require "pallete"
--local splash = require "splash"
--local timer = require "libs/Timer"()
local timer = require "Timer".new()

local keyconfig = require "keyconfig"
local i18n = require "i18n"
local linesbuf = require "kons".new()
local cam = require "camera".new()
local profiCam = require "camera".new()

--local fonts = require "fonts"

local screenMode = "win" -- or "fs"
local type Resizable = record
    resize: function(any, number, number)
end
--local to_resize: {any} = {}
local to_resize: {Resizable} = {}
global languageSelector: LanguageSelector

function dispatchWindowResize(neww: number, newh: number)
    for _, v in ipairs(to_resize) do
        if v and v.resize then v:resize(neww, newh) end
    end
end

local function quit()
    SETTINGS.firstRun = false
    writeSettings()
end

function loadLocales()
    local files = love.filesystem.getDirectoryItems(SCENEPREFIX .. "locales")
    print("locale files", inspect(files))
    for _, v in ipairs(files) do 
        i18n.loadFile("locales/" .. v, function(path: string): any
            local chunk, errmsg = love.filesystem.load(SCENEPREFIX .. path)
            if not chunk then
                error(errmsg)
            end
            return chunk
        end) 
    end
end

function setupLocale(locale: string)
    print("setupLocale", locale)
    i18n.setLocale(locale)
end

function bindKeys()
    local kc = keyconfig

    --local Shortcut = KeyConfig.Shortcut
    kc.bind("keypressed", { key = "2" }, function(sc: kc.Shortcut): boolean, kc.Shortcut
        linesbuf.show = not linesbuf.show 
        return false, sc
    end, "show or hide debug output", "linesbufftoggle")

    -- XXX сломано
    --kc.bindKeyPressed("startprofi", {"9"}, function()
        --startProfiling()
        --linesbuf:push(1, "profiler started.")
    --end, "start program profiling.")

    --kc.bindKeyPressed("stopprofi", {"0"}, function()
        --local time = stopProfiling()
        --linesbuf:push(1, "profiler stoped. gathered for %d seconds.", time)
    --end, "stop program profiling.")

    --kc.bindKeyPressed("dbg", {"d", "lctrl"}, function()
        --debug.debug()
    --end, "Start debugger.")

    --kc.bindKeyPressed("savehistory", {"s", "lctrl"}, function()
        --nback:save_to_history()
    --end, "save statistic file in history file.")

    --kc.bindKeyPressed("changescreenmode", {"return", "lalt"}, function()
        ---- код дерьмовый, но работает
        --if screenMode == "fs" then
            --love.window.setMode(1024, 768, {fullscreen = false}) screenMode = "win"
            --dispatchWindowResize(love.graphics.getDimensions())
        --else
            --love.window.setMode(0, 0, {fullscreen = true, fullscreentype = "exclusive"})
            --screenMode = "fs"
            --dispatchWindowResize(love.graphics.getDimensions())
        --end
    --end, "Turn to fullscreen or windowed mode.")

    --kc.bindKeyPressed("screenshot", {"f12"}, function()
        --make_screenshot()
    --end, "Save screenshot in data folder.")
end

local subInitCounter = 0

function subInit()
    bindKeys()
    --initGlobals()

    nback:init(SAVE_NAME)
    pviewer:init(SAVE_NAME)
    help:init()
    print('main menu', mainMenu)
    mainMenu:init()

    mainMenu:clear()
    mainMenu:addItem(i18n("mainMenu.play"), nback as MenuObject)
    mainMenu:addItem(i18n("mainMenu.viewProgress"), pviewer as MenuObject)
    mainMenu:addItem(i18n("mainMenu.help"), help as MenuObject)

    if not ON_ANDROID then
        mainMenu:addItem(i18n("mainMenu.exit"), function() love.event.quit() end as MenuObject)
    end

    subInitCounter = subInitCounter + 1
    --if subInitCounter > 1 then
        --error("Function 'subInit' called more than once.")
    --end
    print('subInitCounter', subInitCounter)
end

local function init()
    SETTINGS = readSettings()
    print('settings:', inspect(SETTINGS))
    loadLocales()

    -- TODO get cmd arg table for language changing
    print("arg", inspect(arg))
    local locale = "en"
    if arg[1] then
        locale = string.match(arg[1], "locale=(%S+)") or "en"
    end

    if SETTINGS.firstRun or PREVENTIVE_FIRST_RUN then
        languageSelector = require "languageselector".new()
    end

    setupLocale(locale)
    math.randomseed(os.time())
    love.window.setTitle("nback")
    --require "splash".init()
    
    subInit()
    
    table.insert(to_resize, nback as Resizable)
    table.insert(to_resize, mainMenu as Resizable)
    table.insert(to_resize, pviewer as Resizable)
    table.insert(to_resize, help as Resizable)
    table.insert(to_resize, languageSelector as Resizable)
    table.insert(to_resize, tiledback as Resizable)

    if ON_ANDROID then
        love.window.setMode(0, 0, {fullscreen = true})
        --love.window.setMode(0, 0, {fullscreen = true, fullscreentype = "exclusive"})
        cam = require "camera".new()
        screenMode = "fs"
        dispatchWindowResize(love.graphics.getDimensions())
    end

    --profiReportFont = fonts.profi
    linesbuf.show = false
end

function update(dt: number)
    if languageSelector then
        languageSelector:update(dt)
        if languageSelector.locale then
            setupLocale(languageSelector.locale)
            subInit()
            languageSelector = nil
        end
    else
        mainMenu:update(dt)
        timer:update(dt)
    end
    linesbuf:update()
end

--[[
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
--]]

--[[
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
--]]

--[[
function startProfiling()
    profi:start("once")
    profiStartTime = love.timer.getTime()
end
--]]

local function keypressed(scancode: string)
    --if onAndroid then return end
    if languageSelector and languageSelector.keypressed then
        languageSelector:keypressed(scancode)
    else
        keyconfig.keypressed(scancode)
        mainMenu:keypressed(scancode)
    end
end

local function keyreleased(key: string)
    mainMenu:keyreleased(key)
end

local function draw()
    if languageSelector then
        tiledback:draw()
        languageSelector:draw()
    else
        cam:attach()
        mainMenu:draw()
        cam:detach()
        --drawProfilingReport()
        --linesbuf:pushi("average FPS for 30 seconds")
    end
    linesbuf:pushi("FPS %d", love.timer.getFPS())
    linesbuf:draw()
    love.timer.sleep(0.01)
end

local function wheelmoved(_, y: number)
    if y == 1 then
        profiCam:zoom(0.98)
    elseif y == -1 then
        profiCam:zoom(1.02)
    end
end

local function mousemoved(x: number, y: number, dx: number, dy: number, istouch: boolean)
    if love.keyboard.isDown("lshift") and love.mouse.isDown(1) then
        profiCam:move(-dx, -dy)
    end
    if languageSelector then
        languageSelector:mousemoved(x, y, dx, dy, istouch)
    else
        mainMenu:mousemoved(x, y, dx, dy, istouch)
    end
end

local function mousepressed(x: number, y: number, button: number, istouch: boolean)
    if languageSelector then
        languageSelector:mousepressed(x, y, button, istouch)
    else
        mainMenu:mousepressed(x, y, button, istouch)
    end
end

local function mousereleased(x: number, y: number, button: number, istouch: boolean)
    if languageSelector then
        -- почему отлючено?
        --languageSelector:mousereleased(x, y, button, istouch)
    else
        mainMenu:mousereleased(x, y, button, istouch)
    end
end

local function touchpressed(id: number, x: number, y: number, dx: number, dy: number, pressure: number)
    if languageSelector then
        languageSelector:touchpressed(id, x, y)
    else
        mainMenu:touchpressed(id, x, y, dx, dy, pressure)
    end
end

local function touchreleased(id: number, x: number, y: number, dx: number, dy: number, pressure: number)
    if languageSelector then
        languageSelector:touchreleased(id as any, x, y)
    else
        mainMenu:touchreleased(id, x, y, dx, dy, pressure)
    end
end

local function touchmoved(id: number, x: number, y: number, dx: number, dy: number, pressure: number)
    if languageSelector then
        languageSelector:touchmoved(id as any, x, y)
    else
        mainMenu:touchmoved(id, x, y, dx, dy, pressure)
    end
end

return {
    init = init,
    quit = quit,
    draw = draw,
    --drawui = drawui,
    update = update,
    keypressed = keypressed,
    keyreleased = keyreleased,
    mousemoved = mousemoved,
    wheelmoved = wheelmoved, 
    mousereleased = mousereleased, 
    mousepressed = mousepressed, 
    touchpressed = touchpressed, 
    touchreleased = touchreleased,
    touchmoved = touchmoved,
}

