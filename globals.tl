--require "menu"
--require "pviewer"
--require "help"
--require "tiledbackground"
require "nback"

--global pviewer: Pviewer
--global help: Help

local function initGlobals()
    --menu = require "menu".new()
    --help = require "help".new()
    --nback = Nback.new()
    --tiledback = require "tiledbackground".new()
end

return {
    initGlobals = initGlobals,
}
--]]
