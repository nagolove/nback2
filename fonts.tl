print('Fonts module loading..')

require "love"
require "globals"

local lg = love.graphics
local inspect = require "inspect"
local baseSize = 13

local t = {
    help = {
        font = lg.newFont(
            SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
            baseSize + 20
        ),
        gooi = lg.newFont(
            SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
            baseSize
        ),
    },
    profi = lg.newFont(
        SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
        baseSize
    ),
    drawstat = {
        gooi = lg.newFont(
            SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
            baseSize
        ),
    },
    pviewer = lg.newFont(
        SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
        baseSize + 2
    ),
    nback = {
        -- где используется?
        font = love.graphics.newFont(
            SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
            baseSize + 12
        ),
        buttons = love.graphics.newFont(
            SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
            baseSize + 7
        ),
        central = love.graphics.newFont(
            SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
            baseSize + 29
        ),
        setupmenu = lg.newFont(
            SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
            baseSize + 35
        ),
    },
    -- выбор языка
    languageSelector = love.graphics.newFont(
        SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
        baseSize + 35
    ),
    menu = love.graphics.newFont(
        SCENEPREFIX .. "gfx/DejaVuSansMono.ttf",
        baseSize + 35
    ),
}

local colors = require 'ansicolors'
print('type(colors)', type(colors))
print('inspect(colors)', inspect(colors))
--print('fonts are:', colors('%{greenbg}' .. inspect(fonts)))

print('Fonts module loading done.')
return t
