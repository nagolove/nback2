
local g = love.graphics

layout = {
    bottom_line_y,
    font = g.newFont(13),
}

function layout.draw()
    g.setFont(layout.font)
    g.print("layout", 100, 100)
end

return layout
