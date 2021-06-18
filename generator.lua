local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local table = _tl_compat and _tl_compat.table or table; local _tl_table_unpack = unpack or table.unpack; require("common")
require("cmn")
require("nbtypes")

local inspect = require("inspect")

local logfile = love.filesystem.newFile("log-generator.txt", "w")

local GenFunction = {}
local CmpFunction = {}

local function generate(
   sig_count,
   level,
   gen,
   cmp)


   local ret = {}

   local ratio = 5

   local range = { 1, 3 }
   local null = {}

   for _ = 1, ratio * sig_count do
      table.insert(ret, null)
   end


   repeat
      local i = 1
      repeat
         if sig_count > 0 then


            local prob = math.random(_tl_table_unpack(range))

            if prob == range[2] then
               if i + level <= #ret and ret[i] == null and ret[i + level] == null then
                  ret[i] = gen()
                  if type(ret[i]) == "table" then
                     ret[i + level] = shallowCopy(ret[i])
                  else
                     ret[i + level] = ret[i]
                  end
                  sig_count = sig_count - 1
               end
            end
         end
         i = i + 1
         print('i, #ret', i, #ret)
      until i > #ret
      print('sig_count', sig_count)
   until sig_count == 0

   print('done1')

   local __COUNTER = 0















   print('done2')

   return ret
end

local function make_hit_arr(signals, level, comparator)
   local ret = {}
   if signals then
      for k, v in ipairs(signals) do
         ret[#ret + 1] = k > level and comparator(v, signals[k - level])
      end
   end
   return ret
end

local function makeEqArrays(signals, level)
   local ret = {
      pos = make_hit_arr(signals.pos, level, isPositionEqual),
      sound = make_hit_arr(signals.sound, level,
      function(a, b)
         return a == b
      end),
      color = make_hit_arr(signals.color, level, function(a, b)
         return a == b
      end),
      form = make_hit_arr(signals.form, level, function(a, b)
         return a == b
      end),
   }
   return ret
end













function generateAll(sig_count, level, dim, soundsNum, map)
   print('generateAll()')
   print('sig_count:', sig_count)
   print('level:', level)
   print('dim:', dim)
   print('soundsNum', soundsNum)
   print('map:', inspect(map))

   local colorArr = require("colorconstants").makeNamesArray()

   function genArrays(sig_count, level, _, soundsNum)
      local signals = {}

      logfile:write("--pos gen--\n")

      signals.pos = generate(sig_count, level,

















      function()
         local result = {}
         local x, y = math.random(1, #map), math.random(1, #map[1])
         print('x, y', x, y)









         result.x, result.y = x, y
         return result
      end,
      function(a, b)
         return a.x == b.x and a.y == b.y
      end)

      logfile:write("--pos gen--\n")

      signals.form = generate(sig_count, level,
      function()
         local arr = { "trup", "trdown", "trupdown", "quad", "circle", "rhombus" }
         return arr[math.random(1, 6)]
      end,
      function(a, b)
         return a == b
      end)

      signals.sound = generate(sig_count, level,
      function()
         return math.random(1, soundsNum)
      end,
      function(a, b)
         return a == b
      end)

      signals.color = generate(sig_count, level,
      function() return colorArr[math.random(1, 6)] end,
      function(a, b)
         return a == b
      end)


      signals.eq = makeEqArrays(signals, level)
      return signals
   end



   function balance(forIterCount)
      local i, changed = 0, false
      local signals
      repeat
         i = i + 1
         signals = genArrays(sig_count, level, dim, soundsNum)
         for k, v in ipairs(signals.eq.pos) do
            local n = 0
            n = n + (v and 1 or 0)
            n = n + (signals.eq.sound[k] and 1 or 0)
            n = n + (signals.eq.form[k] and 1 or 0)
            n = n + (signals.eq.color[k] and 1 or 0)
            if n > 2 then
               changed = true

            end
         end

      until i >= forIterCount or not changed

      return signals
   end

   local result = balance(1)

   logfile:write("\n")
   logfile:write(inspect(result))
   logfile:write("\n")
   logfile:close()

   return result
end

return {
   makeEqArrays = makeEqArrays,
   generateAll = generateAll,
}
