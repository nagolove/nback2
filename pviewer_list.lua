----------------------
-- List object
----------------------
local pallete = require "pallete"

local List = {}

function inside(mx, my, x, y, w, h)
    return mx >= x and mx <= (x+w) and my >= y and my <= (y+h)
end

function List:new(x, y, w, h, font)
    o = {}
    setmetatable(o, self)
    self.__index = self

    o.items = {}
	o.onclick = nil
    o.font = font

    o.x, o.y = x, y
    o.width, o.height = w, h

    o.item_height = 23 -- где учет высоты шрифта?
    o.sum_item_height = 0

	o.colors = {}
	o.colors.normal = {bg = {0, 0, 0, 1}, fg = {0.77, 0.91, 1}}
	o.colors.hover  = {bg = {0.28, 0.51, 0.66, 1}, fg = {1, 1, 1, 1}}
	o.windowcolor = {0.19, 0.61, 0.88, 1}
	o.bordercolor = {0.28, 0.51, 0.66, 1}
    o.touches = {}
    o.drawList = {}
    o.activeIndex = 0 -- никакой пунки не активный
    o.lastOnclickIndex = 0

    return o
end

function List:add(title)
	local item = {}
	item.title = title
    table.insert(self.items, item)
    return item
end

function List:done()
    self.items.n = #self.items
    self.visibleNum = math.floor(self.height / self.item_height)
    if onAndroid then
        self.visibleNum = self.visibleNum - 1
    end
    self.maxVisibleNum = self.visibleNum
    print("self.visibleNum", self.visibleNum)
    self.start_i = 1
    if #self.items > 0 then
        self.activeIndex = 1
    end
    if #self.items > self.visibleNum then
        self.canDown = true
    end
    self:prepareDrawing()
end

function List:update(dt)
    local touchesSeq = {}
    for k, v in pairs(self.touches) do
        table.insert(touchesSeq, v)
    end

    local first = touchesSeq[1]
    if #touchesSeq == 1 then
        table.insert(self.drawList, function()
            love.graphics.setColor{0.5, 0.5, 0.5, 0.5}
            love.graphics.circle("fill", first.x, first.y, 15)
        end)
    end
end

function List:mousepressed(x, y, b, it)
    if self.upRect and inside(x, y, self.upRect.x, self.upRect.y, self.upRect.w, self.upRect.h) then
        self:scrollUp()
    elseif self.downRect and inside(x, y, self.downRect.x, self.downRect.y, self.downRect.w, self.downRect.h) then
        self:scrollDown()
    elseif type(self.onclick) == "function" then
        for i = self.start_i, self.end_i do
            local item = self.items[i]
            local r = item.rect
            if inside(x, y, r.x, r.y, r.w, r.h) then
                self.onclick(item, i, b)
                self.activeIndex = i
                break
            end
        end
    end
end

function List:mousereleased(x, y, b, it)
end

function List:mousemoved(x, y, dx, dy)
end

function List:touchpressed(id, x, y)
    print(":touchpressed(id, x, y)")
    self.touches[id] = {x = x, y = y}
end

function List:touchreleased(id, x, y)
    print(":touchreleased(id, x, y)")
    self.touches[id] = nil
end

function List:touchmoved(id, x, y, dx, dy)
    self.touches[id] = {x = x, y = y, dx = dx, dy = dy}
    print("touchmoved", id, x, y, dx, dy)
end

function List:wheelmoved(x, y)
end

function List:getItemRect(i)
    return self.x, self.y + self.item_height * (i - 1), self.width, self.item_height
end

