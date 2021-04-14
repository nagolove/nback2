local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string; require("love")
require("nbtypes")
require("layout")
require("cmn")
require("button")



local pallete = require("pallete")
local i18n = require("i18n")
local g = love.graphics

local LinkPoint = {}

 StatisticRenderData = {}










 StatisticRender = {InitData = {}, Info = {}, }









































local StatisticRender_mt = {
   __index = StatisticRender,
}

function StatisticRender:getHitQuadLineHeight()
   return self.rect_size + 12
end



function StatisticRender:drawLink(_, _, point1, point2)
   assert(type(point1) == "table")
   assert(type(point2) == "table")





































end

function StatisticRender:drawLinks(x, y, type)

   local eq_arr = self.signals.eq[type]

   local maxLinks = 1

   local pressed = self.pressed[type]

   local points = {}
   for k, _ in ipairs(pressed) do
      points[k] = {}
   end

   for k, _ in ipairs(pressed) do
      if eq_arr[k] then
         if not points[k][1] then
            points[k] = { {}, {} }
         end
         points[k][1][1] = k - self.level
         points[k][2][1] = k

         local leftIndex = math.floor(k - self.level)
         if leftIndex >= 1 and eq_arr[leftIndex] then
            points[k][1][2] = "right"
         end

         local rightIndex = math.floor(k + self.level)
         if rightIndex <= #pressed and eq_arr[rightIndex] then
            points[k][2][2] = "left"
         end



      end
   end



   for _, v in ipairs(points) do
      if v[1] and v[2] then
         self:drawLink(x, y, v[1], v[2])
      end
   end

   return maxLinks
end

function StatisticRender:drawBox(x, y, k, border)
   local rect_size = self.rect_size
   g.setColor(pallete.field)
   g.rectangle("line", x + rect_size * (k - 1), y, rect_size, rect_size)
   g.setColor(pallete.inactive)
   g.rectangle("fill", x + rect_size * (k - 1) + border, y + border, rect_size - border * 2, rect_size - border * 2)
end

function StatisticRender:drawHitBox(x, y, k, border)
   local rect_size = self.rect_size
   g.setColor(pallete.hit_color)
   g.rectangle("fill", x + rect_size * (k - 1) + border, y + border, rect_size - border * 2, rect_size - border * 2)
end

function StatisticRender:drawHitCirclesPair(x, y, k)
   local rect_size = self.rect_size
   local radius = 4
   g.setColor({ 0, 0, 0 })
   g.circle("fill", x + rect_size * (k - 1) + rect_size / 2, y + rect_size / 2, radius)

   g.setColor({ 1, 1, 1, 0.5 })
   g.circle("line", x + rect_size * ((k - self.level) - 1) + rect_size / 2, y + rect_size / 2, radius)
end



function StatisticRender:drawHitQuads(x, y, type, border)
   local eq_arr = self.signals.eq[type]

   for k, v in ipairs(self.pressed[type]) do
      self:drawBox(x, y, k, border)


      if v then
         self:drawHitBox(x, y, k, border)
      end


      if eq_arr[k] then
         self:drawHitCirclesPair(x, y, k)
      end
   end

   local maxLinks = self:drawLinks(x, y, type)
   return self:getHitQuadLineHeight() + maxLinks * 10
end


function processTouches()











end

function StatisticRender:update(dt)




   self.mainMenuBtn:update(dt)
end


function StatisticRender:printSignalType(x, y, signalType)
   local loc = i18n(signalType) or ""
   local str = loc .. "  "
   local strWidth = g.getFont():getWidth(str)
   g.setColor(pallete.statisticSignalType)
   g.print(str, x, y)
   g.setColor(pallete.percentFont)
   g.print(string.format("%.3f", self.percent[signalType]), x + strWidth, y)
end

function StatisticRender:drawHits(x, y)
   local dy = 0.
   g.setFont(self.font)
   self:printSignalType(x, y, "sound")
   y = y + self.fontHeight
   dy = self:drawHitQuads(x, y, "sound", self.border)
   y = y + dy

   self:printSignalType(x, y, "color")
   y = y + self.fontHeight
   dy = self:drawHitQuads(x, y, "color", self.border)
   y = y + dy

   self:printSignalType(x, y, "form")
   y = y + self.fontHeight
   dy = self:drawHitQuads(x, y, "form", self.border)
   y = y + dy

   self:printSignalType(x, y, "pos")
   y = y + self.fontHeight
   self:drawHitQuads(x, y, "pos", self.border)
