local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; require("love")
require("globals")
require("vector")
require("nbtypes")

local g = love.graphics
local inspect = require("inspect")

 SignalView = {}
































local SignalView_mt = {
   __index = SignalView,
}



local function intersection(start1, end1, start2, end2)
   assert(vector.isvector(start1) and vector.isvector(end1) and
   vector.isvector(start2) and vector.isvector(end2))

   local dir1 = end1 - start1;
   local dir2 = end2 - start2;


   local a1 = -dir1.y;
   local b1 = dir1.x;
   local d1 = -(a1 * start1.x + b1 * start1.y);

   local a2 = -dir2.y;
   local b2 = dir2.x;
   local d2 = -(a2 * start2.x + b2 * start2.y);


   local seg1_line2_start = a2 * start1.x + b2 * start1.y + d2;
   local seg1_line2_end = a2 * end1.x + b2 * end1.y + d2;

   local seg2_line1_start = a1 * start2.x + b1 * start2.y + d1;
   local seg2_line1_end = a1 * end2.x + b1 * end2.y + d1;


   if (seg1_line2_start * seg1_line2_end >= 0 or
      seg2_line1_start * seg2_line1_end >= 0) then
      return nil
   end

   local u = seg1_line2_start / (seg1_line2_start - seg1_line2_end);

   return start1 + u * dir1
end




function SignalView.new(width, soundPack)
   local self = {
      width = width,
      sounds = {},
      canvas = nil,
      borderColor = { 0, 0, 0 },
      borderLineWidth = 3,
   }

   local wavePath = SCENEPREFIX .. "sfx/" .. soundPack
   for _, v in ipairs(love.filesystem.getDirectoryItems(wavePath)) do
      table.insert(self.sounds, love.audio.newSource(wavePath .. "/" .. v,
      "static"))
   end

   self = setmetatable(self, SignalView_mt)



   self:setCorner(0, 0)
   self:resize(self.width)
   return self
end



function SignalView:setCorner(x, y)
   self.x0, self.y0 = x, y
end

function SignalView:resize(width)
   self.width = width

   self.canvas = g.newCanvas(width, width * 6, { msaa = 2 })





end





function SignalView:draw(xd, yd, type_, color)
   print('SignalView:draw()', xd, yd, type_, color)



   local border = 1
   local w, h = self.width - border * 2, self.width - border * 2
   local x = self.x0 + xd * self.width + border
   local y = self.y0 + yd * self.width + border

   self.borderColor[4] = color[4]
   g.setColor(color)
   local oldWidth = g.getLineWidth()
   g.setLineWidth(self.borderLineWidth)



   print('SignalView:draw()', x, y, w, h)

   self[type_](self, x, y, w, h)

   g.setLineWidth(oldWidth)

   g.setColor({ 1, 1, 1 })


end





