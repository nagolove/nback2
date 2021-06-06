local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local table = _tl_compat and _tl_compat.table or table; require("love")

local gr = love.graphics
local fontsize = 23





local List = {Lock = {}, Bar = {}, ColorType = {}, Colors = {}, Item = {}, }


















































































function inside(mx, my, x, y, w, h)
   return mx >= x and mx <= (x + w) and my >= y and my <= (y + h)
end

function List.new(x, y, w, h, fnt)
   local self = {

      font = fnt,
   }

   self = setmetatable(self, { __index = List })

   self.items = {}
   self.hoveritem = 0
   self.onclick = nil

   self.x = x
   self.y = y

   self.width = w
   self.height = h


   print("self.item_height", self.font:getHeight())
   self.item_height = self.font:getHeight()
   self.sum_item_height = 0

   self.bar = { size = 20, pos = 0, maxpos = 0, width = 20, lock = nil }


   self.colors = {}
   self.colors.normal = { bg = { 0.19, 0.61, 0.88 }, fg = { 0.77, 0.91, 1 } }
   self.colors.hover = { bg = { 0.28, 0.51, 0.66 }, fg = { 1, 1, 1 } }
   self.windowcolor = { 0.19, 0.61, 0.88 }
   self.bordercolor = { 0.28, 0.51, 0.66 }
   self.visible = true
   return self
end



