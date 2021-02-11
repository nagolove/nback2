require "love"
local gr = love.graphics

function write2Canvas(func: function)
    local fname = "draft.png"
    local image: love.graphics.Image
    pcall(function()
        image = gr.newImage(fname)
    end)
    local canvas = gr.newCanvas()
    gr.setCanvas(canvas)
    if image then
        gr.setColor{0, 0, 0}
        gr.draw(image as love.graphics.Drawable)
    end
    func()
    gr.setCanvas()
    local imgdata = canvas:newImageData()
    imgdata:encode("png", fname)
end


