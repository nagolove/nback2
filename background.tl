require "love"
require "fonts"
require "common"

local g = love.graphics
local inspect = require "inspect"
local pallete = require "pallete"

global record Background
    bsize: integer
    fragmentCode: string
    tile: love.graphics.Texture
    tiles: {love.graphics.Texture}
    blockSize: number
    emptyNum: number
    --execList: {}
    paused: boolean
    blocks: {{Block}}
    execList: {Block}

    fillGrid: function(Background)
    resize: function(Background, number, number)
end

local Background_mt: metatable<Background> = {
    __index = Background
}

local record Block
    back: Background
    img: love.graphics.Texture
    x: number
    y: number
    xidx: number
    yidx: number
    active: boolean
    duration: number
    dirx: number
    diry: number
    newXidx: number
    newYidx: number
    animCounter: number
    oldXidx: number
    oldYidx: number
end

local Block_mt: metatable<Block> = {
    __index = Block
}

function Background.new(): Background
    print('Background.new()')

    local self: Background = {        
        bsize = 128, -- размер блока в пикселях
        -- time изменяется в пределах 0..1
        fragmentCode = [[
extern float time;
vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
    vec4 pixel = Texel(image, uvs);
    float av = (pixel.r + pixel.g + pixel.b) / time;
    return pixel * color;
}
]], 
        tile = love.graphics.newImage(SCENEPREFIX .. "gfx/IMG_20190111_115755.png") as love.graphics.Texture, 
        blockSize = 128, -- нужная константа или придется менять на что-то?
        emptyNum = 1, -- количество пустых клеток на поле

        -- список блоков для обработки. Хранить индексы или ссылки на объекты?
        -- Если хранить ссылки на объекты, то блок должен внутри хранить
        -- свой индекс из blocks?
        execList = {}, 
        paused = false,
    }
    self = setmetatable(self, Background_mt)

    local blocksPath = "gfx/blocks"
    local files = love.filesystem.getDirectoryItems(blocksPath)
    self.tiles = {}
    for _, v in ipairs(files) do
        --print(string.format("tile %s", v))
        local ok, errmsg: boolean, string = pcall(function()
            self.tiles[#self.tiles + 1] = love.graphics.newImage(blocksPath .. 
            "/" .. v) as love.graphics.Texture
        end)
        if not ok then
            print(errmsg)
        end
    end

    self:fillGrid()
    self:resize(g.getDimensions())

    return self
end

-- back - экземпляр класса Background
function Block.new(back: Background, img: love.graphics.Texture, xidx: number,
    yidx: number, duration: number): Block
    local self: Block = {
        back = back,
        img = img,
        x = (xidx - 1) * back.bsize,
        y = (yidx - 1) * back.bsize,
        xidx = xidx,
        yidx = yidx,
        active = false,
        duration = duration, -- длительность анимации движения(в секундах?)
    }
    return setmetatable(self, Block_mt)
end

function Block:draw()
    local quad = g.newQuad(0, 0, self.img:getWidth(), self.img:getHeight(), 
    self.img:getWidth(), self.img:getHeight())

    g.setColor{1, 1, 1, 1}

    --g.draw(self.img, quad, self.x, self.y, 0, 
    --Background.size / self.img:getWidth(),
    --Background.size / self.img:getHeight(), self.img:getWidth() / 2, 
    --self.img:getHeight() / 2)

    g.draw(self.img, quad, self.x, self.y, 0, self.back.bsize / 
    self.img:getWidth(), self.back.bsize / self.img:getHeight())

    if self.active then
        g.setColor{1, 1, 1}
        local oldLineWidth = g.getLineWidth()
        g.setLineWidth(3)
        --g.rectangle("line", self.x, self.y, Background.bsize, Background.bsize)
        g.setLineWidth(oldLineWidth)
    end

    --local str = string.format("idx (%d, %d)\nnew (%s, %s)\nold (%s, %s)", 
    --self.xidx, self.yidx, tostring(self.newXidx or nil), 
    --tostring(self.newYidx or nil), tostring(self.oldXidx or nil), 
    --tostring(self.oldYidx or nil))

    local oldFont = g.getFont()
    g.setColor{0, 0, 0}
    g.setFont(oldFont)
end

-- начало анимации движения
-- dirx, diry - еденичное направление, в котором будет двигаться блок.
function Block:move(dirx: number, diry: number)
    --print("Block:move()", dirx, diry)
    self.dirx = dirx
    self.diry = diry
    -- новое значение индексов, которое будет использоваться после перемещения
    self.newXidx = self.xidx + dirx
    self.newYidx = self.yidx + diry
    self.active = true
    -- счетчик анимации в пикселях. Уменьшается до 0
    self.animCounter = self.back.bsize
end

-- возвращает true если обработка движения еще не закончена. false если 
-- обработка закончена и блок готов к новым командам.
function Block:process(dt: number): boolean
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
        self.back.blocks[math.floor(self.xidx)][math.floor(self.yidx)] = {}
        --print("self.newXidx, self.newYidx", self.newXidx, self.newYidx)
        self.back.blocks[math.floor(self.newXidx)][math.floor(self.newYidx)] = self
        self.oldXidx, self.oldYidx = self.xidx, self.yidx
        self.xidx = self.newXidx
        self.yidx = self.newYidx
        --self.newXidx = -1
        --self.newYidx = -1
    end

    return ret
end

function Background:get(xidx: integer, yidx: integer): Block
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
function Background:findDirection(xidx: integer, yidx: integer): integer, integer
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
                if directions[dir] and self.blocks[xidx] and 
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

    --print("w / Background.size", w / Background.bsize)

    local xcount, ycount = math.floor(w / self.bsize) + 1, 
    math.floor(h / self.bsize) + 1
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
    for _ = 1, self.emptyNum do
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

function Background:update(dt: number)
    if self.paused then return end
    for k, v in ipairs(self.execList) do
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

            --print(string.format("v.xidx = %d, v.yidx = %d", v.xidx, v.yidx))

            -- поиск индексов нового блока по новым рассчитанным индексам
            local x, y = self:findDirection(math.floor(xidx), math.floor(yidx))
            --print(string.format("x - xidx = %d, y - yidx = %d", xidx, yidx))
            --print(string.format("xidx = %d, yidx = %d", xidx, yidx))
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
    for _, v in ipairs(self.blocks) do
        for _, p in ipairs(v) do
            if p.draw then p:draw() end
        end
    end
end

-- Не работает. Нужно сделать так, чтобы при увеличении размера экрана
-- добавлялись новые блоки, а при уменьшении - стирались невидимые(хотя
-- необязательно их стирать, пусть остаются. Хм, если не стирать, то анимация
-- сможет происходить на невидимой пользователю части экрана)
function Background:resize(_: number, _: number)
    --print("Background:resize()")
    -- увеличиваем размер плиточного поля
    self:fillGrid()
end

return {
    new = Background.new,
}

