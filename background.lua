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
        emptyNum = 2, -- количество пустых клеток на поле

        -- список блоков для обработки. Хранить индексы или ссылки на объекты?
        -- Если хранить ссылки на объекты, то блок должен внутри хранить
        -- свой индекс из blocks?
        execList = {}, 
        paused = false,
    }
    setmetatable(self, Background)

    self:resize(g.getDimensions())
    self:fillGrid()

    -- TESTING --

    --self:findDirection(

    -- TESTING --

    return self
end

local Block = {}
Block.__index = Block

function Block.new(img, xidx, yidx, duration)
    local self = {
        img = img,
        x = (xidx - 1) * Background.bsize,
        y = (yidx - 1) * Background.bsize,
        xidx = xidx,
        yidx = yidx,
        active = false,
        duration = duration, -- длительность анимации движения(в секундах?)
    }
    setmetatable(self, Block)
    print(string.format("Block created at %d, %d", self.x, self.y))
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
        g.rectangle("line", self.x, self.y, Background.bsize, Background.bsize)
        g.setLineWidth(oldLineWidth)
    end

    --print(self.duration)
    local xidx, yidx = math.floor(self.x / Background.bsize),
        math.floor(self.y / Background.bsize)
    local str = string.format("(%d, %d) act = %d dur = %d", xidx, yidx,
        self.active and 1 or 0, self.duration)

    local oldFont = g.getFont()
    g.setFont(serviceFont)
    g.print(str, self.x, self.y)
    g.setFont(oldFont)
    --g.draw(self.img, quad, i, j, math.pi, 0.3, 0.3)
end

-- начало анимации движения
-- dirx, diry - еденичное направление, в котором будет двигаться блок.
function Block:move(dirx, diry)
    -- для начала движения нужно знать текущий индекс блока
    self.startTime = love.timer.getTime()
    self.dirx = dirx
    self.diry = diry
    self.active = true
    -- счетчик анимации в пикселях. Уменьшается до 0
    self.animCounter = Background.bsize
    print("Block:move()")
    print(string.format("startTime = %d, dirx = %d, diry = %d", self.startTime,
        self.dirx, self.diry))
end

-- возвращает true если обработка движения еще не закончена. false если 
-- обработка закончена и блок готов к новым командам.
function Block:process(dt)
    local ret = false

    --print(string.format("dt = %f, self.x * dt = %f, self.y * dt = %f", 
        --dt, self.x * dt, self.y * dt))

    --print(inspect(self))
   
    --print("dirx ", self.dirx)
    --print("diry ", self.diry)
    
    local speed = 20
    local ds = (dt * speed)

    -- тут мне не нравится, что происходят сравнения чисел с плавающей точкой.
    -- Лучше записать новые индексы блока перед начал движения, рассчитав их
    -- целочисленно.
    if self.animCounter - ds > 0 then
        self.animCounter = self.animCounter - ds

        self.x = self.x + self.dirx * ds
        self.y = self.y + self.diry * ds

        ret = true
    else
        -- флаг ничего не делает, влияет только на рисовку обводки блока.
        self.active = false 
        -- приехали
    end

    return ret
end

function Background:keypressed(_, scancode)
    if scancode == "p" then
        self.paused = not self.paused
        print("self.paused", self.paused)
    end
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

    print(string.format("findDirection() xidx = %d, yidx = %d", xidx, yidx))

    -- флаг того, что найдена нужная позиция для активного элемента
    local inserted = false
    -- счетчик безопасности от бесконечного цикла
    local j = 1
    while not inserted do
        local dir = math.random(1, 4)
        print("random dir = ", dir)

        if dir == 1 then
            --left
            if self.blocks[xidx - 1] and self.blocks[xidx - 1][yidx] then
                x = x - 1
                inserted = true
            end
        elseif dir == 2 then
            --up
            if self.blocks[xidx] and self.blocks[xidx][yidx - 1] then
                y = y - 1
                inserted = true
            end
        elseif dir == 3 then
            --right
            if self.blocks[xidx + 1] and self.blocks[xidx + 1][yidx] then
                x = x + 1
                inserted = true
            end
        elseif dir == 4 then
            --down
            if self.blocks[xidx] and self.blocks[xidx][yidx + 1] then
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

    -- как происходит создание блоков? В блок нужно передавать индексы
    -- содержащего его массива. Левый верхний имеет индексы 0, 0. А мог бы
    -- иметь значения 1, 1. Не принципиально.
    -- Но важно - как рассчитывать координаты для рисовки блока?
    -- Через домножение индекса на ширину блока?
    --[[
       [local i, j = 0, 0
       [while i <= w + Background.bsize do
       [    local column = {}
       [    j = 0
       [    while j <= h + Background.bsize do
       [        column[#column + 1] = Block.new(self.tile, i, j, 1000)
       [        j = j + Background.bsize
       [    end
       [    self.blocks[#self.blocks + 1] = column
       [    i = i + Background.bsize
       [end
       ]]
    local xcount, ycount = (w / Background.bsize) + 1, 
        (h / Background.bsize) + 1
    for i = 1, xcount do
        local column = {}
        for j = 1, ycount do
            column[#column + 1] = Block.new(self.tile, i, j, 1000)
        end
        self.blocks[#self.blocks + 1] = column
    end

    --print("self.blocks", inspect(self.blocks))
    --print("#self.blocks", #self.blocks, "#self.blocks[1]", #self.blocks[1])

    math.randomseed(os.time())

    local fieldWidth, fieldHeight = #self.blocks, #self.blocks[1]
    for i = 1, self.emptyNum do
        -- случайный пустой блок, куда будет двигаться сосед
        local xidx = math.random(1, fieldWidth)
        local yidx = math.random(1, fieldHeight)
        self.blocks[xidx][yidx] = {}

        -- поиск соседа пустого блока. Сосед будет двигаться на пустое место.
        local x, y = self:findDirection(xidx, yidx)

        print(string.format("findDirection() = %d, %d", x, y))
        print(string.format("x - xidx = %d, y - yidx = %d", xidx, yidx))

        -- начало движения. Проверь действенность переданных в move() 
        -- параметров.
        print(inspect(self.blocks[x][y]))

        --self.blocks[x][y]:move(x - xidx, y - yidx)
        self.blocks[x][y]:move(xidx - x, yidx - y)
        -- добавляю индексы блока в список для выполнения
        self.execList[#self.execList + 1] = {xidx = x, yidx = y}
    end
    --print("self.blocks[100]", self.blocks[100])
    --print("self.blocks[100][100]", self.blocks[100][100])
end

function Background:update(dt)
    if self.paused then return end

    for _, v in pairs(self.execList) do
        local block = self.blocks[v.xidx][v.yidx]
        -- блок двигается
        local ret = block:process(dt)
        -- начинаю новое движение
        if not ret then
            --local xidx, yidx = v.xidx, v.yidx
            local xidx, yidx = math.floor(block.x / Background.bsize),
                math.floor(block.y / Background.bsize)

            print(string.format("v.xidx = %d, v.yidx = %d", v.xidx, v.yidx))

            -- поиск индексов нового блока по новым рассчитанным индексам
            local x, y = self:findDirection(xidx, yidx)
            print(string.format("x - xidx = %d, y - yidx = %d", xidx, yidx))

            -- запуск нового движения
            --self.blocks[x][y]:move(x - xidx, y - yidx)
            self.blocks[x][y]:move(xidx - x, yidx - y)

            -- обновляю индексы блока
            v.xidx = x
            v.yidx = y
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
    self.w, self.h = neww, newh
end

return {
    new = Background.new,
}

