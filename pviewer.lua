local inspect = require "inspect"
local nback = require "nback"
local lume = require "lume"

local pviewer = {
    background_color = {20, 40, 80, 255},
    scroll_tip_text_color = {0, 240, 0, 255},
    scroll_tip_text = "For scrolling table use ↓↑ arrows",
    header_color = {255, 255, 0, 255},
    header_text = "", 
    chart_color = {200, 80, 80, 255},
    data = {},
    border = 80, --border in pixels for drawing chart
}

function pviewer.update()
end

function pviewer.load()
    local tmp, size = love.filesystem.read(nback.save_name)
    if tmp ~= nil then
        pviewer.data = lume.deserialize(tmp)
    end

    pviewer.font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 13)
    pviewer.scrool_tip_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 13)
    print(inspect(pviewer.data))

    pviewer.rt = love.graphics.newCanvas(love.graphics.getDimensions())
end

function draw_chart()
    local g = love.graphics

    g.setFont(pviewer.font)
    g.setColor(pviewer.chart_color)
    
    local y = pviewer.border
    local s

    for k, v in ipairs(pviewer.data) do
        s = string.format("%.2d.%.2d.%d", 
        v.date.day,
        v.date.month,
        v.date.year)
        g.print(s, 0, y)
        y = y + pviewer.font:getHeight()
    end

    local deltax = pviewer.font:getWidth(s)
    local y = pviewer.border
    g.setColor(pviewer.header_color)

    for k, v in ipairs(pviewer.data) do
        s = "  /  "
        g.print(s, 0 + deltax, y)
        y = y + pviewer.font:getHeight()
    end

    deltax = deltax + pviewer.font:getWidth(s)
    g.setColor(pviewer.chart_color)
    local y = pviewer.border

    for k, v in ipairs(pviewer.data) do
        s = string.format("%.2d %%", v.stat.hits)
        g.print(s, 0 + deltax, y)
        y = y + pviewer.font:getHeight()
    end
end

function pviewer.draw()
    local g = love.graphics
    local w, h = g.getDimensions()
    local r = {x1 = pviewer.border, y1 = pviewer.border, x2 = w - pviewer.border, y2 = h - pviewer.border}

    g.push("all")

    g.setBackgroundColor(pviewer.background_color)
    g.clear()

    --drawing scroll_tip_text
    g.setColor(pviewer.scroll_tip_text_color)
    g.setFont(pviewer.scrool_tip_font)
    g.printf(pviewer.scroll_tip_text, r.x1, r.y2 + pviewer.border / 2, r.x2 - r.x1, "center")
    -- 

    --drawing chart header
    g.setColor(pviewer.header_color)
    g.setFont(pviewer.font)
    g.printf("date / rating", r.x1, r.y1 - pviewer.border / 2, r.x2 - r.x1, "center")
    -- 

    --drawing chart
    g.setCanvas(pviewer.rt)
    pviewer.rt:clear()
    draw_chart()
    g.setCanvas()
    g.draw(pviewer.rt, (w - pviewer.font:getWidth("11.09.2015  /  00 %")) / 2, 0)
    --

    g.pop()
end

function pviewer.keypressed(key)
    if key == "escape" then
        current_state = menu
    end
end

return pviewer
