local g = love.graphics
local inspect = require "libs.inspect"
local pallete = require "pallete"

local Block = {}
Block.__index = Block

function Block.new(img, size, x, y, duration)
    local self = {
        img = img,
        size = size,
        x = x,
        y = y,
        active = false,
        duration = duration, -- длительность анимации движения(в секундах?)
    }
    setmetatable(self, Block)
    print(string.format("Block created at %d, %d", x, y))
    return self
end

function Block:draw()
    local quad = g.newQuad(0, 0, self.img:getWidth(), self.img:getHeight(), 
        self.img:getWidth(), self.img:getHeight())
    g.setColor{1, 1, 1, 1}
    --g.draw(self.img, quad, self.x, self.y, 0, self.size / self.img:getWidth(),
        --self.size / self.img:getHeight(), self.img:getWidth() / 2, 
        --self.img:getHeight() / 2)
    g.draw(self.img, quad, self.x, self.y, 0, self.size / self.img:getWidth(),
        self.size / self.img:getHeight())
    if self.active then
        g.setColor{1, 1, 1}
        local oldLineWidth = g.getLineWidth()
        g.setLineWidth(3)
        g.rectangle("line", self.x, self.y, self.size, self.size)
        g.setLineWidth(oldLineWidth)
    end
    --g.draw(self.img, quad, i, j, math.pi, 0.3, 0.3)
end

-- начало анимации движения
-- dirx, diry - еденичное направление, в котором будет двигаться блок.
function Block:move(dirx, diry)
    self.startTime = love.timer.getTime()
    self.dirx = dirx
    self.diry = diry
    self.active = true
    -- счетчик анимации в пикселях. Уменьшается до 0
    self.animCounter = self.size
    print("Block:move()")
    print(string.format("startTime = %d, dirx = %d, diry = %d", self.startTime,
        self.dirx, self.diry))
end

-- возвращает true если обработка движения еще не закончена. false если 
-- обработка закончена и блок готов к новым командам.
function Block:process(dt)
    local ret = false
    local time = love.timer.getTime()
    local difference = time - self.startTime

    print(string.format("dt = %f, self.x * dt = %f, self.y * dt = %f", 
        dt, self.x * dt, self.y * dt))

    --print(inspect(self))
   
    print("dirx ", self.dirx)
    print("diry ", self.diry)
    local speed = 20
    local ds = (dt * speed)

    --if difference <= self.duration then
    if self.animCounter - ds > 0 then
        self.animCounter = self.animCounter - ds

        -- двигаемся
        assert(difference ~= 0)
        -- пройденная часть времени, стремится к еденице
        --local part = self.size * (duration / difference)

        self.x = self.x + self.dirx * ds
        self.y = self.y + self.diry * ds

        ret = true
    else
        self.active = false
        -- приехали
    end

    return ret
end

local Background = {}
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
    }
    setmetatable(self, Background)

    self:resize(g.getDimensions())
    self:fillGrid()
    return self
end

-- возвращает пару индексов массива blocks, соседних с xidx, yidx из которых
-- можно начинать движение
function Background:findDirection(xidx, yidx)
    local x, y = xidx, yidx
    -- почему-то иногда возвращает не измененный результат, тотже, что и ввод.
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
            if self.blocks[xidx][yidx - 1] then
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
            if self.blocks[xidx][yidx + 1] then
                y = y + 1
                inserted = true
            end
        end

        j = j + 1
        if j > 8 then
            error("Something wrong in block placing alrogithm.")
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

    print("w / self.blockSize", w / self.blockSize)

    local i, j = 0, 0
    while i <= w + self.blockSize do
        local column = {}
        j = 0
        while j <= h + self.blockSize do
            column[#column + 1] = Block.new(self.tile, self.blockSize, i, j,
                1000)
            j = j + self.blockSize
        end
        self.blocks[#self.blocks + 1] = column
        i = i + self.blockSize
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
    for _, v in pairs(self.execList) do
        local block = self.blocks[v.xidx][v.yidx]
        -- блок двигается
        local ret = block:process(dt)
        -- начинаю новое движение
        if not ret then
            --local xidx, yidx = v.xidx, v.yidx
            local xidx, yidx = block.x / block.size, block.y / block.size

            print(string.format("v.xidx = %d, v.yidx = %d", v.xidx, v.yidx))

            -- поиск индексов нового блока
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

function Background:resize(neww, newh)
    print("Background:resize()")
    self.w, self.h = neww, newh
end

return {
    new = Background.new,
}

