local inspect = require "libs.inspect"
local serpent = require "serpent"
local timer = require "libs.Timer"

local pallete = require "pallete"
local g = love.graphics
local Kons = require "kons"

-- integer division
local function div(a, b)
    return (a - a %b) / b
end

local pviewer = {}
pviewer.__index = pviewer

function pviewer.new()
    local self = {
        scroll_tip_text = "For scrolling table use ↓↑ arrows",
        header_text = "", 
        border = 40, --y axis border in pixels for drawing chart
        scrollx = 0,
        font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
        scrool_tip_font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 13),
        selected_item = 2,
        start_line = 1,
        sorted_by_column_num = 1,
        columns_name = {"date", "nlevel", "rating", "pause"},
    }
    self.w, self.h = g.getDimensions()
    return setmetatable(self, pviewer)
end

local linesbuffer = Kons(x, y)

function pviewer:init(save_name)
    self.save_name = save_name
    self:resize(g.getDimensions())
    self.timer = timer()
end

function pviewer:enter()
    print("pviewer:enter()")
    local tmp, size = love.filesystem.read(self.save_name)
    if tmp ~= nil then
        ok, self.data = serpent.load(tmp)
        if not ok then 
            error("Something wrong in restoring data " .. self.save_name)
        end
    else
        self.data = {}
    end
    if #self.data >= 1 then
        self.cursor_index = 1
    else
        self.cursor_index = 0
    end
    print("*** begining of pviewer.data ***")
    local str = inspect(self.data)
    --print(str)
    love.filesystem.write("pviewer_data_extracting.lua", str, str:len())
    print("*** end of pviewer.data ***")
    --self.sort_by_column(1)
end

-- пока методы enter()/leave() не поддерживаются в переключении меню
function pviewer:leave()
    self.data = nil
end

function pviewer:get_max_lines_printed()
    return div(h - 100, self.font:getHeight())
end

function pviewer:resize(neww, newh)
    print(string.format("pviewer.resize(%d, %d)", neww, newh))
    w = neww
    h = newh
    self.vertical_buf_len = self:get_max_lines_printed()
    print("vertical_buf_len = ", self.vertical_buf_len)
    print(self.data)
    print(inspect(self.data))
    print(self.cursor_index)
    if self.cursor_index and self.cursor_index > self.vertical_buf_len then 
        self.cursor_index = self.vertical_buf_len - 1 -- why -1 ??
    end 
    self.rt = g.newCanvas(w, self.vertical_buf_len * 
        self.font:getLineHeight() * self.font:getHeight(), {format = "normal", 
        msaa = 4})
    if not self.rt then
        error("Canvas not supported!")
    end
end

-- draw column of table pviewer.data, from index k, to index j with func(v) access function
function pviewer:draw_column(k, j, deltax, func)
    local oldcolor = {g.getColor()}
    local dx = 0
    local y = 0 + self.font:getHeight() -- start y position
    if k + j > #self.data then
        j = #self.data
    end
    for i = k, j do
        local s = func(self.data[i])
        dx = math.max(dx, self.font:getWidth(s))
        g.print(s, deltax, y)
        y = y + self.font:getHeight()
    end
    g.setColor(oldcolor)
    deltax = deltax + dx
    return deltax
end

function pviewer:draw_columns(k, j, deltax)
    g.setFont(self.font)
    g.setColor(pallete.chart)
    deltax = self:draw_column(k, j, deltax, 
        function(v) 
            if v.date then 
                return string.format("%.2d.%.2d.%d %.2d:%.2d:%.2d", 
                    v.date.day, v.date.month, v.date.year, v.date.hour, 
                    v.date.min, v.date.sec)
            else return "" end 
        end)
    g.setColor(pallete.header)
    deltax = self:draw_column(k, j, deltax, function(v) return " / " end)
    g.setColor(pallete.chart)
    deltax = self:draw_column(k, j, deltax, 
        function(v) if v.nlevel then 
            return string.format("%d", v.nlevel) else return "-" end 
        end)
    g.setColor(pallete.header)
    deltax = self:draw_column(k, j, deltax, function(v) return " / " end)
    g.setColor(pallete.chart)
    deltax = self:draw_column(k, j, deltax, function(v) if v.percent then 
        return string.format("%.2f", v.percent) else return "-" end 
    end)
    g.setColor(pallete.header)
    deltax = self:draw_column(k, j, deltax, function(v) return " / " end)
    g.setColor(pallete.chart)
    deltax = self:draw_column(k, j, deltax, function(v) if v and v.pause then 
        return string.format("%.2f", v.pause) else return "_" end end)
    return deltax
end

-- draw pviewer.data from k to j index in vertical list on the center of screen
function pviewer:draw_chart(k, j)
    if k < 1 then k = 1 end
    local deltax = 0
    -- because k may be float value
    deltax = self:draw_columns(math.floor(k), j, deltax)
    return deltax
end

