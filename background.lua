local g = love.graphics
local inspect = require "libs.inspect"
local pallete = require "pallete"
local serviceFont = love.graphics.newFont(10)

local Background = {
    bsize = 128, -- размер блока в пикселях
}
Background.__index = Background

function Background.new()
    local self = {
        tile = love.graphics.newImage("gfx/IMG_20190111_115755.png"),
        blockSize = 128, -- нужная константа или придется менять на что-то?
        emptyNum = 1, -- количество пустых клеток на поле

        -- список блоков для обработки. Хранить индексы или ссылки на объекты?
        -- Если хранить ссылки на объекты, то блок должен внутри хранить
        -- свой индекс из blocks?
        execList = {}, 
        paused = false,
    }
    setmetatable(self, Background)

    self:fillGrid()
    self:resize(g.getDimensions())

    return self
end

local Block = {}
Block.__index = Block

-- back - экземпляр класса Background
function Block.new(back, img, xidx, yidx, duration)
    local self = {
        back = back,
        img = img,
        x = (xidx - 1) * Background.bsize,
        y = (yidx - 1) * Background.bsize,
        xidx = xidx,
        yidx = yidx,
        active = false,
        duration = duration, -- длительность анимации движения(в секундах?)
    }
    setmetatable(self, Block)
    --print(string.format("Block created at %d, %d", self.x, self.y))
    return self
end

function Block:draw()
    local quad = g.newQuad(0, 0, self.img:getWidth(), self.img:getHeight(), 
        self.img:getWidth(), self.img:getHeight())

    g.setColor{1, 1, 1, 1}

    --g.draw(self.img, quad, self.x, self.y, 0, 
        --Background.size / self.img:getWidth(),
        --Background.size / self.img:getHeight(), self.img:getWidth() / 2, 
        --self.img:getHeight() / 2)
        
    g.draw(self.img, quad, self.x, self.y, 0, Background.bsize / 
        self.img:getWidth(), Background.bsize / self.img:getHeight())

    if self.active then
        g.setColor{1, 1, 1}
        local oldLineWidth = g.getLineWidth()
        g.setLineWidth(3)
        --g.rectangle("line", self.x, self.y, Background.bsize, Background.bsize)
        g.setLineWidth(oldLineWidth)
    end

    local str = string.format("idx (%d, %d)\nnew (%s, %s)\nold (%s, %s)", 
        self.xidx, self.yidx, tostring(self.newXidx or nil), 
        tostring(self.newYidx or nil), tostring(self.oldXidx or nil), 
        tostring(self.oldYidx or nil))

    local oldFont = g.getFont()
    g.setColor{0, 0, 0}
    g.setFont(serviceFont)
    --g.print(str, self.x, self.y)
    g.setFont(oldFont)
    --g.draw(self.img, quad, i, j, math.pi, 0.3, 0.3)
end

-- начало анимации движения
-- dirx, diry - еденичное направление, в котором будет двигаться блок.
function Block:move(dirx, diry)
    --print("Block:move()", dirx, diry)
    self.dirx = dirx
    self.diry = diry
    -- новое значение индексов, которое будет использоваться после перемещения
    self.newXidx = self.xidx + dirx
    self.newYidx = self.yidx + diry
    self.active = true
    -- счетчик анимации в пикселях. Уменьшается до 0
    self.animCounter = Background.bsize
end

-- возвращает true если обработка движения еще не закончена. false если 
-- обработка закончена и блок готов к новым командам.
function Block:process(dt)
    local ret = false

    --print("dirx ", self.dirx)
    --print("diry ", self.diry)
    
    local speed = 20
    local ds = (dt * speed)

    if self.animCounter - ds > 0 then
        self.animCounter = self.animCounter - ds
        self.x = self.x + self.dirx * ds
        self.y = self.y + self.diry * ds
        ret = true
    else
        -- приехали
        -- флаг ничего не делает, влияет только на рисовку обводки блока.
        self.active = false 
        self.back.blocks[self.xidx][self.yidx] = {}
        --print("self.newXidx, self.newYidx", self.newXidx, self.newYidx)
        self.back.blocks[self.newXidx][self.newYidx] = self
        self.oldXidx, self.oldYidx = self.xidx, self.yidx
        self.xidx = self.newXidx
        self.yidx = self.newYidx
        --self.newXidx = -1
        --self.newYidx = -1
    end

    return ret
end

function Background:keypressed(_, scancode)
    --if scancode == "p" then
        --self.paused = not self.paused
        --print("self.paused", self.paused)
    --end
end

function Background:get(xidx, yidx)
    local firstColumn = self.blocks[1]
    --print("xidx, yidx", xidx, yidx)
    if xidx >= 1 and xidx <= #self.blocks and 
        yidx >= 1 and yidx <= #firstColumn then
        return self.blocks[xidx][yidx]
    else
        return nil
    end
end

