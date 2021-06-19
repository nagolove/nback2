local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local os = _tl_compat and _tl_compat.os or os; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table
print('hello from begin of nback module')

require("Timer")
require("button")
require("common")
require("coroprocessor")
require("cmn")
require("drawstat")
require("layout")
require("menu-main")
require("nbtypes")
require("signal_quad_field")
require("snippets")
require("tiledbackground")


local inspect = require("inspect")
local colorConstants = require("colorconstants")
local g = love.graphics
local generator = require("generator")
local getTime = love.timer.getTime
local gr = love.graphics
local i18n = require("i18n")
local pallete = require("pallete")
local serpent = require("serpent")
local setupmenu = require("setupmenu")
local w, h = g.getDimensions()
local yield = coroutine.yield

 Nback = {Button = {}, }










































































































































local Nback_mt = {
   __index = Nback,
}

local fonts = require("fonts")

local nbackSelf = {
   dim = 8,
   cellWidth = 100,
   currentSig = 1,
   sigCount = 8,
   level = 1,
   isRun = false,
   pauseTime = 2.0,
   canPress = false,
   showStatistic = false,
   fieldColor = shallowCopy(pallete.field),
   font = fonts.nback.font,
   buttonsFont = fonts.nback.buttons,
   centralFont = fonts.nback.central,
   border = 3,
   mode = "quad",
}

function Nback.new()
   local self = deepcopy(nbackSelf)

   return setmetatable(self, Nback_mt)
end

