local inspect = require "inspect"

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

    local a = {...}

    -- sum of numeric arguments should be equal 1
    local widht_sum = 0
    for i = (#a / 2) + 1, #a, 1 do
        widht_sum = widht_sum + a[i]
    end
    assert(widht_sum == 1)

    --TODO Put your great code here!
    for i = 1, #a / 2, 1 do
        print(i, a[i])
        --XXX Not work properly
        table["" .. tostring(table[i])] = 1
    end
end

function splitv(t, ...)
    t.k = 1
    t["l"] = 1
end

function check_layout(l)
    print("-- checking layout format")
    print(inspect(layout))
    print("--")
end

function layout.intersect(l, fname, sname)
end

function layout.init()
    layout.x = 0
    layout.y = 0
    layout.w, layout.h = g.getDimensions()

    splitv(layout, "left", "center", "right", 0.3, 0.4, 0.3)
    splith(layout, "top", "center", "bottom", 0.2, 0.6, 0.2)

    check_layout(layout)
end

return layout
