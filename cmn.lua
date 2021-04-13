local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; require("love")
require("nbtypes")
require("constants")

local i18n = require("i18n")

local serpent = require("serpent")


__DEBUG__ = false
onAndroid = love.system.getOS() == "Android"
useKeyboard = true
preventiveFirstRun = true

require("pviewer")
require("menu")
require("help")
require("tiledbackground")







function initGlobals()
   menu = require("menu").new()
   pviewer = require("pviewer").new()
   help = require("help").new()

   tiledback = require("tiledbackground"):new()
end





function pack(...)
   return { ... }
end


function div(a, b)
   return (a - a % b) / b
end


















function deepcopy(orig)
   local orig_type = type(orig)
   if orig_type == 'table' then
      local copy = {}
      copy = {}
      for orig_key, orig_value in pairs(orig) do
         copy[deepcopy(orig_key)] = deepcopy(orig_value)
      end
      return copy

   else
      return orig
   end
end

function make_screenshot()
   local i = 0
   local info
   repeat
      i = i + 1
      info = love.filesystem.getInfo("screenshot" .. i .. ".png")
   until not info
   love.graphics.captureScreenshot("screenshot" .. i .. ".png")
end




function calcPercent(eq, pressed_arr)
   if not eq then return 0 end
   local succ, mistake, count = 0, 0, 0
   for k, v in ipairs(eq) do
      if v then
         count = count + 1
      end
      if v and pressed_arr[k] then
         succ = succ + 1
      end
      if not v and pressed_arr[k] then
         mistake = mistake + 1
      end
   end
   print(string.format("calcPercent() count = %d, succ = %d, mistake = %d", count, succ, mistake))
   return succ / count - mistake / count
end

function percentage(signals, pressed)
   local p1, p2, p3, p4
   p1 = calcPercent(signals.eq.sound, pressed.sound)
   p2 = calcPercent(signals.eq.color, pressed.color)
   p3 = calcPercent(signals.eq.form, pressed.form)
   p4 = calcPercent(signals.eq.pos, pressed.pos)
   local percent = {
      sound = p1 > 0.0 and p1 or 0.0,
      color = p2 > 0.0 and p2 or 0.0,
      form = p3 > 0.0 and p3 or 0.0,
      pos = p4 > 0.0 and p4 or 0.0,
   }
   percent.common = (percent.sound + percent.color + percent.form + percent.form) / 4
   return percent
end





















function storeUI()





   return {}
end

function restoreUI(g)
   if g == nil then
      error("g == nil")
   end


end

function compareDates(now, date)
   local ranges = {
      { 0, 6, i18n("today") },
      { 7, 24, i18n("yesterday") },
      { 25, 48, i18n("twoDays") },
      { 49, 72, i18n("threeDays") },
      { 73, 96, i18n("fourDays") },
      { 97, 24 * 7, i18n("lastWeek") },
      { 24 * 7 + 1, 24 * 14, i18n("lastTwoWeek") },
      { 24 * 14 + 1, 24 * 30, i18n("lastMonth") },
      { 24 * 30 + 1, 24 * 365, i18n("lastYear") },
   }
   local result = i18n("moreTime")


   local t1, t2, diff = now.yday * 24 + now.hour, date.yday * 24 + date.hour, 0.
   if date.year == now.year then
      diff = t1 - t2
   else
      diff = (now.year - date.year) * 365 * 24 - (t1 - t2)
   end
   for _, v in ipairs(ranges) do
      local v1, v2 = v[1], v[2]
      if diff >= v1 and diff <= v2 then
         result = v[3]
         break
      end
   end

   return result
end

function getDefaultSettings()
   print("getDefaultSettings")
   return {
      volume = 0.2,
      firstRun = true,
   }
end


function readSettings()
   local data, _ = love.filesystem.read(SETTINGS_FILENAME)
   local result

   if data then
      local ok, res = serpent.load(data)
      if not ok then
         result = getDefaultSettings()
      else
         result = res
      end
   else
      result = getDefaultSettings()
   end

   return result
end

function writeSettings()
   local serialized = serpent.dump(settings)
   local ok, msg = love.filesystem.write(SETTINGS_FILENAME, serialized)
   if not ok then
      print("Could write settings to ", SETTINGS_FILENAME, " file", msg)
   end
end

function isPositionEqual(a, b)
   return a.x == a.y and b.x == b.y
end