local function makeFalseArray(len)
   local ret = {}
   for _ = 1, len do
      ret[#ret + 1] = false
   end
   return ret
end

function Nback:buildLayout()
   local screen = makeScreenTable()
   screen.left, screen.center, screen.right = 
   splitv(screen, 0.2, 0.6, 0.2)
   screen.leftTop, screen.leftMiddle, screen.leftBottom = 
   splith(screen.left, 0.2, 0.4, 0.4)
   screen.rightTop, screen.rightMiddle, screen.rightBottom = 
   splith(screen.right, 0.2, 0.4, 0.4)
   screen.leftTop, screen.leftMiddle, screen.leftBottom = 
   shrink(screen.leftTop, self.border),
   shrink(screen.leftMiddle, self.border),
   shrink(screen.leftBottom, self.border)
   screen.rightTop, screen.rightMiddle, screen.rightBottom = 
   shrink(screen.rightTop, self.border),
   shrink(screen.rightMiddle, self.border),
   shrink(screen.rightBottom, self.border)
   screen.center = shrink(screen.center, self.border)

   self.layout = screen

end

local function genMapByDim(d)
   local t = {}
   for _ = 1, d do
      table.insert(t, {})
      local p = t[#t]
      for _ = 1, d do
         table.insert(p, 0)
      end
   end
   return t
end

function Nback:start()
   print("nback:start()")
   local q = pallete.field


   self.timer:tween(3, self, { fieldColor = { q[1], q[2], q[3], 1 } }, "linear")
   self.written = false
   self.pause = false
   self.map = genMapByDim(self.dim)

   self.signals = generator.generateAll(
   self.sigCount,
   self.level,
   self.dim,
   #self.signalView.sounds,
   self.map)



   self.currentSig = 1
   self.timestamp = love.timer.getTime() - self.pauseTime
   self.showStatistic = false


   local signalsCount = #self.signals.pos
   self.pressed = {
      pos = makeFalseArray(signalsCount),
      color = makeFalseArray(signalsCount),
      form = makeFalseArray(signalsCount),
      sound = makeFalseArray(signalsCount),
   }




   self.stopppedSignal = 0
   self.start_pause_rest = 3
   self.start_pause = true


   local delay = 1
   self.timer:every(delay,
   function()
      self.start_pause_rest = self.start_pause_rest - 1
   end,
   self.start_pause_rest, function()
      self.start_pause = false
      self.isRun = true

      self.startTime = love.timer.getTime()
   end,
   "notag")


   if ON_ANDROID or not USE_KEYBOARD then
      self:initButtons()
   end
end

function Nback:enter()

   self.fieldColor[4] = 0.2

   print("nback:enter()")

   restoreUI(self.uiState)
end

function Nback:leave()
   print("nback:leave()")
   self.showStatistic = false
   self.uiState = storeUI()
end


local fragmentCode = [[
extern float time;
vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
    vec4 pixel = Texel(image, uvs);
    //float av = (pixel.r + pixel.g + pixel.b) / time;
    color.a = time;
    //return pixel * color;
    return pixel * color;
}
]]

function Nback:initShaders()
   self.shader = g.newShader(fragmentCode)
end


function Nback:createSetupMenu()


   local nbackLevel = self.level



   local maxLevel = 5

   local dim = 5


   local expositionList = { "1", "2", "3", "4", "5", "6" }
   local activeExpositionItem = 2

   local parameterColor = { 0, 0.9, 0 }

   self.setupmenu = setupmenu.new(fonts.nback.setupmenu, pallete.signal)


   self.setupmenu:addItem({
      oninit = function()
         return { i18n("setupMenu.start") }
      end,
      onselect = function()
         self.level = nbackLevel
         self.dim = dim

         self:resize(w, h)
         self.pauseTime = tonumber(expositionList[activeExpositionItem])
         self.setupmenu.freeze = true
         self:start()
         self.setupmenu.freeze = false
      end, })


   self.setupmenu:addItem({
      oninit = function()

         print('count', tonumber(expositionList[activeExpositionItem]))
         local fullStr = i18n("setupMenu.expTime_plural", {
            count = tonumber(expositionList[activeExpositionItem]),
         })




























         print("fullStr = ", fullStr)

         local part1, _, part2 = string.match(fullStr, "(.+)(%d)(.+)")

         return { pallete.signal, part1, parameterColor,
expositionList[activeExpositionItem], pallete.signal, part2, },
         activeExpositionItem == 1,
         activeExpositionItem == #expositionList
      end,

      onleft = function()
         if activeExpositionItem - 1 >= 1 then
            activeExpositionItem = activeExpositionItem - 1
         end
         local fullStr = i18n("setupMenu.expTime_plural", { count = tonumber(expositionList[activeExpositionItem]) })
         local part1, _, part2 = string.match(fullStr, "(.+)(%d)(.+)")
         return { pallete.signal, part1, parameterColor,
expositionList[activeExpositionItem], pallete.signal, part2, },
         activeExpositionItem == 1,
         activeExpositionItem == #expositionList
      end,

      onright = function()
         if activeExpositionItem + 1 <= #expositionList then
            activeExpositionItem = activeExpositionItem + 1
         end
         local fullStr = i18n("setupMenu.expTime_plural", { count = tonumber(expositionList[activeExpositionItem]) })
         local part1, _, part2 = string.match(fullStr, "(.+)(%d)(.+)")

         return { pallete.signal, part1, parameterColor,
expositionList[activeExpositionItem], pallete.signal, part2, },
         activeExpositionItem == 1,
         activeExpositionItem == #expositionList
      end, })


   self.setupmenu:addItem({
      oninit = function()
         return { pallete.signal, i18n("setupMenu.diffLevel"),
parameterColor, tostring(nbackLevel), },
         nbackLevel == 1,
         nbackLevel == maxLevel
      end,

      onleft = function()
         if nbackLevel - 1 >= 1 then nbackLevel = nbackLevel - 1 end
         return { pallete.signal, i18n("setupMenu.diffLevel"), parameterColor,
tostring(nbackLevel), },
         nbackLevel == 1,
         nbackLevel == maxLevel
      end,

      onright = function()
         if nbackLevel + 1 <= maxLevel then nbackLevel = nbackLevel + 1 end
         return { pallete.signal, i18n("setupMenu.diffLevel"), parameterColor,
tostring(nbackLevel), },
         nbackLevel == 1,
         nbackLevel == maxLevel
      end, })




























end

















function Nback:init(saveName)
   readSettings()
   self.volume = SETTINGS.volume
   love.audio.setVolume(SETTINGS.volume)
   self.saveName = saveName
   self.timer = require("Timer").new()

   if self.mode == "quad" then
      self.signalView = require("signal_quad_field").new(self.cellWidth, "alphabet")
   elseif self.mode == "hex" then
      error("not implemented")
      w, h = gr.getDimensions()
      self.map = {
         { 1, 1, 1 },
         { 1, 1, 0 },
         { 1, 1, 1 },
      }






   end

   self:createSetupMenu()
   self:resize(w, h)
   self:initShaders()

   self.uiState = storeUI()
end

function Nback:initShadersTimer()
   self.shaderTimer = 0
   self.shaderTimeEnabled = true
   self.timer:during(2, function(dt, _, _)

      local delta = 0.4 * dt
      if self.shaderTimer + delta <= 1 then
         self.shaderTimer = self.shaderTimer + delta
      end
   end,
   function()
      self.shaderTimeEnabled = false
   end)
end

function Nback:processSignal()
   local time = love.timer.getTime()
   if (time - self.timestamp >= self.pauseTime) then
      self.timestamp = time

      self.currentSig = self.currentSig + 1
      self.canPress = true



      self.figureAlpha = 0.1

      local tween_time = self.pauseTime / 2
      print("tween_time", tween_time)
      print("time delta = " .. self.pauseTime - tween_time)
      local after = self.pauseTime - tween_time - 0.1

      print("after", after)


      self.timer:tween(self.pauseTime / 3, self, { figure_alpha = 1 }, "out-linear")

      self.timer:after(after, function()
         print("figureAlpha before", self.figureAlpha)
         print("tween_time", tween_time)
         self.timer:tween(tween_time, self, { figure_alpha = 0 }, "out-linear")
         print("figure_alpha after", self.figureAlpha)
      end)

      colprint(inspect(self.signals.sound[self.currentSig]))
      self.signalView:play(self.signals.sound[self.currentSig])
   end
end

local function drawButtonCapture(button, nback)
   g.setColor({ 0, 0, 0 })
   g.setFont(nback.buttonsFont)
   g.printf(button.title, button.textx, button.texty, button.w, "center")
end

local drawButton = function(button, nback)


   local ok, errmsg = pcall(function()

      local ret
      repeat
         local oldwidth = g.getLineWidth()
         g.setColor(pallete.buttonColor)
         g.rectangle("fill", button.x, button.y, button.w, button.h, 6, 6)
         g.setColor({ 0, 0, 0 })
         g.setLineWidth(2)
         g.rectangle("line", button.x, button.y, button.w, button.h, 6, 6)

         drawButtonCapture(button, nback)
         g.setLineWidth(oldwidth)
         ret = yield()
      until ret == "exit"

   end)

   if not ok then
      error(errmsg)
   end
end

local drawButtonClicked = function(button, nback)


   local ok, errmsg = pcall(function()

      local btnColor = shallowCopy(pallete.buttonColor)

      local ret
      local time = getTime()
      local alphaDelta = 0.05

      repeat
         local now = getTime()
         local diff = now - time
         if diff > 0.04 then
            if btnColor[4] > 0.1 then
               btnColor[4] = btnColor[4] - alphaDelta
            else
               break
            end
         end

         local oldwidth = g.getLineWidth()
         g.setColor(btnColor)
         g.rectangle("fill", button.x, button.y, button.w, button.h, 6, 6)
         g.setColor({ 0, 0, 0 })
         g.setLineWidth(2)
         g.rectangle("line", button.x, button.y, button.w, button.h, 6, 6)

         drawButtonCapture(button, nback)
         g.setLineWidth(oldwidth)

         ret = yield()
      until ret == "exit"

      if ret == "exit" then
         return
      end

      repeat
         local now = getTime()
         local diff = now - time
         if diff > 0.04 then
            if btnColor[4] < pallete.buttonColor[4] then

               btnColor[4] = btnColor[4] + alphaDelta
            else
               nback.processor:push(button.coroName, drawButton, button, nback)
               break
            end
         end

         local oldwidth = g.getLineWidth()
         g.setColor(btnColor)
         g.rectangle("fill", button.x, button.y, button.w, button.h, 6, 6)
         g.setColor({ 0, 0, 0 })
         g.setLineWidth(2)
         g.rectangle("line", button.x, button.y, button.w, button.h, 6, 6)

         drawButtonCapture(button, nback)
         g.setLineWidth(oldwidth)

         ret = yield()
      until ret == "exit"

   end)

   if not ok then
      error(errmsg)
   end
end

function Nback:initButtons()
   self.buttons = {}


   table.insert(self.buttons, {
      x = self.layout.leftTop.x,
      y = self.layout.leftTop.y,
      w = self.layout.leftTop.w,
      h = self.layout.leftTop.h,
      title = i18n("quitBtn"),
      coroName = "quitBtn",
      ontouch = function()
         mainMenu:goBack()
      end, })


   table.insert(self.buttons, {
      x = self.layout.rightTop.x,
      y = self.layout.rightTop.y,
      w = self.layout.rightTop.w,
      h = self.layout.rightTop.h,
      title = i18n("settingsBtn"),
      coroName = "settingsBtn",
      ontouch = function()

         writeSettings()
         love.event.quit()
      end, })


   table.insert(self.buttons, {
      x = self.layout.leftMiddle.x,
      y = self.layout.leftMiddle.y,
      w = self.layout.leftMiddle.w,
      h = self.layout.leftMiddle.h,
      title = i18n("sound"),
      coroName = "soundBtn",
      ontouch = function()
         if self.isRun then
            self:check("sound")
         end
      end, })


   table.insert(self.buttons, {
      x = self.layout.rightMiddle.x,
      y = self.layout.rightMiddle.y,
      w = self.layout.rightMiddle.w,
      h = self.layout.rightMiddle.h,
      title = i18n("pos"),
      coroName = "posBtn",
      ontouch = function()
         if self.isRun then
            self:check("pos")
         end
      end, })


   table.insert(self.buttons, {
      x = self.layout.leftBottom.x,
      y = self.layout.leftBottom.y,
      w = self.layout.leftBottom.w,
      h = self.layout.leftBottom.h,
      title = i18n("form"),
      coroName = "formBtn",
      ontouch = function()
         if self.isRun then
            self:check("form")
         end
      end, })


   table.insert(self.buttons, {
      x = self.layout.rightBottom.x,
      y = self.layout.rightBottom.y,
      w = self.layout.rightBottom.w,
      h = self.layout.rightBottom.h,
      title = i18n("color"),
      coroName = "colorBtn",
      ontouch = function()
         if self.isRun then
            self:check("color")
         end
      end, })

   self:setupButtonsTextPosition()

   for _, v in ipairs(self.buttons) do
      self.processor:push(v.coroName, drawButton, v, self)

   end






end

function Nback:setupButtonsTextPosition()
   for _, v in ipairs(self.buttons) do
      v.textx = v.x
      v.texty = v.y + (v.h / 2 - self.font:getHeight() / 2)
   end
end

function Nback:drawButtons()


   if not self.buttons then return end

   local oldwidth = g.getLineWidth()
   for _, v in ipairs(self.buttons) do
      g.setColor(pallete.buttonColor)
      g.rectangle("fill", v.x, v.y, v.w, v.h, 6, 6)
      g.setColor({ 0, 0, 0 })
      g.setLineWidth(2)
      g.rectangle("line", v.x, v.y, v.w, v.h, 6, 6)

      g.setColor({ 0, 0, 0 })
      g.setFont(self.font)
      g.printf(v.title, v.textx, v.texty, v.w, "center")
   end
   g.setLineWidth(oldwidth)
end

local function drawTouches()
   local touches = love.touch.getTouches()
   for _, id in ipairs(touches) do
      local x, y = love.touch.getPosition(id)
      g.setColor({ 0, 0, 0 })
      g.circle("fill", x, y, 20)
   end
end

function Nback:draw()
   love.graphics.clear(pallete.background)










   if self.isRun then
      if self.start_pause then
         tiledback:draw(0.3)
         self:drawField()
         self:printStartPause()
      else
         tiledback:draw(0.3)

         if self.mode == "quad" then
            self:drawField()
         elseif self.mode == "hex" then
            error("not implemented")

         end

         if __DEBUG__ then

         end

         self:drawActiveSignal()


      end
   else
      if self.showStatistic then
         tiledback:draw(0.3)
         self.statisticRender:draw()
      else
         tiledback:draw(0.3)
         self.setupmenu:draw()
      end
   end

   drawTouches()

   if USE_KEYBOARD then

   end






end

function Nback:checkTouchButtons(x, y)
   if self.buttons then
      for _, v in ipairs(self.buttons) do
         if pointInRect(x, y, v.x, v.y, v.w, v.h) then
            v.ontouch()
            self.processor:sendMessage(v.coroName, "exit")
            self.processor:push(v.coroName, drawButtonClicked, v, self)
         end
      end
   end
end

function Nback:processTouches()
   local touches = love.touch.getTouches()
   for _, id in ipairs(touches) do
      local x, y = love.touch.getPosition(id)
      self:checkTouchButtons(x, y)
   end
end

function Nback:isRoundFinished()
   return self.currentSig < #self.signals.pos
end

function Nback:update(dt)

   self.timer:update(dt)
   self.processor:update()

   if self.pause or self.start_pause then
      self.timestamp = love.timer.getTime() - self.pauseTime



      return
   end

   if ON_ANDROID then
      self:processTouches()
   end

   if self.isRun then
      if not self:isRoundFinished() then
         self:processSignal()
      else
         self:stop()
      end
   else
      if not self.showStatistic then
         self.setupmenu:update(dt)
      end
   end
end

function Nback:save_to_history()
   if self.written then
      return
   else
      self.written = true
   end

   local history = {}
   local ok
   local data, _ = love.filesystem.read(self.saveName)
   if data ~= nil then
      ok, history = serpent.load(data), { History }

      if not ok then
         return
      end
   end
   print("nback:save_to_history()")

   os.setlocale("C")
   table.insert(history, { date = os.date("*t"),
signals = self.signals,
pressed = self.pressed,
level = self.level,
pause_time = self.pauseTime,


   })
   love.filesystem.write(self.saveName, serpent.dump(history))
   collectgarbage()
end

function Nback:stop(byescape)
   print("stop")
   local q = pallete.field

   self.timer:tween(2, self.fieldColor, { q[1], q[2], q[3], 0.1 }, "linear")

   self.isRun = false
   self.showStatistic = true


   if self.signals and self.signals.pos then
      self.stopppedSignal = self.currentSig
   end

   print("byescape", byescape)
   if not byescape then
      local duration = love.timer.getTime() - self.startTime
      self.durationMin = math.floor(duration / 60)
      self.durationSec = duration - self.durationMin * 60
      print(string.format("durationMin %f, durationSec %f", self.durationMin, self.durationSec))


      if self.signals and self.currentSig == #self.signals.pos then
         self:save_to_history()
      end

      self.statisticRender = require("drawstat").new({
         signals = self.signals,
         pressed = self.pressed,
         level = self.level,
         pause_time = self.pauseTime,

         x0 = self.x0,
         y0 = self.y0,
         font = self.font,
         durationMin = self.durationMin,
         durationSec = self.durationSec,
         buttons = true,
      })
   end
end

function Nback:quit(byescape)
   self.timer:destroy()
   self:stop(byescape)
   SETTINGS.volume = self.volume
   SETTINGS.level = self.level
   SETTINGS.pause_time = self.pauseTime
   SETTINGS.dim = self.dim
   writeSettings()
   mainMenu:goBack()
end

function Nback:keyreleased(scancode)

   if not self.isRun and not self.showStatistic then
      if scancode == "left" or scancode == "h" then
         self.setupmenu:leftReleased()
      elseif scancode == "right" or scancode == "l" then
         self.setupmenu:rightReleased()
      end
   end
end

function Nback:keypressed(scancode)

   if not USE_KEYBOARD then
      return
   end

   if self.isRun then
      if scancode == "a" then
         self:check("sound")


      elseif scancode == "f" then
         self:check("color")


      elseif scancode == "j" then
         self:check("form")


      elseif scancode == ";" then
         self:check("pos")


      end
   else
      if not self.showStatistic then
         if scancode == "space" or scancode == "return" then
            print("select")
            self.setupmenu:select()
         elseif scancode == "up" or scancode == "k" then
            self.setupmenu:scrollUp()
         elseif scancode == "down" or scancode == "j" then
            self.setupmenu:scrollDown()
         elseif scancode == "left" or scancode == "h" then
            self.setupmenu:leftPressed()
         elseif scancode == "right" or scancode == "l" then
            self.setupmenu:rightPressed()
         end
      end
   end
   if scancode == "-" then
      self:loverVolume()
   elseif scancode == "=" then
      self:raiseVolume()
   end
   if scancode == "escape" or scancode == "achome" then
      if self.isRun then
         print("stop by escape")
         self:stop()
      else
         self:quit(true)
      end
   end
end

local soundVolumeStep = 0.05

function Nback:loverVolume()
   if self.volume - soundVolumeStep >= 0 then
      self.volume = self.volume - soundVolumeStep
      love.audio.setVolume(self.volume)
   end
end

function Nback:raiseVolume()
   if self.volume + soundVolumeStep <= 1 then
      self.volume = self.volume + soundVolumeStep
      love.audio.setVolume(self.volume)
   end
end


function Nback:check(signalType)

   if not self.isRun then
      return
   end

   local signals = (self.signals)[signalType]
   local cmp = function(a, b)
      return a == b
   end
   if signalType == "pos" then
      cmp = isPositionEqual
   end

   self.pressed[signalType][self.currentSig] = true
   if self.currentSig - self.level > 1 then
      if cmp(signals[self.currentSig], signals[self.currentSig - self.level]) then

         if self.canPress then
            print(signalType .. " hit!")
            self.canPress = false
         end
      end
   end
end

function Nback:resize(neww, newh)
   print(string.format("resized to %d * %d", neww, newh))
   self:buildLayout()

   w, h = neww, newh


   self.cellWidth = math.ceil(self.layout.center.h / self.dim)

   self.bhupur_h = self.cellWidth * self.dim
   self.x0, self.y0 = self.layout.center.x + (self.layout.center.w - self.layout.center.h) / 2, self.layout.center.y
   self.processor = require("coroprocessor").new()

   if self.signalView then
      self.signalView:setCorner(self.x0, self.y0)
      self.signalView:resize(self.cellWidth)
   end

   if self.statisticRender then
      self.statisticRender:buildLayout(self.border)
   end
end

function Nback:inspectSignals()















end

function Nback:fillLinesbuf()
   if not self.signalsInspected then

   end
   if self.signals then






   end







end

function Nback:drawActiveSignal()
   print('Nback:drawActiveSignal()')
   local pos = self.signals.pos[self.currentSig]
   print("self.signals", inspect(self.signals))
   print("self.signals.pos", inspect(self.signals.pos[self.currentSig]))
   print('pos', inspect(pos))

   local x, y = pos.x, pos.y

   print('self.current_sig', inspect(self.currentSig))
   print('self.signals.color', inspect(self.signals.color))
   print('colorConstants.colors', inspect(colorConstants.colors))
   print('hmm', inspect(self.signals.color[self.currentSig]))

   local sig_color = colorConstants.colors[self.signals.color[self.currentSig]]
   print('sig_color', sig_color)

   if self.figureAlpha then
      sig_color[4] = self.figureAlpha
   else
      print("no self.figure_alpha")
   end

   local curtype = self.signals.form[self.currentSig]
   self.signalView:draw(x, y, curtype, sig_color)
end

function Nback:drawField()
   local field_h = self.dim * self.cellWidth
   g.setColor(self.fieldColor)
   local oldwidth = g.getLineWidth()
   g.setLineWidth(2)
   for i = 0, self.dim do

      g.line(self.x0, self.y0 + i * self.cellWidth,
      self.x0 + field_h, self.y0 + i * self.cellWidth)

      g.line(self.x0 + i * self.cellWidth,
      self.y0, self.x0 + i * self.cellWidth, self.y0 + field_h)
   end
   g.setLineWidth(oldwidth)
end


function Nback:printStartPause()
   print('Nback:printStartPause')
   local central_text = i18n("waitFor", { self.start_pause_rest })
   g.setFont(self.centralFont)
   g.setColor(pallete.signal)
   local x = (w - self.centralFont:getWidth(central_text)) / 2
   local y = self.y0 + (self.dim - 1) * self.cellWidth
   g.print(central_text, x, y)
end

function Nback:mousemoved(x, y, dx, dy, istouch)
   if not self.isRun and not self.showStatistic then
      self.setupmenu:mousemoved(x, y, dx, dy, istouch)
   end
end

function Nback:mousereleased(x, y, btn)
   if self.statisticRender then
      self.statisticRender:mousereleased(x, y, btn)
   end
end

function Nback:mousepressed(x, y, btn, istouch)
   if not self.isRun and not self.showStatistic then
      self.setupmenu:mousepressed(x, y, btn, istouch)
   elseif self.statisticRender then
      self.statisticRender:mousepressed(x, y, btn, istouch)
   elseif not ON_ANDROID then
      self:checkTouchButtons(x, y)
   end
end












nback = Nback.new()
print('hello from end of nback module')
