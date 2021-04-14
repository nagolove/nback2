require("nback")
require("menu")
require("pviewer")
require("help")
require("tiledbackground")







local function initGlobals()
   menu = require("menu").new()

   help = require("help").new()
   nback = require("nback").new()
   tiledback = require("tiledbackground"):new()
end

return {
   initGlobals = initGlobals,
}
