local pallete = require "pallete"
local nback = require "nback"

local help = {
    font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 15),
    init = function() end,
}

local lg = love.graphics
local ls = love.system

function help.update(dt)
    linesbuf:push_text_i("fps " .. love.timer.getFPS())
    linesbuf:push_text_i(string.format("ls.getOS() = %s", ls.getOS()))
    linesbuf:push_text_i(string.format("ls.getClipboardText() = %s", ls.getClipboardText()))
    linesbuf:push_text_i(string.format("ls.getProcessorCount() = %d", ls.getProcessorCount()))
    linesbuf:push_text_i(string.format("ls.getPowerInfo() = %s", tostring(lg.getPowerInfo())))
end

function help.draw()
    lg.setColor(1, 1, 1, 1)
    lg.clear(pallete.background)
    lg.push("all")
    lg.setFont(help.font)
    local w, h = lg.getDimensions()
    local y = 20
    lg.printf("This is a bla-bla", 0, y, w, "center")
    y = y + help.font:getHeight()
    lg.printf("Put description here!", 0, y, w, "center")
    --FIXME Not work, using nil table nback here
    lg.pop()
end

function help.keypressed(key)
    if key == "escape" then
        states.pop()
    end
end

return help
