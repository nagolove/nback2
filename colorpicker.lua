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
    --self.canvas = lg.newCanvas(lg.getWidth(), lg.getHeight(), { type = "2d", format = "normal", msaa = 4})
    self.canvas = lg.newCanvas(lg.getWidth(), lg.getHeight())
    print("self.canvas = ", inspect(self.canvas))
end

-- button = 1 -- primary button
-- button = 2 -- secondary button
function colorpicker:mousepressed(x, y, button, istouch)
    -- беру пиксель пипетки
    if button == 2 then
        local imgdata = self.canvas:newImageData()
        local r, g, b, a = imgdata:getPixel(love.mouse.getPosition())
        self.color[1], self.color[2], self.color[3] = r, g, b
        self.rslider.value, self.gslider.value, self.bslider.value, self.bslider.value = r, g, b, a
    -- копирование в буфер обмена
    elseif button == 3 then
        print("color copied to clpbrd")
        love.system.setClipboardText(string.format("{%s, %s, %s}", self.color[1], self.color[2], self.color[3]))
    end
end
    
function colorpicker:mousereleased(x, y, button, istouch)
end

function colorpicker:mousemoved(x, y, dx, dy, istouch)
end

function colorpicker:draw(func)
    lg.setCanvas(self.canvas)
    lg.setColor(1, 1, 1, 1)
    func()
    lg.setCanvas()
    if self.canvas then lg.draw(self.canvas, 0, 0)  end

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
    --print("color = ", inspect(self.color))
    --print(string.format("color[1] = %f color[2] = %f color[3] = %f", self.color[1], self.color[2], self.color[3]))
end

return colorpicker

