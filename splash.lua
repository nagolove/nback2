
local splash = {}

function splash.init()
    local ok, t = pcall(require "libs.splashes.o-ten-one")
    if ok then
        splash._splash = t
        splash._splash.onDone = function() 
            states.pop(menu)
        end
    else
        print("Error in loading splash library. Continuing.")
        states.pop()
    end
end

function splash.keypressed(key)
    splash._splash:skip()
end

function splash.draw()
    splash._splash:draw()
end

function splash.update(dt)
    splash._splash:update(dt)
end

return splash
