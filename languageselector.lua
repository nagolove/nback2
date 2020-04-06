local inspect = require "libs.inspect"
local pallete = require "pallete"
local gr = love.graphics

local LanguageSelector = {}
LanguageSelector.__index = LanguageSelector

function LanguageSelector:new()
    local self = setmetatable({}, LanguageSelector)
    self.languages = {}
    self.font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 25)
    self.locale = nil
    for _, v in pairs(love.filesystem.getDirectoryItems("locales")) do 
        local chunk, errmsg = love.filesystem.load("locales/" .. v)
        --print(chunk().language, errmsg)
        if not errmsg and type(chunk) == "function" then
            setfenv(chunk, {})
            table.insert(self.languages, { id = chunk().language, locale = string.match(v, "(%S+)%.")})
        end
    end
    print("languages", inspect(self.languages))
    self.selected = 1
    self.beetweenClicks = 0.4
    self:prepareDraw()
    return self
end

function LanguageSelector:getLocale()
    return self.locale
end

function LanguageSelector:prepareDraw()
    local w, h = gr.getDimensions()
    local menuItemHeight = self.font:getHeight() + 6
    local menuHeight = #self.languages * menuItemHeight
    local menuWidth = 0

    for k, v in pairs(self.languages) do
        local width = self.font:getWidth(v.id)
        if width > menuWidth then
            menuWidth = width
        end
    end

    local x0, y0 = 0, 0
    self.x, self.y = (w - menuWidth) / 2, (h - menuHeight) / 2
    self.canvas = gr.newCanvas(menuWidth, menuHeight)
    gr.setFont(self.font)
    gr.setColor(pallete.languageMenuText)
    gr.setCanvas(self.canvas)

    self.items = {}
    local x, y = self.x, self.y
    for k, v in pairs(self.languages) do
        --print("v", v.id)
        gr.print(v.id, x0, y0)
        y0 = y0 + menuItemHeight
        table.insert(self.items, { x = x, y = y, w = menuWidth, h = menuItemHeight })
        y = y + menuItemHeight
    end

    gr.setCanvas()

    self.canvas:newImageData():encode("png", "langlist.png")
end

function LanguageSelector:draw()
    local x, y = self.x, self.y
    gr.clear(pallete.background)
    gr.setColor{1, 1, 1, 1}
    gr.draw(self.canvas, x, y)

    local prevLineWidth = gr.getLineWidth()
    if self.selected then
        local v = self.items[self.selected]
        gr.setColor(pallete.selectedLanguageBorder)
        gr.rectangle("line", v.x, v.y, v.w, v.h)
    end
    gr.setLineWidth(prevLineWidth)

    --gr.setColor{1, 1, 1, 1}
    --gr.print("hihihi", 100, 100)
end

function LanguageSelector:resize(neww, newh)
    print("LanguageSelector:resize()")
    self:prepareDraw()
end

function LanguageSelector:update(dt)
end

function LanguageSelector:touchpressed(id, x, y)
end

function LanguageSelector:touchreleased(id, x, y)
end

function LanguageSelector:touchmoved(id, x, y, dx, dy)
end

function LanguageSelector:mousepressed(x, y, btn, istouch)
    print("LanguageSelector:mousepressed")
    for k, v in pairs(self.items) do
        print("v", inspect(v))
        if pointInRect(x, y, v.x, v.y, v.w, v.h) then
            self.locale = self.languages[k].locale
        end
    end
end

function LanguageSelector:mousereleased(x, y, btn, istouch)
end

function LanguageSelector:mousemoved(x, y, dx, dy, istouch)
    for k, v in pairs(self.items) do
        --print("v", inspect(v))
        if pointInRect(x, y, v.x, v.y, v.w, v.h) then
            --self.locale = self.languages[k]
            self.selected = k
            --print(inspect(k))
            linesbuf:push(1, "LanguageSelector.selected %d", self.selected)
        end
    end
    --print("self.locale", self.locale)
    --print("self.selected", self.selected)
end

return LanguageSelector
