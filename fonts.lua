print('Fonts module loading..')

require("love")
require("globals")

local lg = love.graphics
local inspect = require("inspect")
local baseSize = 13

local t = {
   help = {
      font = lg.newFont(
      SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
      baseSize + 2),

      gooi = lg.newFont(
      SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
      baseSize),

   },
   profi = lg.newFont(
   SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
   baseSize),

   drawstat = {
      gooi = lg.newFont(
      SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
      baseSize),

   },
   pviewer = lg.newFont(
   SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
   baseSize + 2),

   nback = {
      font = love.graphics.newFont(
      SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
      baseSize + 12),

      buttons = love.graphics.newFont(
      SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
      baseSize + 7),

      central = love.graphics.newFont(
      SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
      baseSize + 29),

      setupmenu = lg.newFont(
      SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
      baseSize + 17),

   },
   languageSelector = love.graphics.newFont(
   SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
   baseSize + 12),

   menu = love.graphics.newFont(
   SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
   baseSize + 19),

}

local colors = require('ansicolors')
print('type(colors)', type(colors))
print('inspect(colors)', inspect(colors))


print('Fonts module loading done.')
return t