function List:add(message)


   local item = {}

   item.message = message
   table.insert(self.items, item)
   return self.items[#self.items]
end

function List:done()

   self.bar.pos = 0

   local num_items = (self.height / self.item_height)
   local ratio = num_items / #self.items
   self.bar.size = self.height * ratio
   self.bar.maxpos = self.height - self.bar.size - 3


   self.sum_item_height = (self.item_height + 1) * #self.items + 2


   self.height = self.sum_item_height
   local maxLen, maxLenIdx = 0, 1

   for k, v in ipairs(self.items) do
      if type(v) == "table" and v.message and #v.message > maxLen then
         maxLen = #v.message
         maxLenIdx = k
      end
   end


   self.width = self.font:getWidth(self.items[maxLenIdx].message)





end

function List:hasBar()
   return self.bar and self.sum_item_height > self.height
end

function List:getBarRatio()
   return self.bar.pos / self.bar.maxpos
end

function List:getOffset()
   if self.bar then
      local ratio = self.bar.pos / self.bar.maxpos
      return math.floor((self.sum_item_height - self.height) * ratio + 0.5)
   else
      return 0
   end
end

function List:update(dt)
   if self.bar and self.bar.lock then
      local dy = math.floor(love.mouse.getY() - self.bar.lock.y + 0.5)
      self.bar.pos = self.bar.pos + dy

      if self.bar.pos < 0 then
         self.bar.pos = 0
      elseif self.bar.pos > self.bar.maxpos then
         self.bar.pos = self.bar.maxpos
      end
      self.bar.lock.y = love.mouse.getY()
   end
   for _, v in ipairs(self.items) do
      if type(v) == "table" and v.list then
         v.list:update(dt)
      end
   end
end

function List:mousepressed(x, y, b)
   if b == 1 and self:hasBar() then
      local rx, ry, rw, rh = self:getBarRect()
      if inside(x, y, rx, ry, rw, rh) then
         self.bar.lock = { x = x, y = y }
         return
      end
   end

   if inside(x, y, self.x + 2, self.y + 1, self.width - 3, self.height - 3) then
      if type(self.onclick) == "function" then
         local _, ty = x - self.x, y + self:getOffset() - self.y
         local index = math.floor((ty / self.sum_item_height) * #self.items)
         local item = self.items[index + 1]
         if item then
            self.onclick(self, index + 1, b)
         end
      end
   else
      return false
   end

   return true
end

function List:mousereleased(_, _, b)
   if b == 1 and self:hasBar() then
      self.bar.lock = nil
   end
end

function List:mousemoved(x, y, dx, dy)
   self.hoveritem = 0

   if self:hasBar() then
      local rx, ry, rw, rh = self:getBarRect()
      if inside(x, y, rx, ry, rw, rh) then
         self.hoveritem = -1
         return
      end
   end

   if inside(x, y, self.x + 2, self.y + 1, self.width - 3, self.height - 3) then
      local _, ty = x - self.x, y + self:getOffset() - self.y
      local index = math.floor((ty / self.sum_item_height) * #self.items)
      self.hoveritem = index + 1
      local item = self.items[index + 1]
      item.isdrawable = item.list and true or false
      if item.isdrawable then
         item.list:mousemoved(x, y, dx, dy)
      end
   end
end

function List:wheelmoved(_, y)
   if self:hasBar() then
      local per_pixel = (self.sum_item_height - self.height) / self.bar.maxpos
      local bar_pixel_dt = math.floor((self.item_height * 3) / per_pixel + 0.5)

      self.bar.pos = self.bar.pos - y * bar_pixel_dt
      if self.bar.pos > self.bar.maxpos then self.bar.pos = self.bar.maxpos end
      if self.bar.pos < 0 then self.bar.pos = 0 end
   end
end

function List:getBarRect()
   return self.x + self.width + 2, self.y + self.bar.pos + 1,
   self.bar.width - 3, self.bar.size
end

function List:getItemRect(i)
   return
self.x + 2,
   self.y + ((self.item_height + 1) * (i - 1) + 1) - self:getOffset(),
   self.width - 3,
   self.item_height
end

function List:setupPush()
   self.prevfont = gr.getFont()
   gr.setLineWidth(1)
   gr.setLineStyle("rough")
   gr.setColor(self.windowcolor)
   gr.setFont(self.font)
   gr.setScissor(self.x, self.y, self.width, self.height)
end

function List:setupPop()
   love.graphics.setScissor()
   gr.setFont(self.prevfont)
end

function List:border()
   gr.setColor(self.bordercolor)
   if self.bar then
      gr.rectangle("line", self.x + self.width, self.y, self.bar.width, self.height)
   end
   gr.rectangle("line", self.x, self.y, self.width, self.height)
end


function List:getInterval()
   local start_i = math.floor(self:getOffset() / (self.item_height + 1)) + 1
   local end_i = start_i + math.floor(self.height / (self.item_height + 1)) + 1
   if end_i > #self.items then
      end_i = #self.items
   end
   return start_i, end_i
end

function List:draw()
   if not self.visible then
      return
   end

   self:setupPush()


   local rx, ry, rw, rh
   local start_i, end_i = self:getInterval()
   local colorset
   for i = start_i, end_i do
      if i == self.hoveritem then
         colorset = self.colors.hover
      else
         colorset = self.colors.normal
      end

      rx, ry, rw, rh = self:getItemRect(i)
      gr.setColor(colorset.bg)
      gr.rectangle("fill", rx, ry, rw, rh)

      gr.setColor(colorset.fg)



      gr.print(self.items[i].message, rx, ry)


      local item = self.items[i]
      if item.list and item.isdrawable then
         item.list.x = rx + rw
         item.list.y = ry
         item.list:draw()
      end
   end

   love.graphics.setScissor()

   if self:hasBar() then
      if self.hoveritem == -1 or self.bar.lock ~= nil then
         colorset = self.colors.hover
      else
         colorset = self.colors.normal
      end

      rx, ry, rw, rh = self:getBarRect()
      love.graphics.setColor(colorset.bg)
      love.graphics.rectangle("fill", rx, ry, rw, rh)
   end


   self:border()
   self:setupPop()
end


function List:bar()














end

function List:draw2()
   if not self.visible then return end

   love.graphics.setLineWidth(1)
   love.graphics.setLineStyle("rough")
   love.graphics.setColor(self.windowcolor)


   local start_i = math.floor(self:getOffset() / (self.item_height + 1)) + 1
   local end_i = start_i + math.floor(self.height / (self.item_height + 1)) + 1
   if end_i > #self.items then
      end_i = #self.items
   end

   love.graphics.setScissor(self.x, self.y, self.width, self.height)


   local rx, ry, rw, rh
   local colorset
   for i = start_i, end_i do
      if i == self.hoveritem then
         colorset = self.colors.hover
      else
         colorset = self.colors.normal
      end

      rx, ry, rw, rh = self:getItemRect(i)
      love.graphics.setColor(colorset.bg)
      love.graphics.rectangle("fill", rx, ry, rw, rh)

      love.graphics.setColor(colorset.fg)


      local t = {}



      love.graphics.print(t, rx + 10, ry + 5)

      local item = self.items[i]
      if item.list and item.isdrawable then
         item.list.x = rx + rw
         item.list.y = ry
         item.list:draw()
      end
   end

   love.graphics.setScissor()


   if self:hasBar() then






      rx, ry, rw, rh = self:getBarRect()
      love.graphics.setColor(colorset.bg)
      love.graphics.rectangle("fill", rx, ry, rw, rh)
   end


   love.graphics.setColor(self.bordercolor)
   if self.bar then

   end
   love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

end

return List
