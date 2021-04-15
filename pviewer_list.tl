require "love"

local gr = love.graphics
local fontsize = 23

----------------------
-- List object
----------------------

local record List 

    type Lock = record 
        x: number
        y: number
    end

    type Bar = record 
        size: number
        pos: number
        maxpos: number
        width: number
        lock: Lock
    end

    type ColorType = record 
        bg: {number}
        fg: {number}
    end

    type Colors = record
        normal: ColorType
        hover: ColorType
    end

    type Item = record 
        data: any
        message: string
        colors: {number}
        --tooltip: string
        id: string
        list: List
        isdrawable: boolean
    end

    bar: Bar
    bordercolor: {number}
    colors: Colors
    font: love.graphics.Font
    height: number
    hoveritem: number
    item_height: number
    items: {Item}
    onclick: function(self: List, index: number, button: number)
    prevfont: gr.Font
    sum_item_height: number
    visible: boolean
    width: number
    windowcolor: {number}
    x: number
    y: number

    getBarRect: function(List, number, number, number, number)
    onclick: function(self: List, index: number, button: number)

    new: function(x: number, y: number, w: number, h: number, fnt: gr.Font): List

    --[[
    Добавить в список клавишу.
    ]]
    add: function(List, message: string, ...: {number}): List.Item
    -- закрыть список для добавления и произвести форматирование по ширине
    done: function(List)

    hasBar: function(List): boolean
    getBarRatio: function(List): number
    getOffset: function(List): number
    getBarRect: function(List): number, number, number, number
    getItemRect: function(List, i: number): number, number, number, number

    -- нужно вызывать только когда список активен в отрисовке и используется
    -- ввод.
    update: function(List, dt: number)

    mousepressed: function(List, x: number, y: number, b: number): boolean
    mousereleased: function(List, _: number, _: number, b: number)
    mousemoved: function(List, x: number, y: number, dx: number, dy: number)
    wheelmoved: function(List, _: number, y: number)

    draw: function(List)
    draw2: function(List)
end

function inside(mx: number, my: number, x: number, y: number, w: number, h: number): boolean
    return mx >= x and mx <= (x+w) and my >= y and my <= (y+h)
end

function List.new(x: number, y: number, w: number, h: number, fnt: gr.Font): List
    local self: List = {
        --font = gr.newFont("fonts/DroidSansMono.ttf", fontsize)
        font = fnt, 
    }

    self = setmetatable(self, { __index = List })

    self.items = {}
    self.hoveritem = 0
    self.onclick = nil

    self.x = x
    self.y = y

    self.width = w
    self.height = h

    --self.item_height = 23
    print("self.item_height", self.font:getHeight())
    self.item_height = self.font:getHeight()
    self.sum_item_height = 0

    self.bar = { size = 20, pos = 0, maxpos = 0, width = 20, lock = nil}
    --self.bar = { size = 40, pos = 0, maxpos = 0, width = 20, lock = nil}
    
    self.colors = {}
    self.colors.normal = {bg = {0.19, 0.61, 0.88}, fg = {0.77, 0.91, 1}}
    self.colors.hover  = {bg = {0.28, 0.51, 0.66}, fg = {1, 1, 1}}
    self.windowcolor = {0.19, 0.61, 0.88}
    self.bordercolor = {0.28, 0.51, 0.66}
    self.visible = true
    return self
end

