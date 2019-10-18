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

function compute_rects()
    -- позиционирование игрек посредине высоты экрана
    y_pos = (h - #menu.items * menu.font:getHeight()) / 2

    -- заполнение прямоугольников меню
    items_rects = {}
    local y = y_pos
    local rect_width = max_width
    for i, k in ipairs(menu.items) do
        items_rects[#items_rects + 1] = { x = (w - rect_width) / 2, y = y, w = rect_width, h = menu.font:getHeight()}
        y = y + menu.font:getHeight()
    end
end

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

    -- поиск наиболее широкого текста
    max_width = 0
    for _, v in pairs(menu.items) do
        local w = menu.font:getWidth(v)
        if w > max_width then max_width = w end
    end

    compute_rects()
end

function menu.resize(neww, newh)
    w = neww
    h = newh
    menu.calc_rotation_grid()
    compute_rects()
    print(string.format("menu.resize() %d*%d -> %d*%d!", w, h, neww, newh))
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

function menu.moveDown()
    if menu.active_item + 1 <= #menu.items then
        menu.active_item = menu.active_item + 1
    else
        menu.active_item = 1
    end
end

function menu.moveUp()
    if menu.active_item - 1 >= 1 then
        menu.active_item = menu.active_item - 1
    else
        menu.active_item = #menu.actions
    end
end

function menu.keypressed(key)
    if key == "up" or key == "k" then menu.moveUp()
    elseif key == "down" or key == "j" then menu.moveDown()
    elseif key == "escape" then love.event.quit()
    elseif key == "return" or key == "space" then menu.actions[menu.active_item]()
    end
end

function menu.update(dt) 
    menu.timer:update(dt)
end

function point_in_rect(px, py, x, y, w, h)
    return px > x and py > y and px < x + w and py < y + h
end

function process_menu_selection(x, y, dx, dy, istouch)
    for k, v in pairs(items_rects) do
        if point_in_rect(x, y, v.x, v.y, v.w, v.h) then menu.active_item = k end
    end
end

function menu.mousemoved(x, y, dx, dy, istouch)
    process_menu_selection(x, y, dx, dy, istouch)
end

function menu.mousepressed(x, y, button, istouch)
    local active_rect = items_rects[menu.active_item]
    if button == 1 and active_rect and point_in_rect(x, y, active_rect.x, active_rect.y, active_rect.w, active_rect.h) then
        menu.actions[menu.active_item]()
    end
end

function menu.mousereleased(x, y, button, istouch)
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

    -- печать вертикального списка меню
    g.setFont(menu.font)
    local y = y_pos
    for i, k in ipairs(menu.items) do
        local q = menu.active_item == i and pallete.active or pallete.inactive 
        q[4] = menu.alpha
        g.setColor(q)
        g.printf(k, 0, y, w, "center")
        y = y + menu.font:getHeight()
    end

    g.setLineWidth(3)
    g.setColor{1, 0, 0}
    local v = items_rects[menu.active_item]
    g.rectangle("line", v.x, v.y, v.w, v.h)

    g.pop()
end

return menu
