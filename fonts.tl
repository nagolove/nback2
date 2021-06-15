require "love"
local lg = love.graphics
global SCENEPREFIX = "scenes/nback3/"
print('Fonts module loading..')
local t = {
    help = {
        font = lg.newFont(SCENEPREFIX .. "gfx/DejaVuSansMono.ttf", 15),
        gooi = lg.newFont(SCENEPREFIX .. "gfx/DejaVuSansMono.ttf", 13),
    },
    profi = lg.newFont(SCENEPREFIX .. "gfx/DejaVuSansMono.ttf", 13),
    drawstat = {
        gooi = lg.newFont(SCENEPREFIX .. "gfx/DejaVuSansMono.ttf", 13),
    },
    pviewer = lg.newFont(SCENEPREFIX .. "gfx/DejaVuSansMono.ttf", 15),
    nback = {
        font = love.graphics.newFont(SCENEPREFIX .. "gfx/DejaVuSansMono.ttf", 25),
        buttons = love.graphics.newFont(SCENEPREFIX .. "gfx/DejaVuSansMono.ttf", 20),
        central = love.graphics.newFont(SCENEPREFIX .. "gfx/DejaVuSansMono.ttf", 42),
        setupmenu = lg.newFont(SCENEPREFIX .. "gfx/DejaVuSansMono.ttf", 30),
    },
    languageSelector = love.graphics.newFont(SCENEPREFIX .. "gfx/DejaVuSansMono.ttf", 25),
    menu = love.graphics.newFont(SCENEPREFIX .. "gfx/DejaVuSansMono.ttf", 32),
}
print('Fonts module loading done.')
return t
