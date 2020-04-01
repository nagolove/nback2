local inspect = require "libs.inspect"
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
        print(chunk().language, errmsg)
        if not errmsg and type(chunk) == "function" then
            setfenv(chunk, {})
            table.insert(self.languages, chunk().language)
        end
    end
    self:prepareDraw()
    return self
end

function LanguageSelector:getLocale()
    return self.locale
end

function LanguageSelector:prepareDraw()
    local w, h = gr.getDimensions()
    local menuItemHeight = self.font:getHeight() + 2
    local menuHeight = #self.languages * menuItemHeight
    local menuWidth = 0
    for k, v in pairs(self.languages) do
        local width = self.font:getWidth(v)
        if width > menuWidth then
            menuWidth = width
        end
    end

    self.x, self.y = (w - menuWidth) / 2, (h - menuHeight) / 2

    self.canvas = gr.newCanvas(menuWidth, menuHeight)
    gr.setCanvas(self.canvas)
    local x, y = 0, 0
    for k, v in pairs(self.languages) do
        print("v", v)
        gr.print(v, x, y)
        y = y + self.font:getHeight()
    end
    gr.setCanvas()

    self.items = {}
    x, y = self.x, self.y
    for k, v in pairs(self.languages) do
        table.insert(self.items, { x = self.x, y = self.y, w = menuWidth, h = menuItemHeight })
        y = y + menuItemHeight
    end
end

function LanguageSelector:draw()
    local x, y = self.x, self.y
    gr.setColor{1, 1, 1, 1}
    gr.draw(self.canvas, x, y)
end

function LanguageSelector:update(dt)
end

function LanguageSelector:touchpressed(id, x, y)
end

function LanguageSelector:touchreleased(id, x, y)
end

function LanguageSelector:touchmoved(id, x, y, dx, dy)
end

function LanguageSelector:mousepressed(id, x, y)
    print("LanguageSelector:mousepressed")
    for k, v in pairs(self.items) do
        print("v", inspect(v))
        if pointInRect(x, y, v.x, v.y, v.w, v.h) then
            self.locale = self.languages[k]
        end
    end
    print("self.locale", self.locale)
end

function LanguageSelector:mousereleased(id, x, y)
end

function LanguageSelector:mousemoved(id, x, y, dx, dy)
end
return LanguageSelector
