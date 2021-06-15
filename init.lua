local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local os = _tl_compat and _tl_compat.os or os; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; love.filesystem.setRequirePath(love.filesystem.getRequirePath() .. ";?.lua;?/init.lua;scenes/nback2/?.lua")

require("love")
require("nbtypes")
require("common")
require("globals")
require("pviewer")
require("help")
require("menu")
require("languageselector")








local inspect = require("inspect")



local timer = require("Timer").new()

local keyconfig = require("keyconfig")
local i18n = require("i18n")
local linesbuf = require("kons").new()
local cam = require("camera").new()
local profiCam = require("camera").new()



local screenMode = "win"
local Resizable = {}



local to_resize = {}


function dispatchWindowResize(neww, newh)
   for _, v in ipairs(to_resize) do
      if v and v.resize then v:resize(neww, newh) end
   end
end

local function quit()
   settings.firstRun = false
   writeSettings()
end

function loadLocales()
   local files = love.filesystem.getDirectoryItems("locales")
   print("locale files", inspect(files))
   for _, v in ipairs(files) do
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

function bindKeys()
   local kc = keyconfig


   kc.bind("keypressed", { key = "2" }, function(sc)
      linesbuf.show = not linesbuf.show
      return false, sc
   end, "show or hide debug output", "linesbufftoggle")



































end

function subInit()
   bindKeys()


   nback:init(SAVE_NAME)
   pviewer:init(SAVE_NAME)

   print('menu2', menu2)


   print('menu', menu)
   help:init()
   menu:init()











end

local function init()
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
      languageSelector = require("languageselector").new()
   end

   setupLocale(locale)
   math.randomseed(os.time())
   love.window.setTitle("nback")


   subInit()

   table.insert(to_resize, nback)
   table.insert(to_resize, menu)
   table.insert(to_resize, pviewer)
   table.insert(to_resize, help)
   table.insert(to_resize, languageSelector)
   table.insert(to_resize, tiledback)

   if onAndroid then
      love.window.setMode(0, 0, { fullscreen = true })

      cam = require("camera").new()
      screenMode = "fs"
      dispatchWindowResize(love.graphics.getDimensions())
   end


   linesbuf.show = false
end

function update(dt)
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
   linesbuf:update()
end
























































local function keypressed(scancode)

   if languageSelector and languageSelector.keypressed then
      languageSelector:keypressed(scancode)
   else
      keyconfig.keypressed(scancode)
      menu:keypressed(scancode)
   end
end

local function keyreleased(key)
   menu:keyreleased(key)
end

local function draw()
   if languageSelector then
      tiledback:draw()
      languageSelector:draw()
   else
      cam:attach()
      menu:draw()
      cam:detach()


   end
   linesbuf:pushi("FPS %d", love.timer.getFPS())
   linesbuf:draw()
   love.timer.sleep(0.01)
end

local function wheelmoved(_, y)
   if y == 1 then
      profiCam:zoom(0.98)
   elseif y == -1 then
      profiCam:zoom(1.02)
   end
end

local function mousemoved(x, y, dx, dy, istouch)
   if love.keyboard.isDown("lshift") and love.mouse.isDown(1) then
      profiCam:move(-dx, -dy)
   end
   if languageSelector then
      languageSelector:mousemoved(x, y, dx, dy, istouch)
   else
      menu:mousemoved(x, y, dx, dy, istouch)
   end
end

local function mousepressed(x, y, button, istouch)
   if languageSelector then
      languageSelector:mousepressed(x, y, button, istouch)
   else
      menu:mousepressed(x, y, button, istouch)
   end
end

local function mousereleased(x, y, button, istouch)
   if languageSelector then

   else
      menu:mousereleased(x, y, button, istouch)
   end
end

local function touchpressed(id, x, y, dx, dy, pressure)
   if languageSelector then
      languageSelector:touchpressed(id, x, y)
   else
      menu:touchpressed(id, x, y, dx, dy, pressure)
   end
end

local function touchreleased(id, x, y, dx, dy, pressure)
   if languageSelector then
      languageSelector:touchreleased(id, x, y)
   else
      menu:touchreleased(id, x, y, dx, dy, pressure)
   end
end

local function touchmoved(id, x, y, dx, dy, pressure)
   if languageSelector then
      languageSelector:touchmoved(id, x, y)
   else
      menu:touchmoved(id, x, y, dx, dy, pressure)
   end
end

return {
   init = init,
   quit = quit,
   draw = draw,

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