end

function StatisticRender:getHitsRectHeight()
   return (self.fontHeight + self:getHitQuadLineHeight()) * 4
end

function StatisticRender:beforeDraw()
   g.setFont(self.font)
   g.setColor(pallete.statistic)
   g.setLineWidth(1)
   self.fontHeight = g.getFont():getHeight()
end

function StatisticRender:printInfo()
   local y = self.info.y
   g.print(self.info.durationStr, self.info.durationX, y)
   y = y + g.getFont():getHeight()
   g.print(self.info.infoStr, self.info.infoX, y)
end


function StatisticRender:draw()
   local w = g.getWidth()
   self:beforeDraw()
   local x = (w - w * self.width_k) / 2
   local y = self.layout.middle.y + (self.layout.middle.h - self:getHitsRectHeight()) / 2
   self:drawHits(x, y)
   self:printInfo()
   if self.buttons then
      self.mainMenuBtn:draw()
   end
end

function StatisticRender:buildLayout(border)
   border = border or self.border
   local screen = makeScreenTable()
   screen.top, screen.middle, screen.bottom = splith(screen, 0.2, 0.7, 0.1)
   screen.bottom.left, screen.bottom.right = splitv(screen.bottom, 0.5, 0.5)

   local tmp = screen
   tmp.mainMenuBtn = shrink(screen.bottom.right, border)

   self.layout = screen
end

function StatisticRender:keypressed(key)
   self.mainMenuBtn:keyPressed(key)
end

function StatisticRender:keyreleased(key)
   self.mainMenuBtn:keyReleased(key)
end

function StatisticRender:mousepressed(_, _, _, _)
   self.mainMenuBtn:mousePressed()
end

function StatisticRender:mousereleased(_, _, _utton)
   self.mainMenuBtn:mouseReleased()
end

function StatisticRender:preparePrintInfo()
   self.info = {}
   self.info.durationStr = i18n("levelInfo2_part1", { count = self.level }) .. " " ..
   i18n("levelInfo2_part2", { count = self.pause_time })
   self.info.infoStr = i18n("levelInfo1_part1", { count = self.durationMin }) .. " " ..
   i18n("levelInfo1_part2", { count = tonumber(
string.format("%d", math.floor(self.durationSec))), })

   local width1, width2 = g.getFont():getWidth(self.info.infoStr), g.getFont():getWidth(self.info.durationStr)
   local textHeight = g.getFont():getHeight() * 2
   self.info.infoX, self.info.durationX = (self.layout.top.w - width1) / 2, (self.layout.top.w - width2) / 2
   self.info.y = (self.layout.top.h - textHeight) / 2
end

function StatisticRender.new(data)
   local self = setmetatable({
      signals = data.signals,
      pressed = data.pressed,
      level = data.level,
      pause_time = data.pause_time,
      font = data.font,
      x0 = data.x0,
      y0 = data.y0,
      durationMin = data.durationMin,
      durationSec = data.durationSec,
      buttons = data.buttons,
   }, StatisticRender_mt)


   self.width_k = 3.9 / 4
   self.border = 2
   self.signals.eq = require("generator").makeEqArrays(self.signals, self.level)
   local w, _ = love.graphics.getDimensions()
   self.rect_size = math.floor(w * self.width_k / #self.signals.pos)
   self.percent = percentage(self.signals, self.pressed)

   self:buildLayout(data.border)

   self:preparePrintInfo()



   if self.buttons then






      local mainMenuBtnLayout = (self.layout).mainMenuBtn
      self.mainMenuBtn = Button.new(i18n("backToMainMenu"),
      mainMenuBtnLayout.x, mainMenuBtnLayout.y,
      mainMenuBtnLayout.w, mainMenuBtnLayout.h)
      self.mainMenuBtn.onMouseReleased = function(_)


         error("global variable confusion")


      end














   end

   return self
end

return StatisticRender
