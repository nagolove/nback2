--[[
Object-oriented module for drawing multiline text.

local kons = require "kons"
local linesbuffer = kons(x, y) -- initial coordinates of drawing.

internal variables:
linesbuffer:height -- height in pixels of drawed text. Updated by :draw() call.
methods:
* linesbuffer:draw() -- draw first lines pushed by push_text_i(). After it drawing lines pushed
by push()
* linesbuffer:push("hello", 1) -- push text to screeen for 1 second
* linesbuffer:pushi("fps" .. fps) -- push text to screen for one frame
* linesbuffer:clear() -- full clear of console content
* linesbuffer:show() -- show or hide text output by changing internal flag 
* linesbuffer:update() -- internal mechanics computation. Paste to love.update()

Calls of push() and pushi() can be chained:
  linesbuf:pushi("dd"):pushi("bbb")
--]]

local inspect = require "inspect" -- XXX Debug purpose only

local g = love.graphics

local kons = {}
kons.__index = kons

function kons.new()
    local self = {
        color = {1, 1, 1},
        show = true,
        strings = {},
        strings_i = {},
        strings_num = 0,
        strings_i_num = 0,
    }
    return setmetatable(self, kons)
end

function kons:clear()
    self.strings_i = {}
    self.strings_i_num = 0
    self.strings = {}
    self.strings_num = 0
end

function kons:push(lifetime, text, ...)
    if type(lifetime) ~= "number" then
        error("First argument - cardinal value of text lifetime.")
    end
    assert(lifetime >= 0, string.format("Error: lifetime = %d < 0", lifetime))
    self.strings[self.strings_num + 1] = { 
        text = string.format(text, ...),
        lifetime = lifetime,
        timestamp = love.timer.getTime()
    }
    self.strings_num = self.strings_num + 1
    return self
end

function kons:pushi(text, ...)
    self.strings_i[self.strings_i_num + 1] = string.format(text, ...)
    self.strings_i_num = self.strings_i_num + 1
    return self
end

function kons:draw(x0, y0)
    if not y0 then y0 = 0 end
    if not x0 then x0 = 0 end

    if not self.show then return end

    local y = y0
    g.setColor(self.color)
    for k, v in pairs(self.strings_i) do
        g.print(v, x0, y)
        y = y + g.getFont():getHeight()
        self.strings_i[k] = nil -- XXX
    end
    self.strings_i_num = 0

    for _, v in pairs(self.strings) do
        --print("v.text " .. v.text)
        g.print(v.text, x0, y)
        y = y + g.getFont():getHeight()
    end

    self.height = math.abs(y - y0)
end

function kons:update()
    for k, v in pairs(self.strings) do
        local time = love.timer.getTime()
        --print("(time - v.timestamp) = ", (time - v.timestamp))
        v.lifetime = v.lifetime  - (time - v.timestamp)
        --print(string.format("lifetime %s, %s = %d", tostring(k), tostring(inspect(v)), v.lifetime))
        if v.lifetime <= 0 then
            self.strings[k] = self.strings[self.strings_num]
            self.strings[self.strings_num] = nil
            self.strings_num = self.strings_num - 1
        else
            v.timestamp = time
        end
    end
end

--return kons
return setmetatable(kons, { __call = function(cls, ...)
    return cls.new(...)
end})
