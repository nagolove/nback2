require "libs.splashes.o-ten-one"

local record Splash
    _splash: any

    init: function()
    keypressed: function(key: string)
    draw: function()
    update: function(dt: number)
end

local splash: Splash = {}

function splash.init()
    --local ok, t: boolean, any = pcall(require "libs.splashes.o-ten-one")
    -- XXX Not work
    --[[ 
    if ok then
        splash._splash = t
        splash._splash.onDone = function() 
            states.pop(menu)
        end
    else
        print("Error in loading splash library. Continuing.")
        states.pop()
    end
    --]]
end

function splash.keypressed(_: string)
    --(splash._splash as LibSplash):skip()
end

function splash.draw()
    --(splash._splash as LibSplash):draw()
end

function splash.update(_: number)
    --(splash._splash as LibSplash):update(dt)
end

return splash

