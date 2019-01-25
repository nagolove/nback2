local inspect = require "libs.inspect"
local pviewer = require "pviewer"
local nback = require "nback"
local help = require "help"
local pallete = require "pallete"
local timer = require "libs.Timer"

local g = love.graphics
local w, h = g.getDimensions()
local tile_size = 256

local menu = {
    active_item = 1,
    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 72),
    back_tile = love.graphics.newImage("gfx/IMG_20190111_115755.png")
}

function menu.init()
    menu.items = {"play", "view progress", "help", "quit"}
    menu.actions = { 
        function() states.push(nback) end, 
        function() states.push(pviewer) end, 
        function() states.push(help) end, 
        function() love.event.quit() end,
    }
    math.randomseed(os.time())
    menu.timer = timer()
    menu.alpha = 1
end

function menu.resize(neww, newh)
    w = neww
    h = newh
    menu.calc_rotation_grid()
end

function menu.calc_rotation_grid()
    menu.rot_grid = {}
    local i, j = 0, 0
    while i <= w do
        j = 0
        while j <= h do
            local v = math.random()
            local angle = 0
            if 0 <= v and v <= 0.25 then angle = 0
            elseif 0.25 < v and v < 0.5 then angle = math.pi
            elseif 0.5 < v and v < 0.75 then angle = math.pi * 3 / 4
            elseif 0.75 < v and v <= 1 then angle = math.pi * 2 end
            menu.rot_grid[#menu.rot_grid + 1] = angle
            j = j + tile_size
        end
        i = i + tile_size
    end
end

function menu.enter()
    menu.alpha = 0
    menu.timer:tween(2, menu, { alpha = 1}, "linear")
    print("menu.enter()")
    menu.calc_rotation_grid()
end

function menu.leave()
    print("menu.leave()")
    menu.calc_rotation_grid()
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

function menu.update(dt) 
    menu.timer:update(dt)
end

function menu.draw()
    g.push("all")

    g.clear(pallete.background)
    local quad = g.newQuad(0, 0, menu.back_tile:getWidth(), menu.back_tile:getHeight(), menu.back_tile:getWidth(), menu.back_tile:getHeight())
    local i, j = 0, 0
    local l = 1

    g.setColor(1, 1, 1, menu.alpha)
    while i <= w do
        j = 0
        while j <= h do
            --print("angle = ", menu.rot_grid[l])
            g.draw(menu.back_tile, quad, i, j, menu.rot_grid[l], tile_size / menu.back_tile:getWidth(), tile_size / menu.back_tile:getHeight(),
                menu.back_tile:getWidth() / 2, menu.back_tile:getHeight() / 2)
            --g.draw(menu.back_tile, quad, i, j, math.pi, 0.3, 0.3)
            l = l + 1
            j = j + tile_size
        end
        i = i + tile_size
    end

    -- позиционирование посредине экрана
    local y = (h - #menu.items * menu.font:getHeight()) / 2
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
