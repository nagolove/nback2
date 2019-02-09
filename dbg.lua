
local dbg = {
    show = true
}

local g = love.graphics
local y = 0

function dbg.clear()
    y = 0
end

function dbg.print_text(text, x, y)
    if not x and not y then x, y = 0, 0 end
    if not dbg.show then return end

    local color = {g.getColor()}
    g.setColor(1, 0.5, 0)
    g.print(text, 5, y)
    local font = g.getFont()
    if font then
        y = y + font:getHeight()
    end
    g.setColor(unpack(color))
end

return dbg
