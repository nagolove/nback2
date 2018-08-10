local inspect = require "libs.inspect"
local lume = require "libs.lume"

local pallete = require "pallete"
local nback = require "nback"

local pviewer = {
    scroll_tip_text = "For scrolling table use ↓↑ arrows",
    header_text = "", 
    data = {}, -- games history which loading from file
    border = 80, --y axis border in pixels for drawing chart
    scrollx = 0,

    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
    scrool_tip_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 13),
}

function pviewer.init()
    local tmp, size = love.filesystem.read(nback.save_name)
    if tmp ~= nil then
        pviewer.data = lume.deserialize(tmp)
    end
    --print(inspect(pviewer.data))

    pviewer.rt = love.graphics.newCanvas(love.graphics.getDimensions())
end

function draw_chart()

    local deltax = 0
    local g = love.graphics

    function draw_column(color, func)
        g.setFont(pviewer.font)
        g.setColor(color)
        --g.setColor(pallete.header)
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


    draw_column(pallete.chart, function(k, v)
        return string.format("%.2d.%.2d.%d", 
        v.date.day,
        v.date.month,
        v.date.year)
    end)
    draw_column(pallete.header, function(k, v) return " / " end)
    draw_column(pallete.chart, function(k, v)
        return string.format("%d", v.nlevel)
    end)
    draw_column(pallete.header, function(k, v) return " / " end)
    draw_column(pallete.chart, function(k, v)
        return string.format("%.2d%%", v.statistic.success)
    end)
    draw_column(pallete.header, function(k, v) return " / " end)
    draw_column(pallete.chart, function(k, v)
        if v.use_sound then
            return "yes"
        else
            return "no"
        end
    end)

    return deltax
end

function pviewer.draw()
    local g = love.graphics
    local w, h = g.getDimensions()
    local r = {x1 = pviewer.border, y1 = pviewer.border, x2 = w - pviewer.border, y2 = h - pviewer.border}

    g.push("all")

    g.setBackgroundColor(pallete.background)
    g.clear()

    --drawing scroll_tip_text
    g.setColor(pallete.scroll_tip_text)
    g.setFont(pviewer.scrool_tip_font)
    g.printf(pviewer.scroll_tip_text, r.x1, r.y2 + pviewer.border / 2, r.x2 - r.x1, "center")
    -- 

    --drawing chart header
    g.setColor(pallete.header)
    g.setFont(pviewer.font)
    g.printf("date / nlevel / rating / with sound", r.x1, r.y1 - pviewer.border / 2, r.x2 - r.x1, "center")
    -- 

    --drawing chart
    g.setCanvas(pviewer.rt)
    print("pviever " .. inspect(pviewer))
    --pviewer.rt:clear()
   

    
    --local chart_width = draw_chart()



    --local x = (w - chart_width) / 2
    --g.setCanvas()
    --g.setScissor(x, pviewer.border, chart_width, h - 2 * pviewer.border)
    --g.draw(pviewer.rt, x, pviewer.border + pviewer.scrollx)
    --g.setScissor()
    --

    --XXX
    --g.printf("Escape - to go back", 0, pviewer.font:getHeight(), w, "center")

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
