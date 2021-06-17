require "love"
require "common"

local inspect = require "inspect"
local pallete = require "pallete"
local gr = love.graphics

local record Language
    id: string
    locale: string
end

global record LanguageSelector 

    record Rect
        x: number
        y: number
        w: number
        h: number
    end

    new: function(): LanguageSelector
    prepareDraw: function
    draw: function
    resize: function
    update: function(LanguageSelector, number)
    touchpressed: function(LanguageSelector, any, number, number)
    touchreleased: function(LanguageSelector, any, number, number)
    touchmoved: function(LanguageSelector, any, number, number, number, number)
    up: function
    down: function
    keypressed: function(LanguageSelector, string)
    mousepressed: function(LanguageSelector, number, number, number, boolean)
    mousemoved: function(LanguageSelector, number, number, number, number, boolean)

    languages: {Language}
    font: love.graphics.Font
    locale: string
    selected: integer
    beetweenClicks: number
    x: number
    y: number
    canvas: love.graphics.Canvas
    items: {Rect}
end

local LanguageSelector_mt: metatable<LanguageSelector> = {
    __index = LanguageSelector,
}

function LanguageSelector.new(): LanguageSelector
    local self = setmetatable({} as LanguageSelector, LanguageSelector_mt)
    self.languages = {}
    self.font = require "fonts".languageSelector
    self.locale = nil
    for _, v in ipairs(love.filesystem.getDirectoryItems(SCENEPREFIX .. "locales")) do 
        local chunk, errmsg: function, string = love.filesystem.load(SCENEPREFIX .. "locales/" .. v)
        print("--", chunk(), errmsg)
        if not errmsg and type(chunk) == "function" then
            -- FIXME setfenv not work in Teal
            --setfenv(chunk, {})
            table.insert(self.languages, { 
                id = (chunk() as {any:any}).language as string, 
                locale = string.match(v, "(%S+)%.")
            })
        end
    end
    print("languages", inspect(self.languages))
    self.selected = 1
    self.beetweenClicks = 0.4
    self:prepareDraw()
    return self
end

function LanguageSelector:prepareDraw()
    local w, h = gr.getDimensions()
    local menuItemHeight = self.font:getHeight() + 6
    local menuHeight = #self.languages * menuItemHeight
    local menuWidth = 0.

    for _, v in ipairs(self.languages) do
        local width = self.font:getWidth(v.id)
        print('in cycle width = ', width)
        if width > menuWidth then
            menuWidth = width
        end
    end

    local x0, y0 = 0., 0.
    self.x, self.y = (w - menuWidth) / 2, (h - menuHeight) / 2
    print("menuWidth, menuHeight", menuWidth, menuHeight)
    self.canvas = gr.newCanvas(menuWidth, menuHeight)
    gr.setFont(self.font)
    gr.setColor(pallete.languageMenuText)
    gr.setCanvas(self.canvas)

    self.items = {}
    local x, y = self.x, self.y
    for _, v in ipairs(self.languages) do
        --print("v", v.id)
        gr.print(v.id, x0, y0)
        y0 = y0 + menuItemHeight
        table.insert(self.items, { x = x, y = y, w = menuWidth, h = menuItemHeight })
        y = y + menuItemHeight
    end

    gr.setCanvas()

    --self.canvas:newImageData():encode("png", "langlist.png")
end

function LanguageSelector:draw()
    local x, y = self.x, self.y
    --gr.clear(pallete.background)
    gr.setColor{1, 1, 1, 1}
    local type Drawable = love.graphics.Drawable
    gr.draw(self.canvas as Drawable, x, y)

    local prevLineWidth = gr.getLineWidth()
    if self.selected then
        local v = self.items[self.selected]
        gr.setColor(pallete.selectedLanguageBorder)
        gr.setLineWidth(3)
        gr.rectangle("line", v.x, v.y, v.w, v.h)
    end
    gr.setLineWidth(prevLineWidth)

    --gr.setColor{1, 1, 1, 1}
    --gr.print("hihihi", 100, 100)
end

function LanguageSelector:resize()
    print("LanguageSelector:resize()")
    self:prepareDraw()
end

function LanguageSelector:update(_: number)
end

function LanguageSelector:touchpressed(_: any, _: number, _: number)
end

function LanguageSelector:touchreleased(_: any, _: number, _: number)
end

function LanguageSelector:touchmoved(_: any, _: number, _: number, _: number, _: number)
end

function LanguageSelector:up()
    if self.selected - 1 < 1 then
        self.selected = #self.items
    else
        self.selected = self.selected - 1
    end
end

function LanguageSelector:down()
    if self.selected + 1 > #self.items then
        self.selected = 1
    else
        self.selected = self.selected + 1
    end
end

function LanguageSelector:keypressed(key: string)
    if key == "up" or key == "k" then
        self:up()
    elseif key == "down" or key == "j" then
        self:down()
    elseif key == "space" or key == "return" then
        print("select")
        self.locale = self.languages[self.selected].locale
    end
end

function LanguageSelector:mousepressed(x: number, y: number, _: number, _: boolean)
    print("LanguageSelector:mousepressed")
    for k, v in ipairs(self.items) do
        print("v", inspect(v))
        if pointInRect(x, y, v.x, v.y, v.w, v.h) then
            self.locale = self.languages[k].locale
        end
    end
end

function LanguageSelector:mousemoved(x: number, y: number, _: number, _: number, _: boolean)
    for k, v in ipairs(self.items) do
        --print("v", inspect(v))
        if pointInRect(x, y, v.x, v.y, v.w, v.h) then
            --self.locale = self.languages[k]
            self.selected = k
            --print(inspect(k))
            --linesbuf:push(1, "LanguageSelector.selected %d", self.selected)
        end
    end
    --print("self.locale", self.locale)
    --print("self.selected", self.selected)
end

return LanguageSelector