function List:draw()
	love.graphics.setLineWidth(1)
	--love.graphics.setLineStyle("rough")
	love.graphics.setColor(self.windowcolor)

	--love.graphics.setScissor(self.x, self.y, self.width, self.height)

	local rx, ry, rw, rh
	local colorset
    local relativeI = 0

    if self.canUp then
        rx, ry, rw, rh = self.x, self.y + self.item_height * relativeI, self.width, self.item_height
        self.upRect = {x = rx, y = ry, w = rw, h = rh}
        love.graphics.setColor{1, 1, 1, 1}
        love.graphics.draw(self.upCanvas, rx, ry)
        relativeI = relativeI + 1
    end

    if self.canDown and self.canUp then
        self.end_i = self.start_i + self.visibleNum - 2
    elseif self.canDown or self.canUp then
        self.end_i = self.start_i + self.visibleNum - 1
    else
        self.end_i = self.start_i + #self.items - 1
    end

	for i = self.start_i, self.end_i do
		rx, ry, rw, rh = self.x, self.y + self.item_height * relativeI, self.width, self.item_height
        local item = self.items[i]

        item.rect = {x = rx, y = ry, w = rw, h = rh}

        love.graphics.setColor{1, 1, 1, 1}
        love.graphics.draw(item.canvas, rx, ry)

        if self.activeIndex == i then
            love.graphics.setColor{1, 1, 1}
            love.graphics.rectangle("line", rx + 1, ry + 1, rw - 1, rh - 1)
        end

        relativeI = relativeI + 1
	end

    if self.canDown then
        rx, ry, rw, rh = self.x, self.y + self.item_height * self.maxVisibleNum, self.width, self.item_height
        self.downRect = {x = rx, y = ry, w = rw, h = rh}
        love.graphics.setColor{1, 1, 1, 1}
        love.graphics.draw(self.downCanvas, rx, ry)
    end

    for k, v in pairs(self.drawList) do
        v()
    end

    love.graphics.setColor(pallete.pviewer.scrollLine)
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle("smooth")
    love.graphics.line(self.x + 2, self.y, self.x + 2, self.y + self.height)
    love.graphics.setColor(pallete.pviewer.circle)
end

function List:putActiveInVisiblePlace()
    if self.activeIndex < self.start_i then
        self.activeIndex = self.start_i
    elseif self.activeIndex > self.end_i then
        self.activeIndex = self.end_i - 1
    end
    if self.activeIndex ~= self.lastOnclickIndex then
        if type(self.onclick) == "function" then
            local item = self.items[self.activeIndex]
            self.onclick(item, i, nil)
            self.lastOnclickIndex = self.activeIndex
        end
    end
end

function List:scrollUp()
    print("List:scrollUp()")
    if self.canUp and self.start_i - 2 == 0 then
        self.canUp = false
        self.start_i = self.start_i - 1
    else
        if self.start_i - 1 > 0 then
            self.canDown = true
            self.start_i = self.start_i - 1
        else
            self.canUp = false
            self.upRect = nil
        end
    end
    self:putActiveInVisiblePlace()
end

function List:scrollDown()
    print("List:scrollDown()")
    if self.canDown then
        if self.start_i + self.visibleNum <= #self.items then
            if not self.canUp then
                self.start_i = self.start_i + 2
            else
                self.start_i = self.start_i + 1
            end
            self.canUp = true
        else
            self.canDown = false
            self.downRect = nil
        end
    end
    self:putActiveInVisiblePlace()
end

function List:prepareDrawing()
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
	love.graphics.setColor(self.windowcolor)

    love.graphics.setFont(self.font)

    local rx, ry, rw, rh
    local colorset
    for i = 1, self.items.n do
        colorset = self.colors.normal
        rx, ry, rw, rh = self:getItemRect(i)
        local item = self.items[i]

        item.canvas = love.graphics.newCanvas(rw, rh)
        love.graphics.setCanvas(item.canvas)

        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setColor(colorset.bg)
        love.graphics.rectangle("fill", 0, 0, rw, rh)

        love.graphics.setColor(colorset.fg)
        love.graphics.print(item.title, 10, 5) 

        love.graphics.setCanvas()
    end

    self:prepareArrows()

    self:saveCanvases()
end

function List:prepareArrows()
    local _, _, rw, rh = self:getItemRect(1)
    local x, y, w, h = 1, 1, rw - 1, rh - 1
    self.downCanvas = love.graphics.newCanvas(rw, rh)
    love.graphics.setCanvas(self.downCanvas)

    love.graphics.setColor(pallete.pviewer.scrollTriangle)
    love.graphics.polygon("fill", w / 2 - w / 3, y, w / 2, h, w / 2 + w / 3, y)

    self.upCanvas = love.graphics.newCanvas(rw, rh)
    love.graphics.setCanvas(self.upCanvas)

    love.graphics.setColor(pallete.pviewer.scrollTriangle)
    love.graphics.polygon("fill", w / 2 - w / 3, h, w / 2, y, w / 2 + w / 3, h)
    love.graphics.setCanvas()
end

function List:saveCanvases()
    self.upCanvas:newImageData():encode("png", "up.png")
    self.downCanvas:newImageData():encode("png", "down.png")
    for i in ipairs(self.items) do
        local imageData = self.items[i].canvas:newImageData()
        local file = imageData:encode("png", string.format("item_%d.png", i))
        print(file)
    end
end

return List
