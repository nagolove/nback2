local class = require "libs/30log"
local lg = love.graphics
local geo = require "geo"

local ruler = class("ruler")

function ruler:init(x1, y1, x2, y2)
    self.x1, self.y1, self.x2, self.y2 = x1, y1, x2, y2
    print(string.format("Ruler created at (%d, %d), (%d, %d)", x1, y1, x2, y2))
    self.rad = 4
    self.color = {200, 100, 135}
    self.ccolor = {20, 80, 135}
    self.lcolor = {80, 20, 135}
    self.visible = true
    self.pinned = false
    self.infirst = false
    self.insecond = false
    self.linewidth = 2
end

function ruler:mousepressed(x, y, button, istouch)
    self.pinned = true
end
    
function ruler:mousereleased(x, y, button, istouch)
    self.pinned = false
end

function ruler:mousemoved(x, y, dx, dy, istouch)
    if self.pinned and self.infirst then
        self.x1 = self.x1 + dx
        self.y1 = self.y1 + dy
    end
    if self.pinned and self.insecond then
        self.x2 = self.x2 + dx
        self.y2 = self.y2 + dy
    end
    self.infirst = geo.isPointInCircle(x, y, self.x1, self.y1, self.rad)
    self.insecond = geo.isPointInCircle(x, y, self.x2, self.y2, self.rad)
end

function ruler:draw()
    if not self.visible then return end

    local lineStyle = lg.getLineStyle()
    local lineWidth = lg.getLineWidth()
    local lineColor = pack(lg.getColor())
    lg.setLineStyle("smooth")
    lg.setLineWidth(self.linewidth)

    local x, y = love.mouse.getPosition()
    if geo.isPointInCircle(x, y, self.x1, self.y1, self.rad) then
        lg.setColor(255 - self.ccolor[1], 255 - self.ccolor[2], 255 - self.ccolor[3], 255)
    else    
        lg.setColor(self.ccolor)
    end
    lg.circle("fill", self.x1, self.y1, self.rad)

    if geo.isPointInCircle(x, y, self.x2, self.y2, self.rad) then
        lg.setColor(255 - self.ccolor[1], 255 - self.ccolor[2], 255 - self.ccolor[3], 255)
    else    
        lg.setColor(self.ccolor)
    end
    lg.circle("fill", self.x2, self.y2, self.rad)

    lg.setColor(self.lcolor)
    lg.line(self.x1, self.y1, self.x2, self.y2)

    lg.print(string.format("%d px", geo.dist(self.x1, self.y1, self.x2, self.y2)), self.x1, self.y1)
    -- black points in center of circles
    lg.setColor(0, 0, 0, 255)
    lg.circle("fill", self.x1, self.y1, 1)
    lg.circle("fill", self.x2, self.y2, 1)

    lg.setLineWidth(lineWidth)
    lg.setLineStyle(lineStyle)
    lg.setColor(unpack(lineColor))

    function tooltipCoordinates(x, y)
        local height = lg.getFont():getHeight()
        lg.print(string.format("(%d, %d)", x, y), x - 2, y - height - 2)
    end

    if self.infirst then
        tooltipCoordinates(self.x1, self.y1)
    end
    if self.insecond then
        tooltipCoordinates(self.x2, self.y2)
    end
end

return ruler
