----------------------
-- List object
----------------------
local pallete = require "pallete"

local List = {}

function inside(mx, my, x, y, w, h)
    return mx >= x and mx <= (x+w) and my >= y and my <= (y+h)
end

function List:new(x, y, w, h)
    o = {}
    setmetatable(o, self)
    self.__index = self

    o.items = {}
	o.hoveritem = 0
	o.onclick = nil

    o.x = x
    o.y = y

    o.bar = { size = 20, pos = 0, maxpos = 0, width = 15, lock = nil}

    o.width = w - o.bar.width
    o.height = h

    o.item_height = 23
    o.sum_item_height = 0

	o.colors = {}
	--o.colors.normal = {bg = {0.19, 0.61, 0.88}, fg = {0.77, 0.91, 1}}
	o.colors.normal = {bg = {0, 0, 0, 1}, fg = {0.77, 0.91, 1}}
	o.colors.hover  = {bg = {0.28, 0.51, 0.66, 1}, fg = {1, 1, 1, 1}}
	o.windowcolor = {0.19, 0.61, 0.88, 1}
	o.bordercolor = {0.28, 0.51, 0.66, 1}
    o.touches = {}
    o.drawList = {}

    return o
end

function List:add(title, id)
	local item = {}
	item.title = title
	item.id = id
	--if type(tooltip) == "string" then
		--item.tooltip = tooltip
	--else
		--item.tooltip = ""
	--end
    table.insert(self.items, item)
    return item
end

function List:done()
    self.items.n = #self.items
    -- Recalc bar size.
    self.bar.pos = 0
    local num_items = (self.height / self.item_height)
    local ratio = num_items / self.items.n
    self.bar.size = self.height * ratio
    self.bar.maxpos = self.height - self.bar.size - 3
    -- Calculate height of everything.
    self.sum_item_height = (self.item_height+1) * self.items.n + 2
    self.bar.y = 0
    self:prepareDrawing()
end

function List:hasBar()
    return self.sum_item_height > self.height
end

function List:getBarRatio()
    return self.bar.pos / self.bar.maxpos
end

function List:getOffset()
    local ratio = self.bar.pos / self.bar.maxpos
    return math.floor((self.sum_item_height - self.height) * ratio + 0.5)
end

function List:update(dt)
    if self.bar.lock then
        local dy = math.floor(love.mouse.getY()-self.bar.lock.y+0.5)
        self.bar.pos = self.bar.pos + dy

        if self.bar.pos < 0 then
            self.bar.pos = 0
        elseif self.bar.pos > self.bar.maxpos then
            self.bar.pos = self.bar.maxpos
        end

        self.bar.lock.y = love.mouse.getY()
    end

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
        if inside(first.x, first.y, self.x + 2, self.y + 1, self.width - 3, self.height - 3) then
            local tx, ty = x - self.x, y + self:getOffset() - self.y
            local index = math.floor((ty / self.sum_item_height) * self.items.n)
            local item = self.items[index + 1]
            if item then
                print("onclick", index + 1)
                self.onclick(item, index + 1, b)
            end
            self.active = index + 1
        end
    end
end

function List:mousepressed(x, y, b, it)
	if b == 1 and self:hasBar() then
		local rx, ry, rw, rh = self:getBarRect()
		if inside(x, y, rx, ry, rw, rh) then
			self.bar.lock = { x = x, y = y }
			return
		end
	end

	if type(self.onclick) == "function" and 
    inside(x, y, self.x + 2, self.y + 1, self.width - 3, self.height - 3) then
		local tx, ty = x - self.x, y + self:getOffset() - self.y
		local index = math.floor((ty / self.sum_item_height) * self.items.n)
		local item = self.items[index + 1]
		if item then
			self.onclick(item, index + 1, b)
		end
    end
end

function List:mousereleased(x, y, b, it)
	if b == 1 and self:hasBar() then
		self.bar.lock = nil
	end
end

function List:mousemoved(x, y, dx, dy)
	self.hoveritem = 0

	if self:hasBar() then
		local rx, ry, rw, rh = self:getBarRect()
		if inside(x, y, rx, ry, rw, rh) then
			self.hoveritem = -1
			return
		end
	end

	if inside(x, y, self.x + 2, self.y + 1, self.width - 3, self.height - 3) then
		local tx, ty = x - self.x, y + self:getOffset() - self.y
		local index = math.floor((ty / self.sum_item_height) * self.items.n)
		self.hoveritem = index + 1
	end
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
	--if self:hasBar() then
		--local per_pixel = (self.sum_item_height - self.height) / self.bar.maxpos
		--local bar_pixel_dt = math.floor((self.item_height * 3) / per_pixel + 0.5)

		--self.bar.pos = self.bar.pos - y * bar_pixel_dt
		--if self.bar.pos > self.bar.maxpos then self.bar.pos = self.bar.maxpos end
		--if self.bar.pos < 0 then self.bar.pos = 0 end
	--end
