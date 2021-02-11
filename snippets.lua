local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pcall = _tl_compat and _tl_compat.pcall or pcall; require("love")
local gr = love.graphics

function write2Canvas(func)
   local fname = "draft.png"
   local image
   pcall(function()
      image = gr.newImage(fname)
   end)
   local canvas = gr.newCanvas()
   gr.setCanvas(canvas)
   if image then
      gr.setColor({ 0, 0, 0 })
      gr.draw(image)
   end
   func()
   gr.setCanvas()
   local imgdata = canvas:newImageData()
   imgdata:encode("png", fname)
end
