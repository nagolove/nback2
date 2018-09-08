local inspect = require "libs.inspect"
local lume = require "libs.lume"

local pallete = require "pallete"
local nback = require "nback"
local g = love.graphics
local dbg = require "dbg"

local pviewer = {
    scroll_tip_text = "For scrolling table use ↓↑ arrows",
    header_text = "", 
    border = 80, --y axis border in pixels for drawing chart
    scrollx = 0,

    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
    scrool_tip_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 13),
    selected_item = 2,
    start_line = 1,
    sorted_by_column_num = 1
}

local w, h = g.getDimensions()
local columns_name = {"date", "nlevel", "rating", "pause"}

function pviewer.init()
    local tmp, size = love.filesystem.read(nback.save_name)
    if tmp ~= nil then
        pviewer.data = lume.deserialize(tmp)
    else
        pviewer.data = {}
    end
    print("*** begining of pviewer.data ***")
    print(inspect(pviewer.data))
    print("*** end of pviewer.data ***")
    pviewer.sort_by_column(1)
    pviewer.rt = g.newCanvas(w, h, {format = "normal", msaa = 4})
    if not pviewer then
        error("Canvas not supported!")
    end
end

function pviewer.resize(neww, newh)
    w = neww
    h = newh
    print(string.format("pviewer resized to %d * %d", neww, newh))
end

function draw_chart(k, j)

    local deltax = 0

    -- draw column of table pviewer.data, from index k, to index j with func(v) access function
    function draw_column(func)
        local oldcolor = {g.getColor()}
        local dx = 0
        local y = 100 -- start y position
        if k + j > #pviewer.data then
            j = #pviewer.data
        end
        for i = k, j do
            local s = func(pviewer.data[i])
            dx = math.max(dx, pviewer.font:getWidth(s))
            if pviewer.selected_item == k then
                g.setColor({1, 1, 1, 1})
            else
                g.setColor(oldcolor)
            end
            g.print(s, deltax, y)
            y = y + pviewer.font:getHeight()
            --print(k, inspect(v))
        end
        --print("len " .. #pviewer.data)
        g.setColor(oldcolor)
        deltax = deltax + dx
    end

    g.setFont(pviewer.font)

    g.setColor(pallete.chart)
    draw_column(function(v) return string.format("%.2d.%.2d.%d", v.date.day, v.date.month, v.date.year) end)

    g.setColor(pallete.header)
    draw_column(function(v) return " / " end)

    g.setColor(pallete.chart)
    draw_column(function(v) if v.nlevel then return string.format("%d", v.nlevel) else return "-" end end)

    g.setColor(pallete.header)
    draw_column(function(v) return " / " end)

    g.setColor(pallete.chart)
    draw_column(function(v) if v.percent then return string.format("%.2f", v.percent) else return "-" end end)

    g.setColor(pallete.header)
    draw_column(function(v) return " / " end)

    g.setColor(pallete.chart)
    draw_column(function(v) if v and v.pause then return string.format("%.2f", v.pause) else return "_" end end)

    return deltax
end

function draw_chart_header(r)
    --g.setColor(pallete.header)
    g.setFont(pviewer.font)
    local tbl = {}
    for k, v in pairs(columns_name) do
        if k == pviewer.sorted_by_column_num then
            tbl[#tbl + 1] = pallete.active
            --tbl[#tbl + 1] = {0, 1, 1}
        else
            tbl[#tbl + 1] = pallete.header
            --tbl[#tbl + 1] = {1, 0, 1}
        end
        if k ~= #columns_name then
            tbl[#tbl + 1] = v .. " / "
        else
            tbl[#tbl + 1] = v
        end
    end
    g.printf(tbl, r.x1, r.y1 - pviewer.border / 2, r.x2 - r.x1, "center")
end

function pviewer.draw()
    local r = {x1 = pviewer.border, y1 = pviewer.border, x2 = w - pviewer.border, y2 = h - pviewer.border}

    g.push("all")

    --drawing scroll_tip_text
    g.setColor(pallete.scroll_tip_text)
    g.setFont(pviewer.scrool_tip_font)
    g.printf(pviewer.scroll_tip_text, r.x1, r.y2 + pviewer.border / 2, r.x2 - r.x1, "center")
    -- 

    draw_chart_header(r)

    function get_max_lines_printed()
        return (h - 100) / pviewer.font:getHeight()
    end

    g.setColor({1, 1, 1, 1})
    g.setCanvas(pviewer.rt)
    g.clear()

    local chart_width = draw_chart(pviewer.start_line, pviewer.start_line + get_max_lines_printed())
    local x = (w - chart_width) / 2
    g.setCanvas()

    g.setColor({1, 1, 1, 1})
    g.draw(pviewer.rt, (w - chart_width) / 2, y1)

    --XXX
    g.setColor({1, 1, 1, 1})
    --g.printf("Escape - to go back", 0, 20, w, "center")
    
    dbg.clear()
    dbg.print_text("fps " .. love.timer.getFPS())
    dbg.print_text(string.format("sorted by %s = %d", columns_name[pviewer.sorted_by_column_num], pviewer.sorted_by_column_num))

    g.pop()
end

function pviewer.sort_by_column(idx)
    -- TODO sorting
    pviewer.sorted_by_column_num = idx
    --[[
       [table.sort(pviewer.data, function(a, b)
       [    -- local columns_name = {"date", "nlevel", "rating", "pause"}
       [    if columns_name[idx] == "date" then
       [        --TODO not implemented
       [    elseif columns_name[idx] == "nlevel" then
       [        --TODO not implemented
       [    elseif columns_name[idx] == "rating" then
       [        --TODO not implemented
       [    elseif columns_name[idx] == "pause" then
       [        --TODO not implemented
       [    end
       [    return false
       [end)
       ]]
end

function pviewer.keypressed(key)
    if key == "escape" then
        states.pop()
    elseif key == "left" then
        if pviewer.sorted_by_column_num - 1 < 1 then
            pviewer.sort_by_column(#columns_name)
        else
            pviewer.sort_by_column(pviewer.sorted_by_column_num - 1)
        end
    elseif key == "right" then
        if pviewer.sorted_by_column_num + 1 > #columns_name then
            pviewer.sort_by_column(1)
        else
            pviewer.sort_by_column(pviewer.sorted_by_column_num + 1)
        end
    elseif key == "return" or key == "space" then
    end
end

function pviewer.move_up()
    if pviewer.start_line > 1 then
        pviewer.start_line = pviewer.start_line - 1
    end
end

function pviewer.move_down()
    if pviewer.start_line < #pviewer.data then
        pviewer.start_line = pviewer.start_line + 1
    end
end

function pviewer.update(dt)
    local kb = love.keyboard
    if kb.isDown("up") then
        pviewer.move_up()
    elseif kb.isDown("down") then
        pviewer.move_down()
    end
end

return pviewer
