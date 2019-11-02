-- какие параметры контролирует меню? Что передавать в функцию создания нового
-- пункта меню?
-- Где будет находиться обработка пунктов, изменение их значений?
--
-- * уровень н-назад
-- * временя паузы
-- * длина раунда
--
-- * вывод расчетного значения времени раунда(Почему "раунд"? Бокс что-ли?
-- Попробуй заменить на время концентрации

local menu {}

menu.__index = menu

-- парамертрами могут быть - шрифт и его размер, цвет текста, стиль рамки
-- выделения пункта
function menu.new(font, color)
    local self = {
        font = font,
        color = color,
    }
    return setmetatable(self, menu)
end
   
-- какие тут могут быть параметры?
-- что выдает пункт меню для рисовки? статичный текст?
local pauseTimeList = {
    "1.4s .. 1.8s",
    "1.8s .. 2.2s",
    "2.2s .. 2.6s",
}
local activePauseTimeListItem = 2

function onleft()
    -- эта строчка должна попадать во внутренний буфер вызывающего меню
    if activePauseTimeListItem - 1 >= 1 then
        activePauseTimeListItem = activePauseTimeListItem - 1
    end
    return pauseTimeList[activePauseTimeListItem]
end

function onright()
    if activePauseTimeListItem + 1 <= #pauseTimeList then
        activePauseTimeListItem = activePauseTimeListItem + 1
    end
    return pauseTimeList[activePauseTimeListItem]
end

function ondraw(item, x, y, w, h)
    love.graphics.print(item.pauseTimeList[item.activePauseTimeListItem],
end

function menu.addItem(ondraw, onleft, onright)
end

function menu.scrollUp()
    if self.activeIndex - 1 >= 1 then
        self.activeIndex = self.activeIndex - 1
    end
end

function menu.scroollDown()
    if self.activeIndex + 1 <= #self.items then
        self.activeIndex = self.activeIndex + 1
    end
end

-- тут изменение параметра в меньшую стророну
function menu.leftPressed()
end

-- тут изменение параметра в большую строну
function menu.rightPressed()
end

-- рисовать курсор на активной позиции
function menu.drawCursor()
end

-- рисовать менюшку с выравниванием относительно прямоугольника x, y, w, h
-- целевая задача: рисовка одной единственной менюшки, в центре экрана, с
-- выравниманием по-центру прямоугольника.
function menu.draw(x, y, w, h)
end


