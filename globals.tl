--require "nback"
require "menu"
require "pviewer"
require "help"

global menu: Menu
global pviewer: Pviewer
global help: Help
--global nback: Nback

local function initGlobals()
    menu = require "menu".new()
    pviewer = require "pviewer".new()
    help = require "help".new()
    --nback = require "nback".new()
end

return {
    initGlobals = initGlobals,
}
