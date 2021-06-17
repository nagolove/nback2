local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; require("love")
require("common")

local inspect = require("inspect")
local pallete = require("pallete")
local gr = love.graphics

local Language = {}




 LanguageSelector = {Rect = {}, }

































local LanguageSelector_mt = {
   __index = LanguageSelector,
}

function LanguageSelector.new()
   local self = setmetatable({}, LanguageSelector_mt)
   self.languages = {}
   self.font = require("fonts").languageSelector
   self.locale = nil
   for _, v in ipairs(love.filesystem.getDirectoryItems(SCENEPREFIX .. "locales")) do
      local chunk, errmsg = love.filesystem.load(SCENEPREFIX .. "locales/" .. v)

      if not errmsg and type(chunk) == "function" then


         table.insert(self.languages, {
            id = (chunk()).language,
            locale = string.match(v, "(%S+)%."),
         })
      end
   end
   print("languages", inspect(self.languages))
   self.selected = 1
   self.beetweenClicks = 0.4
   self:prepareDraw()
   return self
end

function LanguageSelector:prepareDraw()
   local w, h = gr.getDimensions()
   local menuItemHeight = self.font:getHeight() + 6
   local menuHeight = #self.languages * menuItemHeight
   local menuWidth = 0.

   for _, v in ipairs(self.languages) do
      local width = self.font:getWidth(v.id)
      print('in cycle width = ', width)
      if width > menuWidth then
         menuWidth = width
      end
   end

   local x0, y0 = 0., 0.
   self.x, self.y = (w - menuWidth) / 2, (h - menuHeight) / 2
   print("menuWidth, menuHeight", menuWidth, menuHeight)
   self.canvas = gr.newCanvas(menuWidth, menuHeight)
   gr.setFont(self.font)
   gr.setColor(pallete.languageMenuText)
   gr.setCanvas(self.canvas)

   self.items = {}
   local x, y = self.x, self.y
   for _, v in ipairs(self.languages) do

      gr.print(v.id, x0, y0)
      y0 = y0 + menuItemHeight
      table.insert(self.items, { x = x, y = y, w = menuWidth, h = menuItemHeight })
      y = y + menuItemHeight
   end

   gr.setCanvas()


end

function LanguageSelector:draw()
   local x, y = self.x, self.y

   gr.setColor({ 1, 1, 1, 1 })
   local Drawable = love.graphics.Drawable
   gr.draw(self.canvas, x, y)

   local prevLineWidth = gr.getLineWidth()
   if self.selected then
      local v = self.items[self.selected]
      gr.setColor(pallete.selectedLanguageBorder)
      gr.setLineWidth(3)
      gr.rectangle("line", v.x, v.y, v.w, v.h)
   end
   gr.setLineWidth(prevLineWidth)



end

function LanguageSelector:resize()
   print("LanguageSelector:resize()")
   self:prepareDraw()
end

function LanguageSelector:update(_)
end

function LanguageSelector:touchpressed(_, _, _)
end

function LanguageSelector:touchreleased(_, _, _)
end

function LanguageSelector:touchmoved(_, _, _, _, _)
end

function LanguageSelector:up()
   if self.selected - 1 < 1 then
      self.selected = #self.items
   else
      self.selected = self.selected - 1
   end
end

function LanguageSelector:down()
   if self.selected + 1 > #self.items then
      self.selected = 1
   else
      self.selected = self.selected + 1
   end
end

function LanguageSelector:keypressed(key)
   if key == "up" or key == "k" then
      self:up()
   elseif key == "down" or key == "j" then
      self:down()
   elseif key == "space" or key == "return" then
      print("select")
      self.locale = self.languages[self.selected].locale
   end
end

function LanguageSelector:mousepressed(x, y, _, _)

   for k, v in ipairs(self.items) do

      if pointInRect(x, y, v.x, v.y, v.w, v.h) then
         self.locale = self.languages[k].locale
      end
   end
end

function LanguageSelector:mousemoved(x, y, _, _, _)
   for k, v in ipairs(self.items) do

      if pointInRect(x, y, v.x, v.y, v.w, v.h) then

         self.selected = k


      end
   end


end

return LanguageSelector
