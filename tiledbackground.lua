local gr = love.graphics

local TiledBackround = {}
TiledBackround.__index = TiledBackround

function TiledBackround:new()
    local self = setmetatable({}, TiledBackround)
    self.img = gr.newImage("gfx/tile1.png")
    self:prepareDrawing()

    return self
end

function TiledBackround:prepareDrawing()
    local w, h = gr.getDimensions()
    self.canvas = gr.newCanvas(w, h)
    gr.clear(0, 0, 0, 0)
    gr.setColor{1, 1, 1}
    gr.setCanvas(self.canvas)
    local cam = require "camera".new()
    cam:zoom(0.12)
    local maxi, maxj = math.ceil(h / (self.img:getHeight() * cam.scale)), math.ceil(w / (self.img:getWidth() * cam.scale))
    local k = 1 / cam.scale
    cam:lookAt((w / 2) * k, (h / 2) * k)
    cam:attach()
    for i = 0, maxi do
        for j = 0, maxj do
            gr.draw(self.img, j * self.img:getWidth(), i * self.img:getHeight())
        end
    end
    cam:detach()
    gr.setCanvas()
    --self.canvas:newImageData():encode("png", "tiledback.png")
end

function TiledBackround:draw()
    gr.clear(0, 0, 0, 0)
    gr.setColor(1, 1, 1, 1)
    gr.draw(self.canvas, 0, 0)
end

function TiledBackround:resize(neww, newh)
    self:prepareDrawing()
end

return TiledBackround
