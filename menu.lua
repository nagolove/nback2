local pviewer = require "pviewer"
local nback = require "nback"
local help = require "help"

local menu = {
    active_color = {255, 255, 255, 255},
    inactive_color = {100, 200, 70, 255},
    active_item = 1,
    background_color = {20, 40, 80, 255},
    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 32),
}

function menu.load()
    menu.items = {"play", "view progress", "help", "quit"}
    menu.actions = { menu.play, menu.view_progress, menu.help, menu.quit }
end

function menu.play()
    nback.enter()
    states.push(nback)
end

function menu.view_progress()
    pviewer.load()
    states.push(pviewer)
end

function menu.quit()
    love.event.quit()
end

function menu.help()
    states.push(help)
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
    elseif key == "escape" then
        menu.quit()
    elseif key == "return" or key == " " then
        menu.actions[menu.active_item]()
    end
end

function menu.update()
end

function menu.draw()
    local g = love.graphics
    g.push("all")

    w, h = g.getDimensions()
    y = (h - #menu.items * menu.font:getHeight()) / 2

    g.setFont(menu.font)
    g.setBackgroundColor(menu.background_color)
    g.clear()

    for i, k in ipairs(menu.items) do
        if (menu.active_item == i) then
            g.setColor(menu.inactive_color)
        else
            g.setColor(menu.active_color)
        end
        g.printf(k, 0, y, w, "center")
        y = y + menu.font:getHeight()
    end

    g.pop()
end

return menu
