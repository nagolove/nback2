local pviewer = require "pviewer"
local nback = require "nback"
local help = require "help"
local pallete = require "pallete"

local g = love.graphics
local w, h = g.getDimensions()

local menu = {
    active_item = 1,
    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 72),
}

function menu.init()
    menu.items = {"play", "view progress", "help", "quit"}
    menu.actions = { 
        function() states.push(nback) end, 
        function() states.push(pviewer) end, 
        function() states.push(help) end, 
        function() love.event.quit() end,
    }
end

function menu.resize(neww, newh)
    w = neww
    h = newh
    print("Menu resized!")
end

function menu.keypressed(key)
    if key == "up" then
        if menu.active_item - 1 >= 1 then
            menu.active_item = menu.active_item - 1
        else
            menu.active_item = #menu.actions
        end
    elseif key == "down" then
        if menu.active_item + 1 <= #menu.items then
            menu.active_item = menu.active_item + 1
        else
            menu.active_item = 1
        end
    elseif key == "escape" then love.event.quit()
    elseif key == "return" or key == "space" then menu.actions[menu.active_item]()
    end
end

function menu.update() end

function menu.draw()
    g.clear(pallete.background)
    g.push("all")
    -- позиционирование посредине экрана
    y = (h - #menu.items * menu.font:getHeight()) / 2
    g.setFont(menu.font)
    for i, k in ipairs(menu.items) do
        if (menu.active_item == i) then
            g.setColor(pallete.inactive)
        else
            g.setColor(pallete.active)
        end
        g.printf(k, 0, y, w, "center")
        y = y + menu.font:getHeight()
    end
    g.pop()
end

return menu
