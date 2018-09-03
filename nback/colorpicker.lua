local class = require "libs.30log"
local suit = require "libs.suit"
local inspect = require "libs.inspect"
local lg = love.graphics

local colorpicker = class("colorpicker")

function colorpicker:init()
    print(string.format("Colorpicker created"))
    self.color = {0.5, 0.5, 0.5, 1}
    self.rslider = {value = self.color[1], min = 0, max = 1}
    self.gslider = {value = self.color[2], min = 0, max = 1}
    self.bslider = {value = self.color[3], min = 0, max = 1}
    self.aslider = {value = self.color[4], min = 0, max = 1}
end

function colorpicker:mousepressed(x, y, button, istouch)
    if button == 2 then
        print("color copied to clpbrd")
        love.system.setClipboardText(string.format("{%s, %s, %s, %s}", self.color[1], self.color[2], self.color[3], self.color[4]))
    end
end
    
function colorpicker:mousereleased(x, y, button, istouch)
end

function colorpicker:mousemoved(x, y, dx, dy, istouch)
end

function pack(...)
    return {...}
end

function colorpicker:draw()
    local pickerwidth = 200
    local pickerheight = 128
    local w, h = lg.getDimensions()
    local cornerx, cornery = (w - pickerwidth) / 2, h / 3
    local old = pack(lg.getColor())
    --local lc = pack(lg.getColor(
    --print("getColor()", inspect(lc))
    --print("self.color", inspect(self.color))
    lg.setColor(self.color)
    lg.rectangle("fill", cornerx, cornery, pickerwidth, pickerheight, 3, 3)
    lg.setColor(old)

    cornery = cornery + pickerheight

    local sliderh = 16
    suit.Slider(self.rslider, cornerx, cornery, pickerwidth, sliderh)
    lg.print(string.format("%3f", self.color[1]), cornerx + pickerwidth, cornery)
    cornery = cornery + sliderh
    suit.Slider(self.gslider, cornerx, cornery, pickerwidth, sliderh)
    lg.print(string.format("%3f", self.color[2]), cornerx + pickerwidth, cornery)
    cornery = cornery + sliderh
    suit.Slider(self.bslider, cornerx, cornery, pickerwidth, sliderh)
    lg.print(string.format("%3f", self.color[3]), cornerx + pickerwidth, cornery)
    cornery = cornery + sliderh
    suit.Slider(self.aslider, cornerx, cornery, pickerwidth, sliderh)
    if self.color[4] then   
        lg.print(string.format("%3f", self.color[4]), cornerx + pickerwidth, cornery)
    end

    suit.draw()
end

function colorpicker:update(dt)
    self.color = {self.rslider.value, self.gslider.value, self.bslider.value}
end

return colorpicker

