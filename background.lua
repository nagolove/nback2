local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local os = _tl_compat and _tl_compat.os or os; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; require("love")
require("fonts")
require("common")

local g = love.graphics
local inspect = require("inspect")
local pallete = require("pallete")

 Background = {}















local Background_mt = {
   __index = Background,
}

local Block = {}

















local Block_mt = {
   __index = Block,
}

function Background.new()
   print('Background.new()')

   local self = {
      bsize = 128,

      fragmentCode = [[
extern float time;
vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
    vec4 pixel = Texel(image, uvs);
    float av = (pixel.r + pixel.g + pixel.b) / time;
    return pixel * color;
}
]],
      tile = love.graphics.newImage(SCENEPREFIX .. "gfx/IMG_20190111_115755.png"),
      blockSize = 128,
      emptyNum = 1,




      execList = {},
      paused = false,
   }
   self = setmetatable(self, Background_mt)

   local blocksPath = "gfx/blocks"
   local files = love.filesystem.getDirectoryItems(blocksPath)
   self.tiles = {}
   for _, v in ipairs(files) do

      local ok, errmsg = pcall(function()
         self.tiles[#self.tiles + 1] = love.graphics.newImage(blocksPath ..
         "/" .. v)
      end)
      if not ok then
         print(errmsg)
      end
   end

   self:fillGrid()
   self:resize(g.getDimensions())

   return self
end


function Block.new(back, img, xidx,
   yidx, duration)
   local self = {
      back = back,
      img = img,
      x = (xidx - 1) * back.bsize,
      y = (yidx - 1) * back.bsize,
      xidx = xidx,
      yidx = yidx,
      active = false,
      duration = duration,
   }
   return setmetatable(self, Block_mt)
end

function Block:draw()
   local quad = g.newQuad(0, 0, self.img:getWidth(), self.img:getHeight(),
   self.img:getWidth(), self.img:getHeight())

   g.setColor({ 1, 1, 1, 1 })






   g.draw(self.img, quad, self.x, self.y, 0, self.back.bsize /
   self.img:getWidth(), self.back.bsize / self.img:getHeight())

   if self.active then
      g.setColor({ 1, 1, 1 })
      local oldLineWidth = g.getLineWidth()
      g.setLineWidth(3)

      g.setLineWidth(oldLineWidth)
   end






   local oldFont = g.getFont()
   g.setColor({ 0, 0, 0 })
   g.setFont(oldFont)
end



function Block:move(dirx, diry)

   self.dirx = dirx
   self.diry = diry

   self.newXidx = self.xidx + dirx
   self.newYidx = self.yidx + diry
   self.active = true

   self.animCounter = self.back.bsize
end



function Block:process(dt)
   local ret = false




   local speed = 20
   local ds = (dt * speed)

   if self.animCounter - ds > 0 then
      self.animCounter = self.animCounter - ds
      self.x = self.x + self.dirx * ds
      self.y = self.y + self.diry * ds
      ret = true
   else


      self.active = false
      self.back.blocks[math.floor(self.xidx)][math.floor(self.yidx)] = {}

      self.back.blocks[math.floor(self.newXidx)][math.floor(self.newYidx)] = self
      self.oldXidx, self.oldYidx = self.xidx, self.yidx
      self.xidx = self.newXidx
      self.yidx = self.newYidx


   end

   return ret
end

function Background:get(xidx, yidx)
   local firstColumn = self.blocks[1]

   if xidx >= 1 and xidx <= #self.blocks and
      yidx >= 1 and yidx <= #firstColumn then
      return self.blocks[xidx][yidx]
   else
      return nil
   end
end







function Background:findDirection(xidx, yidx)
   local x, y = xidx, yidx



   local columnMax = #self.blocks[1]

   local directions = { xidx - 1 >= 1, yidx - 1 >= 1, xidx + 1 <= columnMax,
yidx + 1 <= columnMax, }






   local inserted = false

   local j = 1
   while not inserted do
      local dir = math.random(1, 4)


      if dir == 1 then

         if directions[dir] and self.blocks[xidx - 1] and
            self.blocks[xidx - 1][yidx] then
            x = x - 1
            inserted = true
         end
      elseif dir == 2 then

         if directions[dir] and self.blocks[xidx] and
            self.blocks[xidx][yidx - 1] then
            y = y - 1
            inserted = true
         end
      elseif dir == 3 then

         if directions[dir] and self.blocks[xidx + 1] and
            self.blocks[xidx + 1][yidx] then
            x = x + 1
            inserted = true
         end
      elseif dir == 4 then

         if directions[dir] and self.blocks[xidx] and
            self.blocks[xidx][yidx + 1] then
            y = y + 1
            inserted = true
         end
      end

      j = j + 1
      if j > 16 then
         error(string.format(
         "Something wrong in block placing alrogithm on [%d][%d].",
         xidx, yidx))
      end
   end

   return x, y
end

function Background:fillGrid()
   local w, h = g.getDimensions()





   self.blocks = {}



   local xcount, ycount = math.floor(w / self.bsize) + 1,
   math.floor(h / self.bsize) + 1
   for i = 1, xcount do
      local column = {}
      for j = 1, ycount do
         column[#column + 1] = Block.new(self, self.tile, i, j, 1000)
      end
      self.blocks[#self.blocks + 1] = column
   end

   math.randomseed(os.time())

   local fieldWidth, fieldHeight = #self.blocks, #self.blocks[1]
   self.execList = {}
   for _ = 1, self.emptyNum do

      local xidx = math.random(1, fieldWidth)
      local yidx = math.random(1, fieldHeight)
      self.blocks[xidx][yidx] = {}


      local x, y = self:findDirection(xidx, yidx)

      self.blocks[x][y]:move(xidx - x, yidx - y)
      self.execList[#self.execList + 1] = self.blocks[x][y]
   end
end

function Background:update(dt)
   if self.paused then return end

   for k, v in ipairs(self.execList) do
      local block = v


      local ret = block:process(dt)

      if not ret then




         local xidx, yidx = block.oldXidx or block.xidx,
         block.oldYidx or block.yidx

         print(string.format("v.xidx = %d, v.yidx = %d", v.xidx, v.yidx))


         local x, y = self:findDirection(math.floor(xidx), math.floor(yidx))










         if self.blocks[x][y].move then
            self.blocks[x][y]:move(xidx - x, yidx - y)
         elseif self.blocks[x][y] == {} then
            error("{} block")
         else
            error("Ououou " .. inspect(self.blocks[x][y]))
         end

         self.execList[k] = self.blocks[x][y]



      end
   end
end

function Background:draw()
   g.clear(pallete.background)

   for _, v in ipairs(self.blocks) do
      for _, p in ipairs(v) do
         if p.draw then p:draw() end
      end
   end
end





function Background:resize(_, _)


   self:fillGrid()
end

return {
   new = Background.new,
}