function SignalView:play(index)
   if type(index) ~= 'number' then
      error(string.format(
      'SignalView:play() "index" is not a number, type(%s) == %s',
      type(index),
      inspect(index)))

   end
   print('SignalView:play()', index, #self.sounds)
   assert(index <= #self.sounds)

end

function SignalView:quad(x, y, w, h)
   print('SignalView:quad()', x, y, w, h)
   local delta = 5
   g.rectangle("fill", x + delta, y + delta, w - delta * 2, h - delta * 2)
   g.setColor(self.borderColor)
   g.rectangle("line", x + delta, y + delta, w - delta * 2, h - delta * 2)
end

function SignalView:circle(x, y, w, h)
   g.circle("fill", x + w / 2, y + h / 2, w / 2.3)
   g.setColor(self.borderColor)
   g.circle("line", x + w / 2, y + h / 2, w / 2.3)
end

function SignalView:trdown(x, y, w, h)
   local magic = 2.64
   local tri = {}
   local rad = w / 2
   for i = 1, 3 do
      local alpha = 2 * math.pi * i / 3
      local sx = x + w / 2 + rad * math.sin(alpha)
      local sy = y + h / magic + rad * math.cos(alpha)
      tri[#tri + 1] = sx
      tri[#tri + 1] = sy
   end
   g.polygon("fill", tri)
   g.setColor(self.borderColor)
   g.polygon("line", tri)
end

function SignalView:trup(x, y, w, h)
   local magic = 1.64
   local tri = {}
   local rad = w / 2
   for i = 1, 3 do
      local alpha = math.pi + 2 * math.pi * i / 3
      local sx = x + w / 2 + rad * math.sin(alpha)
      local sy = y + h / magic + rad * math.cos(alpha)
      tri[#tri + 1] = sx
      tri[#tri + 1] = sy
   end
   g.polygon("fill", tri)
   g.setColor(self.borderColor)
   g.polygon("line", tri)
end




function SignalView:calculateIntersections(up, down)
   local points = {}
   local p
   local vec2 = vector.new


   p = intersection(vec2(up[5], up[6]), vec2(up[1], up[2]),
   vec2(down[5], down[6]), vec2(down[3], down[4]))
   points[#points + 1] = p.x
   points[#points + 1] = p.y


   p = intersection(vec2(up[5], up[6]), vec2(up[1], up[2]),
   vec2(down[3], down[4]), vec2(down[1], down[2]))
   points[#points + 1] = p.x
   points[#points + 1] = p.y


   p = intersection(vec2(up[3], up[4]), vec2(up[5], up[6]),
   vec2(down[3], down[4]), vec2(down[1], down[2]))
   points[#points + 1] = p.x
   points[#points + 1] = p.y


   p = intersection(vec2(up[3], up[4]), vec2(up[5], up[6]),
   vec2(down[1], down[2]), vec2(down[5], down[6]))
   points[#points + 1] = p.x
   points[#points + 1] = p.y


   p = intersection(vec2(up[3], up[4]), vec2(up[1], up[2]),
   vec2(down[1], down[2]), vec2(down[5], down[6]))
   points[#points + 1] = p.x
   points[#points + 1] = p.y


   p = intersection(vec2(up[3], up[4]), vec2(up[1], up[2]),
   vec2(down[3], down[4]), vec2(down[5], down[6]))
   points[#points + 1] = p.x
   points[#points + 1] = p.y

   return points
end

function SignalView:trupdown(_, _, w, h)
   local tri_up, tri_down = {}, {}
   local rad = w / 2
   for i = 1, 3 do
      local alpha = 2 * math.pi * i / 3
      local sx = w / 2 + rad * math.sin(alpha)
      local sy = h / 2 + rad * math.cos(alpha)
      tri_up[#tri_up + 1] = sx
      tri_up[#tri_up + 1] = sy

      alpha = math.pi + 2 * math.pi * i / 3
      sx = w / 2 + rad * math.sin(alpha)
      sy = h / 2 + rad * math.cos(alpha)

      tri_down[#tri_down + 1] = sx
      tri_down[#tri_down + 1] = sy
   end

   g.polygon("fill", tri_up)
   g.polygon("fill", tri_down)

   local points = self:calculateIntersections(tri_up, tri_down)

   local borderVertices = {
      tri_up[1], tri_up[2],
      points[1], points[2],
      tri_down[3], tri_down[4],
      points[3], points[4],
      tri_up[5], tri_up[6],
      points[5], points[6],
      tri_down[1], tri_down[2],
      points[7], points[8],
      tri_up[3], tri_up[4],
      points[9], points[10],
      tri_down[5], tri_down[6],
      points[11], points[12],
      tri_up[1], tri_up[2],
      tri_down[3], tri_down[4],
   }

   local oldcolor = { g.getColor() }
   g.setColor(self.borderColor)
   g.polygon("line", borderVertices)
   g.setColor(oldcolor)
end

function SignalView:rhombus(x, y, w, h)
   print('SignalView:rhombus()', x, y, w, h)
   local delta = 6
   g.polygon("fill", { x + delta, y + h / 2, x + w / 2, y + h - delta,
x + w - delta, y + h / 2,
x + w / 2, y + delta, })
   g.setColor(self.borderColor)
   g.polygon("line", { x + delta, y + h / 2, x + w / 2, y + h - delta,
x + w - delta, y + h / 2,
x + w / 2, y + delta, })
end

return {
   new = SignalView.new,
}