-- возвращает пару индексов массива blocks, соседних с xidx, yidx из которых
-- можно начинать движение. А что возвращает в качестве ошибки? Всегда ли
-- существует пара подходящих индексов?
-- Как можно разделить функцию на две части?
-- Скажем одна делает обращение к массиву с проверкой границ и отладочным
-- выводом, а другая - занимается поиском подходящей ячейки.
function Background:findDirection(xidx, yidx)
    local x, y = xidx, yidx
    -- почему-то иногда возвращает не измененный результат, тот же, что и ввод.
    -- приводит к падению программы

    local columnMax = #self.blocks[1]
    -- left, up, right, down
    local directions = {xidx - 1 >= 1, yidx - 1 >= 1, xidx + 1 <= columnMax,
        yidx + 1 <= columnMax}

    --print(string.format("findDirection() xidx = %d, yidx = %d", xidx, yidx))
    --print("self.blocks[xidx - 1]", self.blocks[xidx - 1])
    --print("directions", inspect(directions))

    -- флаг того, что найдена нужная позиция для активного элемента
    local inserted = false
    -- счетчик безопасности от бесконечного цикла
    local j = 1
    while not inserted do
        local dir = math.random(1, 4)
        --print("random dir = ", dir)

        if dir == 1 then
            --left
            if directions[dir] and self.blocks[xidx - 1] and 
                self.blocks[xidx - 1][yidx] then
                x = x - 1
                inserted = true
            end
        elseif dir == 2 then
            --up
            if directions[dir] and self.blocks[xidx] and 
                self.blocks[xidx][yidx - 1] then
                y = y - 1
                inserted = true
            end
        elseif dir == 3 then
            --right
            if directions[dir] and self.blocks[xidx + 1] and 
                self.blocks[xidx + 1][yidx] then
                x = x + 1
                inserted = true
            end
        elseif dir == 4 then
            --down
            if directions[dire] and self.blocks[xidx] and 
                self.blocks[xidx][yidx + 1] then
                y = y + 1
                inserted = true
            end
        end

        j = j + 1
        if j > 16 then
            error(string.format(
                "Something wrong in block placing alrogithm on [%d][%d].",
                xidx, yidx))
        end
    end

    return x, y
end

function Background:fillGrid()
    local w, h = g.getDimensions()

    -- пример правильной адресации - смещение по горизонтали, потом - смещение
    -- по вертикали
    -- self.blocks[x][y] = block
    -- значит в строках лежат колонки
    self.blocks = {}

    print("w / Background.size", w / Background.bsize)

    local xcount, ycount = math.floor(w / Background.bsize) + 1, 
        math.floor(h / Background.bsize) + 1
    for i = 1, xcount do
        local column = {}
        for j = 1, ycount do
            column[#column + 1] = Block.new(self, self.tile, i, j, 1000)
        end
        self.blocks[#self.blocks + 1] = column
    end

    math.randomseed(os.time())

    local fieldWidth, fieldHeight = #self.blocks, #self.blocks[1]
    self.execList = {}
    for i = 1, self.emptyNum do
        -- случайный пустой блок, куда будет двигаться сосед
        local xidx = math.random(1, fieldWidth)
        local yidx = math.random(1, fieldHeight)
        self.blocks[xidx][yidx] = {}

        -- поиск соседа пустого блока. Сосед будет двигаться на пустое место.
        local x, y = self:findDirection(xidx, yidx)

        self.blocks[x][y]:move(xidx - x, yidx - y)
        self.execList[#self.execList + 1] = self.blocks[x][y]
    end
end

function Background:update(dt)
    if self.paused then return end

    for k, v in pairs(self.execList) do
        local block = v
        --print(inspect(v))
        -- блок двигается
        local ret = block:process(dt)
        -- начинаю новое движение
        if not ret then
            --local xidx, yidx = v.xidx, v.yidx
            --local xidx, yidx = math.floor(block.x / Background.bsize),
                --math.floor(block.y / Background.bsize)

            local xidx, yidx = block.oldXidx or block.xidx, 
                block.oldYidx or block.yidx

            print(string.format("v.xidx = %d, v.yidx = %d", v.xidx, v.yidx))

            -- поиск индексов нового блока по новым рассчитанным индексам
            local x, y = self:findDirection(xidx, yidx)
            --print(string.format("x - xidx = %d, y - yidx = %d", xidx, yidx))
            print(string.format("xidx = %d, yidx = %d", xidx, yidx))
            --print(string.format("xidx - x = %d, yidx - y = %d", 
                --xidx - x, yidx - y))

            -- запуск нового движения
            -- здесь какие-то неправильные индексы используются. При
            -- первом движении работает нормально, а следущие - генерируются
            -- совсем не так, как должны.
            --self.blocks[x][y]:move(x - xidx, y - yidx)
            if self.blocks[x][y].move then
                self.blocks[x][y]:move(xidx - x, yidx - y)
            elseif self.blocks[x][y] == {} then
                error("{} block")
            else
                error("Ououou " .. inspect(self.blocks[x][y]))
            end

            self.execList[k] = self.blocks[x][y]
            -- обновляю индексы блока
            --v.xidx = x
            --v.yidx = y
        end
    end
end

function Background:draw()
    g.clear(pallete.background)
    --print("self.blocks", inspect(self.blocks))
    for _, v in pairs(self.blocks) do
        for _, p in pairs(v) do
            if p.draw then p:draw() end
        end
    end
end

-- Не работает. Нужно сделать так, чтобы при увеличении размера экрана
-- добавлялись новые блоки, а при уменьшении - стирались невидимые(хотя
-- необязательно их стирать, пусть остаются. Хм, если не стирать, то анимация
-- сможет происходить на невидимой пользователю части экрана)
function Background:resize(neww, newh)
    print("Background:resize()")
    -- увеличиваем размер плиточного поля
    self:fillGrid()
end

return {
    new = Background.new,
}

