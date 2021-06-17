local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math; print('hello from top of Help module.')

require("button")
require("cmn")
require("common")
require("globals")
require("layout")
require("love")
require("menu-main")
require("nback")
require("tiledbackground")

local pallete = require("pallete")
local fonts = require("fonts")
local i18n = require("i18n")

 Help = {Desc = {}, }



















local Help_mt = {
   __index = Help,
}



function Help.new()
   local self = {
      font = fonts.help.font,
   }
   return setmetatable(self, Help_mt)
end

local g = love.graphics

function Help:init()
   self:buildLayout()




   self:buildButtons()


   self.ui = storeUI()


   self:prepareDrawDescription()
end

function Help:buildButtons()
   local mainMenuBtnLayout = shrink(self.layout.top, nback.border)















   self.mainMenuBtn = Button.new(i18n("help.backButton"),
   mainMenuBtnLayout.x, mainMenuBtnLayout.y,
   mainMenuBtnLayout.w, mainMenuBtnLayout.h)
   self.mainMenuBtn.font = fonts.help.gooi
   self.mainMenuBtn.bgColor = { 0.208, 0.220, 0.222 }
end

function Help:buildLayout()
   self.layout = {}
   self.layout.top, self.layout.bottom = splith(makeScreenTable(), 0.1, 0.9)
end

function Help:resize(_, _)
   self:buildLayout()
end

function Help:enter()
   print("help:enter()")
   restoreUI(self.ui)
end

function Help:leave()
   print("help:leave()")
   self.ui = storeUI()
end

function Help:prepareDrawDescription()
   self.desc = {}

   local w, h = g.getDimensions()
   local x, y = math.floor(self.layout.bottom.x), math.floor(self.layout.bottom.y)




   local descText = i18n("help.desc")


   descText = descText or ""

   self.desc.x, self.desc.y = x, y
   self.desc.canvas = g.newCanvas(w, h)
   g.setCanvas(self.desc.canvas)

   g.setColor({ 1, 1, 1, 1 })
   g.clear(pallete.background)
   g.setFont(self.font)

   g.printf(descText, x, y, w - 100, "center")




   g.setCanvas()
end

function Help:drawDescription()
   g.setColor({ 1, 1, 1 })
   g.draw(self.desc.canvas, self.desc.x, self.desc.y)
end

function Help:draw()
   g.clear(pallete.background)
   tiledback:draw(0.3)
   self:drawDescription()

   self.mainMenuBtn:draw()



end

function Help:update(dt)
   self.mainMenuBtn:update(dt)
end

function Help:mousepressed(_, _, _, _)
   print("help:mousepressed()")
   self.mainMenuBtn:mousePressed()
end

function Help:mousereleased(_, _, _, _)
   print("help:mousereleased()")
   self.mainMenuBtn:mouseReleased()
end

function Help:keypressed(key)
   if key == "escape" then

      mainMenu:goBack()
   end
end




help = Help.new()
print('hello from bottom of Help module.')
