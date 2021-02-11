--require "nback"
require "menu"
require "pviewer"
require "help"
require "tiledbackground"

global menu: Menu
global pviewer: Pviewer
global help: Help
global tiledback: TiledBackround
--global nback: Nback

local function initGlobals()
    menu = require "menu".new()
    pviewer = require "pviewer".new()
    help = require "help".new()
    --nback = require "nback".new()
    tiledback = require "tiledbackground":new()
end

return {
    initGlobals = initGlobals,
}
