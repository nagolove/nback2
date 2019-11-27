local class = require "libs.30log"
local g = love.graphics
local AlignedLabels = class("AlignedLabels")

function AlignedLabels:init(font, screenwidth, color)
    self:clear(font, screenwidth, color)
end

function AlignedLabels:clear(font, screenwidth, color)
    self.screenwidth = screenwidth or self.screenwidth
    self.font = font or self.font
    self.data = {}
    self.colors = {}
    self.default_color = color or {1, 1, 1, 1}
    self.maxlen = 0
end

-- ... - list of pairs of color and text
-- AlignedLabels:add("helllo", {200, 100, 10}, "wwww", {0, 0, 100})
-- плохо, что функция не проверяет параметры на количество и тип
function AlignedLabels:add(...)
    --assert(type(text) == "string")
    local args = {...}
    local nargs = select("#", ...)
    --print("AlignedLabels:add() args = " .. inspect(args))
    if nargs > 2 then
        local colored_text_data = {}
        local colors = {}
        local text_len = 0
        for i = 1, nargs, 2 do
            local text = select(i, ...)
            local color = select(i + 1, ...)
            text_len = text_len + text:len()
            colored_text_data[#colored_text_data + 1] = text
            colors[#colors + 1] = color
        end
        self.data[#self.data + 1] = colored_text_data
        --assert(check_color_t(select(i + 1, ...)))
        self.colors[#self.colors + 1] = colors
        if text_len > self.maxlen then
            self.maxlen = text_len
        end
    else
        self.data[#self.data + 1] = select(1, ...)
        self.colors[#self.colors + 1] = select(2, ...) or self.default_color
    end
end

function AlignedLabels:draw(x, y)
    local dw = self.screenwidth / (#self.data + 1)
    local i = x + dw
    local f = g.getFont()
    local c = {g.getColor()}
    g.setFont(self.font)
    for k, v in pairs(self.data) do
        if type(v) == "string" then
            g.setColor(self.colors[k])
            g.print(v, i - self.font:getWidth(v) / 2, y)
            i = i + dw
        elseif type(v) == "table" then
            local width = 0
            for _, g in pairs(v) do
                width = width + self.font:getWidth(g)
            end
            assert(#v == #self.colors[k])
            local xpos = i - width / 2
            for j, p in pairs(v) do
                --print(type(self.colors[k]), inspect(self.colors[k]), k, j)
                g.setColor(self.colors[k][j])
                g.print(p, xpos, y)
                xpos = xpos + self.font:getWidth(p)
            end
            i = i + dw
        else
            error(string.format(
                "AlignedLabels:draw() : Incorrect type %s in self.data", 
                self.data))
        end
    end
    g.setFont(f)
    g.setColor(c)
end

local alignedtables = {
    new = function(font, screenwidth, color)
        return AlignedLabels:new(font, screenwidth, color)
    end
}

return alignedtables

