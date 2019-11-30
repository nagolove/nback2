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
    return self
end

function Block:draw()
    local quad = g.newQuad(0, 0, self.img:getWidth(), self.img:getHeight(), 
        self.img:getWidth(), self.img:getHeight())
    g.setColor{1, 1, 1, 1}
    g.draw(self.img, quad, self.x, self.y, 0, self.size / self.tile:getWidth(),
        self.size / self.tile:getHeight(), self.img:getWidth() / 2, 
        self.img:getHeight() / 2)
    --g.draw(menu.tile, quad, i, j, math.pi, 0.3, 0.3)
end

end

local Background = {}
Background.__index = Background

function Background.new()
    local self = {
        tile_size = 256,
        tile = love.graphics.newImage("gfx/IMG_20190111_115755.png"),
    }
    setmetatable(self, Background)
    self:resize(g.getDimensions())
    self:calc_rotation_grid()
    return self
end

-- здесь добавить генерацию разных маршрутов движения и преобразования
-- элементов - "плиток"
function Background:calc_rotation_grid()
    self.rot_grid = {}
    local i, j = 0, 0
    while i <= self.w do
        j = 0
        while j <= self.h do
            local v = math.random()
            local angle = 0
            if 0 <= v and v <= 0.25 then angle = 0
            elseif 0.25 < v and v < 0.5 then angle = math.pi
            elseif 0.5 < v and v < 0.75 then angle = math.pi * 3 / 4
            elseif 0.75 < v and v <= 1 then angle = math.pi * 2 end
            self.rot_grid[#self.rot_grid + 1] = angle
            j = j + self.tile_size
        end
        i = i + self.tile_size
    end
end

function Background:update(dt)
end

function Background:draw()
    local quad = g.newQuad(0, 0, self.tile:getWidth(), self.tile:getHeight(), 
        self.tile:getWidth(), self.tile:getHeight())
    local i, j = 0, 0
    local l = 1
    g.clear(pallete.background)
    g.setColor(1, 1, 1, self.alpha)
    while i <= self.w do
        j = 0
        while j <= self.h do
            --print("angle = ", self.rot_grid[l])
            g.draw(self.tile, quad, i, j, self.rot_grid[l], 
                self.tile_size / self.tile:getWidth(), 
                self.tile_size / self.tile:getHeight(),
                self.tile:getWidth() / 2, self.tile:getHeight() / 2)
            --g.draw(menu.tile, quad, i, j, math.pi, 0.3, 0.3)
            l = l + 1
            j = j + self.tile_size
        end
        i = i + self.tile_size
    end
end

function Background:resize(neww, newh)
    print("Background:resize()")
    self.w, self.h = neww, newh
end

return {
    new = Background.new,
}

