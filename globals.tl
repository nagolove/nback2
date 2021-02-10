require "nback"
require "menu"
require "pviewer"
require "help"

global menu: Menu
global pviewer: Pviewer
global help: Help
global nback: Nback

local function initGlobals()
    global menu = require "menu".new()
    global pviewer = require "pviewer".new()
    global help = require "help".new()
    global nback = require "nback".new()
end

return {
    initGlobals = initGlobals,
}
