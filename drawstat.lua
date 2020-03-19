local pallete = require "pallete"

-- x, y - координаты левого верхнего угла отрисовываемой картинки.
-- arr - массив со значениями чего?
-- eq - массив-наложение на arr, для успешных попаданий?
-- rect_size - размер отображаемого в сетке прямоугольника
-- border - зазор между прямоугольниками.
-- что за пару x, y возвращает функция?
local function draw_hit_rects(x, y, pressed_arr, eq_arr, 
    rect_size, border, level)
    local g = love.graphics
    local hit_color = {200 / 255, 10 / 255, 10 / 255}
    for k, v in pairs(pressed_arr) do
        g.setColor(pallete.field)
        g.rectangle("line", x + rect_size * (k - 1), y, rect_size, rect_size)
        g.setColor(pallete.inactive)
        g.rectangle("fill", x + rect_size * (k - 1) + border, y + border, 
            rect_size - border * 2, rect_size - border * 2)

        -- отмеченная игроком позиция
        if v then
            g.setColor(hit_color)
            g.rectangle("fill", x + rect_size * (k - 1) + border, y + border, 
                rect_size - border * 2, rect_size - border * 2)
        end

        -- правильная позиция нажатия
        if eq_arr[k] then
            local radius = 4
            g.setColor{0, 0, 0}
            g.circle("fill", x + rect_size * (k - 1) + rect_size / 2, 
                y + rect_size / 2, radius)
            -- кружок на место предудущего сигнала
            g.setColor{1, 1, 1, 0.5}
            g.circle("line", x + rect_size * ((k - level) - 1) + rect_size / 2, 
                y + rect_size / 2, radius)
        end
    end

    -- этот код должен быть в вызывающей функции
    y = y + rect_size + 6
    return x, y
    -- этот код должен быть в вызывающей функции
end

return { draw_hit_rects = draw_hit_rects }
