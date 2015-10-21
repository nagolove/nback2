﻿local inspect = require "inspect"
local nback = require "nback"
local lume = require "lume"

local colors = require "colors"

local pviewer = {
    scroll_tip_text = "For scrolling table use ↓↑ arrows",
    header_text = "", 
    data = {}, -- games history which loading from file
    border = 80, --y axis border in pixels for drawing chart

    update = function() end,

    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
    scrool_tip_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 13),
}

function pviewer.load()
    local tmp, size = love.filesystem.read(nback.save_name)
    if tmp ~= nil then
        pviewer.data = lume.deserialize(tmp)
    end
    print(inspect(pviewer.data))

    pviewer.rt = love.graphics.newCanvas(love.graphics.getDimensions())
end

function draw_chart()

    local deltax = 0
    local g = love.graphics

    function draw_column(color, func)
        g.setFont(pviewer.font)
        g.setColor(color)
        --g.setColor(colors.header)
        local dx = 0
        local y = 0
        for k, v in ipairs(pviewer.data) do
            local s = func(k, v)
            dx = math.max(dx, pviewer.font:getWidth(s))
            g.print(s, deltax, y)
            y = y + pviewer.font:getHeight()
        end
        deltax = deltax + dx
    end

    function draw_slash()
        draw_column(colors.header, function(k, v)
            return " / "
        end)
    end

    draw_column(colors.chart, function(k, v)
        return string.format("%.2d.%.2d.%d", 
        v.date.day,
        v.date.month,
        v.date.year)
    end)
    draw_slash()
    draw_column(colors.chart, function(k, v)
        return string.format("%d", v.nlevel)
    end)
    draw_slash()
    draw_column(colors.chart, function(k, v)
        if v.use_sound then
            return "yes"
        else
            return "no"
        end
    end)
    draw_slash()
    draw_column(colors.chart, function(k, v)
        return string.format("%.2d %%", v.stat.hits)
    end)

    return deltax
end

function pviewer.draw()
    local g = love.graphics
    local w, h = g.getDimensions()
    local r = {x1 = pviewer.border, y1 = pviewer.border, x2 = w - pviewer.border, y2 = h - pviewer.border}

    g.push("all")

    g.setBackgroundColor(colors.background)
    g.clear()

    --drawing scroll_tip_text
    g.setColor(colors.scroll_tip_text)
    g.setFont(pviewer.scrool_tip_font)
    g.printf(pviewer.scroll_tip_text, r.x1, r.y2 + pviewer.border / 2, r.x2 - r.x1, "center")
    -- 

    --drawing chart header
    g.setColor(colors.header)
    g.setFont(pviewer.font)
    g.printf("date / nlevel / rating / with sound", r.x1, r.y1 - pviewer.border / 2, r.x2 - r.x1, "center")
    -- 

    --drawing chart
    g.setCanvas(pviewer.rt)
    pviewer.rt:clear()
    local chart_width = draw_chart()
    g.setCanvas()
    g.draw(pviewer.rt, (w - chart_width) / 2, pviewer.border)
    --

    g.pop()
end

function pviewer.keypressed(key)
    if key == "escape" then
        states.pop()
    end
end

return pviewer
