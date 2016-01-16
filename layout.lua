local inspect = require "inspect"
local pallete = require "pallete"

local g = love.graphics

layout = {
    bottom_line_y, -- How to put piexls here?
    font = g.newFont(13),
}

function split(name, sublayout, linetype)
end

function draw_rect(layout)
    print("-- draw_rect")
    for k, v in pairs(layout) do
        if type(v) == "table" and v.x ~= nil and v.y ~= nil and v.w ~= nil and v.h ~= nil then

            local l = v

            g.push("all")
            --g.scale(0.5, 0.5)
            g.setColor(pallete.debug_line)
            g.setLineWidth(3)
            g.rectangle("line", l.x, l.y, l.w, l.h)
            g.pop()

            print(string.format("%s (%d, %d, %d, %d)", k, l.x, l.y, l.w, l.h))

            draw_rect(v)
        end
    end
    print("--")
end

function layout.draw()
    g.setFont(layout.font)
    g.print("layout", 100, 100)

    draw_rect(layout)
end

function splitv(layout, ...)
    assert((#{...}) % 2 == 0)

    local a = {...}

    -- sum of numeric arguments should be equal 1
    local widht_sum = 0
    for i = (#a / 2) + 1, #a, 1 do
        widht_sum = widht_sum + a[i]
    end
    assert(widht_sum == 1)

    local columns_count = #a / 2

    for i = 1, #a / 2, 1 do
        local koef = a[#a / 2 + i]
        local t = { 
            x = (1 - koef) * layout.w, 
            y = 0, 
            w = koef * layout.w, 
            h = layout.h
        }
        print("put a[i]", a[i])
        layout[a[i]] = t
    end

end

function splith(t, ...)
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
