
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

function print_table(t)
    print("-- table")
    for i, v in ipairs(t) do
        print(i, v)
    end
    print("--")
end

function splith(table, ...)
    assert((#{...}) % 2 == 0)

    local a = {...}

    -- sum of arguments should be equal 1
    local widht_sum = 0
    for i = (#a / 2) + 1, #a, 1 do
        widht_sum = widht_sum + a[i]
    end
    assert(widht_sum == 1)

    print("--", widht_sum)
    print("widht_sum", widht_sum)
end

function splitv()
end

function layout.init()
    splitv(layout, "left", "center", "right", 0.3, 0.4, 0.3)
    splith(layout, "top", "center", "bottom", 0.2, 0.6, 0.2)
end

return layout
