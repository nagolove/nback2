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
end

-- возвращает true если обработка движения еще не закончена. false если 
-- обработка закончена и блок готов к новым командам.
function Block:process(dt)
    local ret = false
    local time = love.timer.getTime()
    local difference = time - self.startTime

    print(string.format("dt = %f, self.x * dt = %f, self.y * dt = %f", 
        dt, self.x * dt, self.y * dt))

    if difference <= duration then
        -- двигаемся
        assert(difference ~= 0)
        -- пройденная часть времени, стремится к еденице
        --local part = self.size * (duration / difference)

        self.x = self.x + self.dirx * dt
        self.y = self.y + self.diry * dt

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
    -- флаг того, что найдена нужная позиция для активного элемента
    local inserted = false
    -- счетчик безопасности от бесконечного цикла
    local j = 1
    while not inserted do
        local dir = math.random(1, 4)

        if dir == 1 then
            --left
            if self.blocks[xidx - 1] and self.blocks[xidx - 1][yidx] then
                self.blocks[xidx -1][yidx].active = true
                inserted = true
            end
        elseif dir == 2 then
            --up
            if self.blocks[xidx][yidx - 1] then
                inserted = true
                self.blocks[xidx][yidx - 1].active = true
            end
        elseif dir == 3 then
            --right
            if self.blocks[xidx + 1] and self.blocks[xidx + 1][yidx] then
                self.blocks[xidx + 1][yidx].active = true
                inserted = true
            end
        elseif dir == 4 then
            --down
            if self.blocks[xidx][yidx + 1] then
                self.blocks[xidx][yidx + 1].active = true
                inserted = true
            end
        end

        j = j + 1
        if j > 8 then
            error("Something wrong in block placing alrogithm.")
        end
    end
end

function Background:fillGrid()
    local w, h = g.getDimensions()

    self.blocks = {}

    -- пример правильной адресации - смещение по горизонтали, потом - смещение
    -- по вертикали
    -- self.blocks[x][y] = block
    -- значит в строках лежат колонки

    print("w / self.blockSize", w / self.blockSize)
    local i, j = 0, 0
    while i <= w + self.blockSize do
        local column = {}
        j = 0
        while j <= h + self.blockSize do
            column[#column + 1] = Block.new(self.tile, self.blockSize, i, j)
            j = j + self.blockSize
        end
        self.blocks[#self.blocks + 1] = column
        i = i + self.blockSize
    end

    --print("self.blocks", inspect(self.blocks))
    print("#self.blocks", #self.blocks, "#self.blocks[1]", #self.blocks[1])

    math.randomseed(os.time())

    local fieldWidth, fieldHeight = #self.blocks, #self.blocks[1]
    for i = 1, self.emptyNum do
        local xidx = math.random(1, fieldWidth)
        local yidx = math.random(1, fieldHeight)
        self.blocks[xidx][yidx] = {}

        self:findDirection(xidx, yidx)
    end
    --print("self.blocks[100]", self.blocks[100])
    --print("self.blocks[100][100]", self.blocks[100][100])
end

function Background:update(dt)
    for _, v in pairs(self.blocks) do
        for _, block in pairs(v) do
            if block.process then
                local ret = block:process(dt)
                if not ret then
                    -- начинаю новое движение
                    block:move()
                end
            end
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

