require "love"

local g = love.graphics

global type AlignedLabels = record
    screenwidth: number
    font: love.graphics.Font
    data: {string}
    colors: {{number}}
    default_color: {number}
    maxlen: number

    new: function(love.graphics.Font, number, {number})
    clear: function(AlignedLabels, love.graphics.Font, number, {number})
    add: function(AlignedLabels, ...:any)
    draw: function(AlignedLabels, number, number)
end

local AlignedLabels_mt: metatable<AlignedLabels> = {
    __index = AlignedLabels
}

function AlignedLabels.new(font: love.graphics.Font, screenwidth: number, color: {number}): AlignedLabels
    local self: AlignedLabels = {}
    setmetatable(self, AlignedLabels_mt)
    self:clear(font, screenwidth, color)
    return self
end

function AlignedLabels:clear(font: love.graphics.Font, screenwidth: number, color: {number})
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
function AlignedLabels:add(...: any)
    local nargs = select("#", ...)
    if nargs > 2 then
        local colored_text_data: {string} = {}
        local colors: {{number}} = {}
        local text_len = 0
        for i = 1, nargs, 2 do
            local text = select(i, ...) as string
            local color = select(i + 1, ...) as {number}
            text_len = text_len + text:len()
            colored_text_data[#colored_text_data + 1] = text
            colors[#colors + 1] = color
        end

        -- XXX может не работать
        --self.data[#self.data + 1] = colored_text_data
        self.data = colored_text_data

        -- XXX может не работать
        --self.colors[#self.colors + 1] = colors
        self.colors = colors

        if text_len > self.maxlen then
            self.maxlen = text_len
        end
    else
        self.data[#self.data + 1] = select(1, ...) as string
        self.colors[#self.colors + 1] = (select(2, ...) as {number}) or self.default_color
    end
end

function AlignedLabels:draw(x: number, y: number)
    local dw = self.screenwidth / (#self.data + 1)
    local i = x + dw
    local f = g.getFont()
    local c = {g.getColor()}
    g.setFont(self.font)
    for k, v in pairs(self.data as {any:any}) do
        if type(v) == "string" then
            g.setColor(self.colors[k as integer])
            g.print(v as string, i - self.font:getWidth(v as string) / 2, y)
            i = i + dw
        elseif type(v) == "table" then
            local width = 0.
            for _, g in ipairs(v as {string}) do
                width = width + self.font:getWidth(g)
            end
            --assert(#(v as {string}) == #self.colors[k as number])
            assert(#(v as {string}) == #self.colors[math.floor(k as number)])
            local xpos = i - width / 2
            for j, p in pairs(v as {any:any}) do
                --print(type(self.colors[k]), inspect(self.colors[k]), k, j)
                g.setColor(self.colors[math.floor(k as number)][math.floor(j as number)])
                g.print(p as string, xpos, y)
                xpos = xpos + self.font:getWidth(p as string)
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

return AlignedLabels


