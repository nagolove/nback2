local inspect = require "inspect"
local pallete = require "pallete"

local g = love.graphics

layout = {
    bottom_line_y, -- How to put piexls here?
    font = g.newFont(13),
}

function draw(layout)
    --print("-- draw_rect")
    for k, v in pairs(layout) do
        if type(v) == "table" and v.x ~= nil and v.y ~= nil and v.w ~= nil and v.h ~= nil then

            local l = v

            g.push("all")

            g.setFont(layout.font)
            g.setColor(pallete.debug_font)
            g.printf(k, l.x, l.y, l.w, "center")

            g.setColor(pallete.debug_line)
            g.setLineWidth(3)
            g.rectangle("line", l.x, l.y, l.w, l.h)
            g.pop()

            --print(string.format("%s (%d, %d, %d, %d)", k, l.x, l.y, l.w, l.h))

            draw(v)
        end
    end
    --print("--")
end

function layout.draw()
    draw(layout)
end

function splitv(layout, ...)
    assert((#{...}) % 2 == 0)

    local a = {...}

    -- sum of numeric arguments should be equal 1
    local widht_sum = 0
    for i = (#a / 2) + 1, #a do
        widht_sum = widht_sum + a[i]
    end
    assert(widht_sum == 1)

    local columns_count = #a / 2
    local x = 0

    for i = 1, columns_count do
        local koef = a[columns_count + i]
        local t = { 
            x = x,
            y = 0, 
            w = koef * layout.w, 
            h = layout.h
        }
        x = x + koef * layout.w
        layout[a[i]] = t
    end
end

function splith(t, ...)
    assert((#{...}) % 2 == 0)

    local a = {...}

    -- sum of numeric arguments should be equal 1
    local height_sum = 0
    for i = (#a / 2) + 1, #a do
        height_sum = height_sum + a[i]
    end
    assert(height_sum == 1)

    local rows_count = #a / 2
    local y = 0

    for i = 1, rows_count do
        local koef = a[rows_count + i]
        local t = { 
            x = 0,
            y = y, 
            w = layout.w,
            h = koef * layout.h
        }
        y = y + koef * layout.h
        layout[a[i]] = t
    end
end

function check_layout(l)
    print("-- checking layout format")
    print(inspect(layout))
    print("--")
end

function layout.resize(neww, newh)
    layout.init()
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