end

function List:getBarRect()
    return self.x, self.y + self.bar.pos + 1,
        self.bar.width - 3, self.bar.size
	--return self.x + self.width + 2, self.y + self.bar.pos + 1,
		--self.bar.width - 3, self.bar.size
end

function List:getItemRect(i)
    --return self.x + self.bar.width, self.y + ((self.item_height + 1) * (i - 1) + 1) - self:getOffset(),
        --self.width - self.bar.width, self.item_height
    return self.x + 2, self.y + ((self.item_height + 1) * (i - 1) + 1) - self:getOffset(),
        self.width - 3, self.item_height
end

function List:draw()
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
	love.graphics.setColor(self.windowcolor)

	-- Get interval to display
	local start_i = math.floor(self:getOffset() / (self.item_height + 1)) + 1
	local end_i = start_i + math.floor(self.height / (self.item_height + 1)) + 1
	if end_i > self.items.n then end_i = self.items.n end

	--love.graphics.setScissor(self.x, self.y, self.width, self.height)

	-- Items
	local rx, ry, rw, rh
	local colorset
	for i = start_i, end_i do
		--if i == self.hoveritem then
			--colorset = self.colors.hover
		--else
			--colorset = self.colors.normal
		--end

		rx, ry, rw, rh = self:getItemRect(i)
        local item = self.items[i]
        love.graphics.setColor{1, 1, 1, 1}
        love.graphics.draw(item.canvas, rx, ry)

        if self.active == i then
            love.setColor{0, 0, 0}
            love.graphics("line", rx, ry, rw, rh)
        end
        --love.graphics.setColor(colorset.bg)
        --love.graphics.rectangle("fill", rx, ry, rw, rh)

        --love.graphics.setColor(colorset.fg)
        --love.graphics.print(self.items[i].title, rx + 10, ry + 5) 
	end

    for k, v in pairs(self.drawList) do
        v()
    end

	--love.graphics.setScissor()
    love.graphics.setColor(pallete.pviewer.scrollLine)
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle("smooth")
    love.graphics.line(self.x + 2, self.y, self.x + 2, self.y + self.height)
    love.graphics.setColor(pallete.pviewer.circle)
    love.graphics.circle("fill", self.x + 2, self.bar.y, 3)
end

function List:prepareDrawing()
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
	love.graphics.setColor(self.windowcolor)

	-- Get interval to display
	local start_i = math.floor(self:getOffset() / (self.item_height + 1)) + 1
	local end_i = start_i + math.floor(self.height / (self.item_height + 1)) + 1
	if end_i > self.items.n then end_i = self.items.n end

	love.graphics.setScissor(self.x, self.y, self.width, self.height)

    -- Items
    local rx, ry, rw, rh
    local colorset
    for i = 1, self.items.n do
        --if i == self.hoveritem then
            --colorset = self.colors.hover
        --else
            --colorset = self.colors.normal
        --end
        colorset = self.colors.normal
        rx, ry, rw, rh = self:getItemRect(i)
        local item = self.items[i]

        item.canvas = love.graphics.newCanvas(rw, rh)
        love.graphics.setCanvas(item.canvas)

        love.graphics.clear(1, 1, 1, 1)
        love.graphics.setColor(colorset.bg)
        love.graphics.rectangle("fill", 0, 0, rw, rh)

        --love.graphics.setColor{0, 0, 0}
        --love.graphics.rectangle("line", 2, 2, rw - 2, rh - 2)
        --love.graphics.rectangle("fill", 2, 2, rw - 2, rh - 2)

        --g.print(compareDates(os.date("*t"), item.data.date), rx, ry)

        love.graphics.setColor(colorset.fg)
        local str = compareDates(os.date("*t"), item.data.date)
        --local str = compareDates(os.date("*t"), item.data.date) .. " " .. tostring(item.data.date.year * 365 * 24 + item.data.date.yday * 24 + item.data.date.hour)
        --local str = " " .. tostring(item.data.date.year * 365 * 24 + item.data.date.yday * 24 + item.data.date.hour)
        love.graphics.print(str, 10, 5) 

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