-- list:add("сбросить управление %C%C)
--function List:add(message: string, ...: {number}): List.Item
function List:add(message: string): List.Item
    --print("itooltip", tooltip)
    --os.exit()
    local item: List.Item = {}
    -- сообщение с форматированием
    item.message = message
    table.insert(self.items, item)
    return self.items[#self.items]
end

function List:done()
    -- Recalc bar size.
    self.bar.pos = 0

    local num_items = (self.height/self.item_height)
    local ratio = num_items/ #self.items
    self.bar.size = self.height * ratio
    self.bar.maxpos = self.height - self.bar.size - 3

    -- Calculate height of everything.
    self.sum_item_height = (self.item_height+1) * #self.items + 2
    --self.sum_item_height = (self.item_height+1) * #self.items 

    self.height = self.sum_item_height
    local maxLen, maxLenIdx = 0, 1
    --print(inspect(self.items))
    for k, v in ipairs(self.items) do
        if type(v) == "table" and v.message and #v.message > maxLen then
            maxLen = #v.message
            maxLenIdx = k
        end
    end
    --local longestStr = self.items[maxLenIdx].message .. string.rep(" ", 10)
    --self.width = love.graphics.getFont():getWidth(longestStr)
    self.width = self.font:getWidth(self.items[maxLenIdx].message)
    print("self.sum_item_height", self.sum_item_height)
    print("self.width", self.width)
    print("self.height", self.height)
end

function List:hasBar(): boolean
    return self.bar and self.sum_item_height > self.height
end

function List:getBarRatio(): number
    return self.bar.pos / self.bar.maxpos
end

function List:getOffset(): number
    if self.bar then
        local ratio = self.bar.pos / self.bar.maxpos
        return math.floor((self.sum_item_height - self.height) * ratio + 0.5)
    else 
        return 0 
    end
end

function List:update(dt: number)
    if self.bar and self.bar.lock then
        local dy = math.floor(love.mouse.getY()-self.bar.lock.y+0.5)
        self.bar.pos = self.bar.pos + dy

        if self.bar.pos < 0 then
            self.bar.pos = 0
        elseif self.bar.pos > self.bar.maxpos then
            self.bar.pos = self.bar.maxpos
        end
        self.bar.lock.y = love.mouse.getY()
    end
    for _, v in ipairs(self.items) do
        if type(v) == "table" and v.list then
            v.list:update(dt)
        end
    end
end

function List:mousepressed(x: number, y: number, b: number): boolean
    if b == 1 and self:hasBar() then
        local rx, ry, rw, rh: number, number, number, number = self:getBarRect()
        if inside(x, y, rx, ry, rw, rh) then
            self.bar.lock = { x = x, y = y }
            return
        end
    end

    if inside(x, y, self.x + 2, self.y + 1, self.width - 3, self.height - 3) then
        if type(self.onclick) == "function" then 
            local _, ty = x - self.x, y + self:getOffset() - self.y
            local index = math.floor((ty / self.sum_item_height) * #self.items)
            local item = self.items[index + 1]
            if item then
                self.onclick(self, index + 1, b)
            end
        end
    else
        return false
    end

    return true
end

function List:mousereleased(_: number, _: number, b: number)
    if b == 1 and self:hasBar() then
        self.bar.lock = nil
    end
end

function List:mousemoved(x: number, y: number, dx: number, dy: number)
    self.hoveritem = 0

    if self:hasBar() then
        local rx, ry, rw, rh: number, number, number, number = self:getBarRect()
        if inside(x, y, rx, ry, rw, rh) then
            self.hoveritem = -1
            return
        end
    end

    if inside(x, y, self.x + 2, self.y + 1, self.width - 3, self.height - 3) then
        local _, ty = x - self.x, y + self:getOffset() - self.y
        local index = math.floor((ty / self.sum_item_height) * #self.items)
        self.hoveritem = index + 1
        local item = self.items[index + 1]
        item.isdrawable = item.list and true or false
        if item.isdrawable then
            item.list:mousemoved(x, y, dx, dy)
        end
    end
end

function List:wheelmoved(_: number, y: number)
    if self:hasBar() then
        local per_pixel = (self.sum_item_height - self.height) / self.bar.maxpos
        local bar_pixel_dt = math.floor((self.item_height * 3) / per_pixel + 0.5)

        self.bar.pos = self.bar.pos - y * bar_pixel_dt
        if self.bar.pos > self.bar.maxpos then self.bar.pos = self.bar.maxpos end
        if self.bar.pos < 0 then self.bar.pos = 0 end
    end
end

function List:getBarRect(): number, number, number, number
    return self.x + self.width + 2, self.y + self.bar.pos + 1,
        self.bar.width - 3, self.bar.size
end

function List:getItemRect(i: number): number, number, number, number
    return 
        self.x + 2, 
        self.y + ((self.item_height + 1) * (i - 1) + 1) - self:getOffset(),
        self.width - 3, 
        self.item_height
end

function List:setupPush()
    self.prevfont = gr.getFont()
    gr.setLineWidth(1)
    gr.setLineStyle("rough")
    gr.setColor(self.windowcolor)
    gr.setFont(self.font)
    gr.setScissor(self.x, self.y, self.width, self.height)
end

function List:setupPop()
    love.graphics.setScissor()
    gr.setFont(self.prevfont)
end

function List:border()
    gr.setColor(self.bordercolor)
    if self.bar then
        gr.rectangle("line", self.x + self.width, self.y, self.bar.width, self.height)
    end
    gr.rectangle("line", self.x, self.y, self.width, self.height)
end

-- Get interval to display
function List:getInterval(): number, number
    local start_i = math.floor(self:getOffset() / (self.item_height + 1)) + 1
    local end_i = start_i + math.floor(self.height / (self.item_height + 1)) + 1
    if end_i > #self.items then 
        end_i = #self.items
    end
    return start_i, end_i
end

function List:draw()
    if not self.visible then 
        return 
    end

    self:setupPush()

    -- Items
    local rx, ry, rw, rh: number, number, number, number
    local start_i, end_i = self:getInterval()
    local colorset: List.ColorType
    for i = start_i,end_i do
        if i == self.hoveritem then
            colorset = self.colors.hover
        else
            colorset = self.colors.normal
        end

        rx, ry, rw, rh = self:getItemRect(i)
        gr.setColor(colorset.bg)
        gr.rectangle("fill", rx, ry, rw, rh)

        gr.setColor(colorset.fg)

        ----
        --gr.print(self.items[i].message, rx + 10, ry + 5) 
        gr.print(self.items[i as integer].message, rx, ry) 
        ----

        local item = self.items[i as integer]
        if item.list and item.isdrawable then
            item.list.x = rx + rw
            item.list.y = ry
            item.list:draw()
        end
    end

    love.graphics.setScissor()

    if self:hasBar() then
        if self.hoveritem == -1 or self.bar.lock ~= nil then
            colorset = self.colors.hover
        else
            colorset = self.colors.normal
        end

        rx, ry, rw, rh = self:getBarRect()
        love.graphics.setColor(colorset.bg)
        love.graphics.rectangle("fill", rx, ry, rw, rh)
    end

    --self:bar()
    self:border()
    self:setupPop()
end

-- Bar
function List:bar()
    --local rx, ry, rw, rh: number, number, number, number
    --[[
    if self:hasBar() then
        if self.hoveritem == -1 or self.bar.lock ~= nil then
            colorset = self.colors.hover
        else
            colorset = self.colors.normal
        end

        rx, ry, rw, rh = self:getBarRect()
        love.graphics.setColor(colorset.bg)
        love.graphics.rectangle("fill", rx, ry, rw, rh)
    end
    --]]
end

function List:draw2()
    if not self.visible then return end

    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
    love.graphics.setColor(self.windowcolor)

    -- Get interval to display
    local start_i = math.floor(self:getOffset() / (self.item_height + 1)) + 1
    local end_i = start_i + math.floor(self.height / (self.item_height + 1)) + 1
    if end_i > #self.items then 
        end_i = #self.items
    end

    love.graphics.setScissor(self.x, self.y, self.width, self.height)

    -- Items
    local rx, ry, rw, rh: number, number, number, number
    local colorset: List.ColorType
    for i = start_i,end_i do
        if i == self.hoveritem then
            colorset = self.colors.hover
        else
            colorset = self.colors.normal
        end

        rx, ry, rw, rh = self:getItemRect(i)
        love.graphics.setColor(colorset.bg)
        love.graphics.rectangle("fill", rx, ry, rw, rh)

        love.graphics.setColor(colorset.fg)
        --love.graphics.print(self.items[i].title, rx + 10, ry + 5) 
        --local colors: {number} = self.items[i].colors
        local t: {any} = {}
        --for i, color in ipairs(colors) do
            ----table.insert(t, )
        --end
        love.graphics.print(t as {table}, rx + 10, ry + 5) 

        local item = self.items[i]
        if item.list and item.isdrawable then
            item.list.x = rx + rw
            item.list.y = ry
            item.list:draw()
        end
    end

    love.graphics.setScissor()

    -- Bar
    if self:hasBar() then
        --if self.hoveritem == -1 or self.bar.lock ~= nil then
            --colorset = self.colors.hover
        --else
            --colorset = self.colors.normal
        --end
        
        rx, ry, rw, rh = self:getBarRect()
        love.graphics.setColor(colorset.bg)
        love.graphics.rectangle("fill", rx, ry, rw, rh)
    end

    -- Border
    love.graphics.setColor(self.bordercolor)
    if self.bar then
        --love.graphics.rectangle("line", self.x + self.width, self.y, self.bar.width, self.height)
    end
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

end

return List
