require "love"
local gr = love.graphics

global type TiledBackround = record
    new: function(): TiledBackround
    prepareDrawing: function(TiledBackround)
    draw: function(TiledBackround, number)
    resize: function(TiledBackround, number, number)

    img: love.graphics.Texture
    canvas: love.graphics.Canvas
end

local TiledBackround_mt: metatable<TiledBackround> = {
    __index = TiledBackround
}
--TiledBackround.__index = TiledBackround

function TiledBackround.new(): TiledBackround
    --local self: TiledBackround = setmetatable({}, TiledBackround)
    --local self: TiledBackround = setmetatable({} as TiledBackround, {})
    local self = setmetatable({} as TiledBackround, TiledBackround_mt)
    self.img = gr.newImage("gfx/tile1.png") as love.graphics.Texture
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
            gr.draw(self.img as love.graphics.Drawable, j * self.img:getWidth(), i * self.img:getHeight())
        end
    end
    cam:detach()
    gr.setCanvas()
    --self.canvas:newImageData():encode("png", "tiledback.png")
end

function TiledBackround:draw(alpha: number)
    gr.clear(0, 0, 0, 0)
    gr.setColor(1, 1, 1, alpha or 1)
    gr.draw(self.canvas as love.graphics.Drawable, 0, 0)
end

function TiledBackround:resize(_: number, _: number)
    self:prepareDrawing()
end

--return TiledBackround
global tiledback: TiledBackround = TiledBackround.new()

