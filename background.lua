local g = love.graphics
local inspect = require "libs.inspect"
local pallete = require "pallete"

local Block = {}
Block.__index = Block

function Block.new(img, size, x, y)
    local self = {
        img = img,
        size = size,
        x = x,
        y = y,
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
    --g.draw(self.img, quad, i, j, math.pi, 0.3, 0.3)
end

-- еденичное направление, в котором будет двигаться блок.
function Block:move(dirx, diry)
end

function Block:process()

end

local Background = {}
Background.__index = Background

function Background.new()
    local self = {
        tile = love.graphics.newImage("gfx/IMG_20190111_115755.png"),
        blockSize = 128, -- нужная константа или придется менять на что-то?
        emptyNum = 2,
    }
    setmetatable(self, Background)

    self:resize(g.getDimensions())
    self:fillGrid()
    return self
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
    end
end

function Background:update(dt)
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