function pviewer:draw_chart_header(r)
    g.setColor({1, 1, 1})
    g.setFont(self.font)
    local tbl = {}
    for k, v in pairs(self.columns_name) do
        if k == self.sorted_by_column_num then
            tbl[#tbl + 1] = pallete.active
        else
            tbl[#tbl + 1] = pallete.header
        end
        if k ~= #self.columns_name then
            tbl[#tbl + 1] = v .. " / "
        else
            tbl[#tbl + 1] = v
        end
    end
    g.printf(tbl, r.x1, r.y1 - self.border / 2, r.x2 - r.x1, "center")
end

--drawing scroll_tip_text
function pviewer:draw_scroll_tip(rect)
    g.setColor(pallete.scroll_tip_text)
    g.setFont(self.scrool_tip_font)
    g.printf(self.scroll_tip_text, rect.x1, rect.y2 + self.border / 2, 
        rect.x2 - rect.x1, "center")
end

function pviewer:print_dbg_info()
    linesbuffer:pushi("fps " .. love.timer.getFPS())
    linesbuffer:pushi("sorted by %s = %d", 
        self.columns_name[self.sorted_by_column_num], 
        self.sorted_by_column_num)
    linesbuffer:draw()
end

function pviewer:draw()
    love.graphics.clear(pallete.background)

    local r = {x1 = self.border, y1 = self.border, 
        x2 = w - self.border, y2 = h - self.border}

    g.push("all")

    self:draw_scroll_tip(r)
    self:draw_chart_header(r)

    g.setColor({1, 1, 1, 1})
    g.setCanvas(self.rt)
    
    love.graphics.clear(pallete.background)
    local chart_width = self:draw_chart(self.start_line, self.start_line + 
        self.vertical_buf_len)
    g.setCanvas()

    g.setColor({1, 1, 1, 1})
    g.draw(self.rt, (w - chart_width) / 2, r.y1)

    if self.cursor_index > 0 then
        g.setColor(1, 1, 1, 0.3)
        local x = (w - chart_width) / 2
        local y = r.y1 + self.cursor_index * self.font:getHeight()
        g.rectangle("fill", x, y, chart_width, self.font:getHeight())
    end

    self:print_dbg_info()

    g.pop()
end

function pviewer:sort_by_column(idx)
    self.sorted_by_column_num = idx
    table.sort(self.data, function(a, b)
        if self.columns_name[idx] == "date" then
            if a.date and b.date then
                local t1 = a.date
                local t2 = b.date
                local a_sec = t1.year * 365 * 24 * 60 * 60 + t1.yday * 24 * 60 * 60 + t1.hour * 60 * 60 + t1.min * 60 + t1.sec
                local b_sec = t2.year * 365 * 24 * 60 * 60 + t2.yday * 24 * 60 * 60 + t2.hour * 60 * 60 + t2.min * 60 + t2.sec
                return a_sec < b_sec
            end
        elseif self.columns_name[idx] == "nlevel" then
            if a.nlevel and b.nlevel then
                return a.nlevel < b.nlevel
            end
        elseif self.columns_name[idx] == "rating" then
            if a.percent and b.percent then
                return a.percent < b.percent
            end
        elseif self.columns_name[idx] == "pause" then
            if a.pause and b.pause then
                return a.pause < b.pause
            end
        end
    end)
end

function pviewer:sort_by_previous_column()
    if self.sorted_by_column_num - 1 < 1 then
        self:sort_by_column(#self.columns_name)
    else
        self:sort_by_column(self.sorted_by_column_num - 1)
    end
end

function pviewer:sort_by_next_column()
    if self.sorted_by_column_num + 1 > #self.columns_name then
        self:sort_by_column(1)
    else
        self:sort_by_column(self.sorted_by_column_num + 1)
    end
end

function pviewer:scroll_up()
    if self.start_line - self.vertical_buf_len >= 1 then
        self.start_line = self.start_line - self.vertical_buf_len
    end
end

function pviewer:scroll_down()
    if self.start_line + self.vertical_buf_len <= #self.data then
        self.start_line = self.start_line + self.vertical_buf_len
    end
end

function pviewer:move_up()
    if self.cursor_index > 1 then
        if not self.cursor_move_up_animation then
            self.cursor_move_up_animation = true
            self.timer:after(0.1, function()
                self.cursor_move_up_animation = false;
                self.cursor_index = self.cursor_index - 1
            end)
        end
    elseif not self.move_up_animation then
        if self.start_line > 1 then
            self.move_up_animation = true
            self.timer:during(0.1, function()
                self.start_line = self.start_line - 0.1
            end, 
            function() self.move_up_animation = false end)
        end
    end
end

function pviewer:move_down()
    print("move down")
    if self.cursor_index + 1 < self.vertical_buf_len then
        if not self.cursor_move_down_animation then
            --print("after")
            self.cursor_move_down_animation = true
            self.timer:after(0.1, function()
                self.cursor_move_down_animation = false;
                self.cursor_index = self.cursor_index + 1
            end)
        end
    elseif not self.move_down_animation then
        if self.start_line + self.vertical_buf_len <= #self.data then
            self.move_down_animation = true
            self.timer:during(0.1, function()
                self.start_line = self.start_line + 0.1
            end, function() self.move_down_animation = false end)
        end
    end
end

-- добавить клавиши управления для постраничной прокрутки списка результатов.
function pviewer:keypressed(key)
    if key == "escape" then
        menu:goBack()
    elseif key == "left" then
        self:sort_by_previous_column()
    elseif key == "right" then
        self:sort_by_next_column()
    elseif key == "return" or key == "space" then
        -- TODO по нажатию клавиши показать конечную таблицу игры
    elseif key == "home" or key == "kp7" then
        print("pviewer.keypressed('home')")
        self.start_line = 1
        self.cursor_index = 1
    elseif key == "end" or key == "kp1" then
        print("pviewer.keypressed('end')")
        self.start_line = #self.data - self.vertical_buf_len + 1
        print("pviewer.vertical_buf_len = ", pviewer.vertical_buf_len)
        self.cursor_index = self.vertical_buf_len - 1
    end
end

function pviewer:update(dt)
    local kb = love.keyboard
    if kb.isDown("up", "k") then
        self:move_up()
    elseif kb.isDown("down", "j") then
        self:move_down()
    elseif kb.isDown("pageup") then
        self:scroll_up()
    elseif kb.isDown("pagedown") then
        self:scroll_down()
    end
    self.timer:update(dt)
end

return {
    new = pviewer.new
}
