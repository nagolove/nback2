local inspect = require "libs.inspect"
local lume = require "libs.lume"

local pallete = require "pallete"
local nback = require "nback"
local g = love.graphics
local dbg = require "dbg"

local pviewer = {
    scroll_tip_text = "For scrolling table use ↓↑ arrows",
    header_text = "", 
    data = {}, -- games history which loads from file
    border = 80, --y axis border in pixels for drawing chart
    scrollx = 0,

    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
    scrool_tip_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 13),
}

local w, h = g.getDimensions()

function pviewer.init()
    local tmp, size = love.filesystem.read(nback.save_name)
    if tmp ~= nil then
        pviewer.data = lume.deserialize(tmp)
    end
    print("*** begining of pviewer.data ***")
    print(inspect(pviewer.data))
    print("*** end of pviewer.data ***")

    pviewer.rt = love.graphics.newCanvas(w, h, {format = "normal", msaa = 2})
end

function draw_chart()

    local deltax = 0

    function draw_column(color, func)
        g.setFont(pviewer.font)
        g.setColor(color)
        --g.setColor(pallete.header)
        local dx = 0
        local y = 0
        --print(inspect(pviewer.data))
        for k, v in ipairs(pviewer.data) do
            if k > 10 then break end
            local s = func(k, v)
            dx = math.max(dx, pviewer.font:getWidth(s))
            g.print(s, deltax, y)
            y = y + pviewer.font:getHeight()
            print(k, inspect(v))
        end
        --print("len " .. #pviewer.data)
        deltax = deltax + dx
    end


    draw_column(pallete.chart, function(k, v)
        return string.format("%.2d.%.2d.%d", v.date.day, v.date.month, v.date.year)
    end)
    draw_column(pallete.header, function(k, v) return " / " end)
    draw_column(pallete.chart, function(k, v)
        if v.level then
            return string.format("%d", v.nlevel)
        else
            return "-" 
        end
    end)
    draw_column(pallete.header, function(k, v) return " / " end)
    draw_column(pallete.chart, function(k, v)
        if v.percent then
            return string.format("%.2d%%", v.percent)
        else
            return "-"
        end
    end)
    draw_column(pallete.header, function(k, v) return " / " end)
    draw_column(pallete.chart, function(k, v)
        if v and v.pause then
            return string.format("%d", v.pause)
        else
            return "_"
        end
    end)

    return deltax
end

function pviewer.draw()
    local g = love.graphics
    local w, h = g.getDimensions()
    local r = {x1 = pviewer.border, y1 = pviewer.border, x2 = w - pviewer.border, y2 = h - pviewer.border}

    g.push("all")

    --drawing scroll_tip_text
    g.setColor(pallete.scroll_tip_text)
    g.setFont(pviewer.scrool_tip_font)
    g.printf(pviewer.scroll_tip_text, r.x1, r.y2 + pviewer.border / 2, r.x2 - r.x1, "center")
    -- 

    --drawing chart header
    g.setColor(pallete.header)
    g.setFont(pviewer.font)
    g.printf("date / nlevel / rating", r.x1, r.y1 - pviewer.border / 2, r.x2 - r.x1, "center")
    -- 

    --drawing chart
    g.setCanvas(pviewer.rt)
    --print("pviever " .. inspect(pviewer))
    g.clear()

    local chart_width = draw_chart()

    local x = (w - chart_width) / 2
    g.setCanvas()
    g.setScissor(x, pviewer.border, chart_width, h - 2 * pviewer.border)
    g.draw(pviewer.rt, x, pviewer.border + pviewer.scrollx)
    g.setScissor()
    --

    --XXX
    --g.printf("Escape - to go back", 0, pviewer.font:getHeight(), w, "center")
    dbg.clear()
    dbg.print_text("fps " .. love.timer.getFPS())

    g.pop()
end

function pviewer.keypressed(key)
    if key == "escape" then
        states.pop()
    end
end

function pviewer.update(dt)
    local kb = love.keyboard
    local l = #pviewer.data / 2
    if kb.isDown("up") then
        local t = pviewer.scrollx - pviewer.font:getHeight() 
        if t >= - l * pviewer.font:getHeight() then
            pviewer.scrollx = t
        end
    elseif kb.isDown("down") then
        local t = pviewer.scrollx + pviewer.font:getHeight() 
        if t <= l * pviewer.font:getHeight() then
            pviewer.scrollx = t
        end
    end
end

return pviewer
