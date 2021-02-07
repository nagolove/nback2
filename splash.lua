local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pcall = _tl_compat and _tl_compat.pcall or pcall; require("libs.splashes.o-ten-one")

local Splash = {}








local splash = {}

function splash.init()
   local ok, t = pcall(require("libs.splashes.o-ten-one"))












end

function splash.keypressed(key)

end

function splash.draw()

end

function splash.update(dt)

end

return splash
