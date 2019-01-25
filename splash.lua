
local _splash = nil

local splash = {}

function splash.init()
    local ok, t = pcall(require "libs.splashes.o-ten-one")
    if ok then
        _splash = t
        _splash.onDone = function() 
            states.pop(menu)
        end
    else
        print("Error in loading splash library. Continuing.")
        states.pop()
    end
end

function splash.keypressed(key)
    _splash:skip()
end

function splash.draw()
    _splash:draw()
end

function splash.update(dt)
    _splash:update(dt)
end

return splash
