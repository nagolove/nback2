require "nbtypes"

global SETTINGS_FILENAME = "settings.lua"
global SAVE_NAME = "nback-v0.4.lua"
global SCENEPREFIX = "scenes/nback3/"

global SETTINGS: Settings
global __DEBUG__ = false
global ON_ANDROID = love.system.getOS() == "Android"
global USE_KEYBOARD = true
global PREVENTIVE_FIRST_RUN = true

--require "menu"
--require "pviewer"
--require "help"
--require "tiledbackground"
--require "nback"

----global pviewer: Pviewer
----global help: Help

--local function initGlobals()
    ----menu = require "menu".new()
    ----help = require "help".new()
    ----nback = Nback.new()
    ----tiledback = require "tiledbackground".new()
--end

--return {
    --initGlobals = initGlobals,
--}
----]]
