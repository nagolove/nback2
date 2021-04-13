local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; require("love")

local g = love.graphics

 AlignedLabels = {}













local AlignedLabels_mt = {
   __index = AlignedLabels,
}

function AlignedLabels.new(font, screenwidth, color)
   local self = {}
   setmetatable(self, AlignedLabels_mt)
   self:clear(font, screenwidth, color)
   return self
end

function AlignedLabels:clear(font, screenwidth, color)
   self.screenwidth = screenwidth or self.screenwidth
   self.font = font or self.font
   self.data = {}
   self.colors = {}
   self.default_color = color or { 1, 1, 1, 1 }
   self.maxlen = 0
end




function AlignedLabels:add(...)
   local nargs = select("#", ...)
   if nargs > 2 then
      local colored_text_data = {}
      local colors = {}
      local text_len = 0
      for i = 1, nargs, 2 do
         local text = select(i, ...)
         local color = select(i + 1, ...)
         text_len = text_len + text:len()
         colored_text_data[#colored_text_data + 1] = text
         colors[#colors + 1] = color
      end



      self.data = colored_text_data



      self.colors = colors

      if text_len > self.maxlen then
         self.maxlen = text_len
      end
   else
      self.data[#self.data + 1] = select(1, ...)
      self.colors[#self.colors + 1] = (select(2, ...)) or self.default_color
   end
end

function AlignedLabels:draw(x, y)
   local dw = self.screenwidth / (#self.data + 1)
   local i = x + dw
   local f = g.getFont()
   local c = { g.getColor() }
   g.setFont(self.font)
   for k, v in pairs(self.data) do
      if type(v) == "string" then
         g.setColor(self.colors[k])
         g.print(v, i - self.font:getWidth(v) / 2, y)
         i = i + dw
      elseif type(v) == "table" then
         local width = 0.
         for _, g in ipairs(v) do
            width = width + self.font:getWidth(g)
         end

         assert(#(v) == #self.colors[math.floor(k)])
         local xpos = i - width / 2
         for j, p in pairs(v) do

            g.setColor(self.colors[math.floor(k)][math.floor(j)])
            g.print(p, xpos, y)
            xpos = xpos + self.font:getWidth(p)
         end
         i = i + dw
      else
         error(string.format(
         "AlignedLabels:draw() : Incorrect type %s in self.data",
         self.data))
      end
   end
   g.setFont(f)
   g.setColor(c)
end

return AlignedLabels
