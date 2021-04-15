require("love")
local lg = love.graphics
local prefix = "scenes/nback2/"
return {
   help = {
      font = lg.newFont(prefix .. "gfx/DejaVuSansMono.ttf", 15),
      gooi = lg.newFont(prefix .. "gfx/DejaVuSansMono.ttf", 13),
   },
   profi = lg.newFont(prefix .. "gfx/DejaVuSansMono.ttf", 13),
   drawstat = {
      gooi = lg.newFont(prefix .. "gfx/DejaVuSansMono.ttf", 13),
   },
   pviewer = lg.newFont(prefix .. "gfx/DejaVuSansMono.ttf", 15),
   nback = {
      font = love.graphics.newFont(prefix .. "gfx/DejaVuSansMono.ttf", 25),
      buttons = love.graphics.newFont(prefix .. "gfx/DejaVuSansMono.ttf", 20),
      central = love.graphics.newFont(prefix .. "gfx/DejaVuSansMono.ttf", 42),
      setupmenu = lg.newFont(prefix .. "gfx/DejaVuSansMono.ttf", 30),
   },
   languageSelector = love.graphics.newFont(prefix .. "gfx/DejaVuSansMono.ttf", 25),
   menu = love.graphics.newFont(prefix .. "gfx/DejaVuSansMono.ttf", 32),
}
