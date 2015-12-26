
local g = love.graphics

layout = {
    bottom_line_y, --How to put piexls here?
    font = g.newFont(13),
}

function split(name, sublayout, linetype)
end

function layout.draw()
    g.setFont(layout.font)
    g.print("layout", 100, 100)
end

function splith()
end

function splitv()
end

function layout.init()
    splitv(layout, "left", "center", "right", 0.3, 0.4, 0.3)
    splith(layout, "top", "center", "bottom", 0.2, 0.6, 0.2)
end

return layout
