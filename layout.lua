local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local math = _tl_compat and _tl_compat.math or math; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local _tl_table_unpack = unpack or table.unpack; require("love")
local lg = love.graphics

local inspect = require("inspect")



 Layout = {}











local Layout_mt = {
   __index = Layout,
}

function makeScreenTable()
   return { x = 0, y = 0, w = lg.getWidth(), h = lg.getHeight() }
end

function assertHelper(tbl)
   assert(tbl.x and tbl.y and tbl.w and tbl.h,
   "not all fields are correct " .. inspect(tbl))
end


function checkHelper(tbl)
   return (tbl.x and tbl.y and tbl.w and tbl.h) ~= nil
end

function Layout.new(x, y, w, h)
   local self
   if not x and not y and not w and not h then
      self = makeScreenTable()
   else
      self = { x = x, y = y, w = w, h = h }
   end
   if type(x) == "table" then
      assertHelper(x)
      local tbl = x
      self = { x = tbl.x, y = tbl.y, w = tbl.w, h = tbl.h }
   end
   return setmetatable(self, Layout_mt)
end

function assertVariadic(...)
   local sum = 0
   for i = 1, select("#", ...) do
      sum = sum + select(i, ...)
   end
   assert(math.abs(sum - 1) < 0.01)
end


function splith(tbl, ...)
   assertVariadic(...)
   assertHelper(tbl)
   local subTbls = {}
   local lasty = tbl.y
   for i = 1, select("#", ...) do
      local currenth = tbl.h * select(i, ...)
      table.insert(subTbls, { x = tbl.x, y = lasty, w = tbl.w, h = currenth })
      lasty = lasty + currenth
   end
   return _tl_table_unpack(subTbls)
end

function assertAlign(alignMode)
   assert(type(alignMode) == "string")
   assert(alignMode == "left" or alignMode == "right" or
   alignMode == "center")
end

function splitv(tbl, ...)
   assertVariadic(...)
   assertHelper(tbl)
   local subTbls = {}
   local lastx = tbl.x
   for i = 1, select("#", ...) do
      local currentw = tbl.w * select(i, ...)
      table.insert(subTbls, { x = lastx, y = tbl.y, w = currentw, h = tbl.h })
      lastx = lastx + currentw
   end
   return _tl_table_unpack(subTbls)
end

function splitvAlign(tbl, alignMode, ...)
   assert(false, "Not yet implemented")
   assertHelper(tbl)
   assertAlign(alignMode)
   local subTbls = {}
   for i = 1, select("#", ...) do
   end
   assert(false, "Not implemented")
end

function splithByNum(tbl, piecesNum)
   assertHelper(tbl)
   local subTbls = {}
   local prevy, h = tbl.y, tbl.h / piecesNum
   for i = 1, piecesNum do
      table.insert(subTbls, { x = tbl.x, y = prevy, w = tbl.w, h = h })
      prevy = prevy + h
   end
   return _tl_table_unpack(subTbls)
end

function splitvByNum(tbl, piecesNum)
   assertHelper(tbl)
   local subTbls = {}
   local prevx, w = tbl.x, tbl.w / piecesNum
   for i = 1, piecesNum do
      table.insert(subTbls, { x = prevx, y = tbl.y, w = w, h = tbl.h })
      prevx = prevx + w
   end
   return _tl_table_unpack(subTbls)
end

function shrink(tbl, value)
   assertHelper(tbl)
   assert(type(value) == "number", string.format("number expected, but %s is", type(value)))
   return { x = tbl.x + value, y = tbl.y + value,
w = tbl.w - value * 2, h = tbl.h - value * 2, }
end

function areaGrowByPixel(tbl, delta)
   assertHelper(tbl)
   assert(type(delta) == "number")
   return { x = tbl.x + delta, y = tbl.y + delta,
w = tbl.w - delta * 2, h = tbl.h - delta * 2, }
end



function drawHelper(...)





















   for i = 1, select("#", ...) do
      local tbl = select(i, ...)


      assertHelper(tbl)
      if checkHelper(tbl) then

         lg.rectangle("line", tbl.x, tbl.y, tbl.w, tbl.h)

         lg.rectangle("line", tbl.x + 1, tbl.y + 1, tbl.w - 1, tbl.h - 1)
      elseif type(tbl) == "table" then


         for _, v in pairs(tbl) do
            if checkHelper(v) then
               drawHelper(v)
            end
         end
      end
   end
end

function drawHierachy(rootTbl)

   if checkHelper(rootTbl) then
      drawHelper(rootTbl)
   end
   for _, v in pairs(rootTbl) do
      if type(v) == "table" and checkHelper(v) then
         drawHierachy(v)
      end
   end
end
