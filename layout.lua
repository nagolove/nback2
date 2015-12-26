
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

function splith(table, ...)
    assert((#{...}) % 2 == 0)
    --print((#...  - 1) % 2)
    --assert((#...  - 1) % 2 == 0)
    local widht_sum = 0
    --for i, v in ipairs({...}) do
    local last = #{...}
    local a = {...}
    for i = (#a / 2), #a, 1 do
        print(i, v)
        widht_sum = widht_sum + tonumber(a[i])
    end
    print("--")
    print("widht_sum", widht_sum)
end

function splitv()
end

function layout.init()
    splitv(layout, "left", "center", "right", 0.3, 0.4, 0.3)
    splith(layout, "top", "center", "bottom", 0.2, 0.6, 0.2)
end

return layout
