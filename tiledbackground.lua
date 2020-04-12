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
    gr.setCanvas(self.canvas)
    local cam = require "camera".new()
    cam:zoom(0.3)
    print("cam.scale", cam.scale)
    --local maxi, maxj = math.floor(w / self.img:getHeight() * cam.scale), math.floor(h / self.img:getWidth() * cam.scale)
    local maxi, maxj = 10, 10
    print("maxi, maxj", maxi, maxj)
    cam:move(w / 2, h / 2)
    cam:attach()
    for i = 0, maxi do
        for j = 0, maxj do
            gr.draw(self.img, j * self.img:getWidth(), i * self.img:getHeight())
        end
    end
    cam:detach()
    gr.setCanvas()

    self.canvas:newImageData():encode("png", "tiledback.png")
end

function TiledBackround:draw()
    gr.setColor(1, 1, 1, 1)
    gr.draw(self.canvas)
end

function TiledBackround:resize(neww, newh)
    error("Not yet implemented")
end

return TiledBackround
