require "love"
local lg = love.graphics
return {
    help = {
        font = lg.newFont("gfx/DejaVuSansMono.ttf", 15),
        gooi = lg.newFont("gfx/DejaVuSansMono.ttf", 13),
    },
    profi = lg.newFont("gfx/DejaVuSansMono.ttf", 13),
    drawstat = {
        gooi = lg.newFont("gfx/DejaVuSansMono.ttf", 13),
    },
    pviewer = lg.newFont("gfx/DejaVuSansMono.ttf", 15),
    nback = {
        font = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 25),
        buttons = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 20),
        central = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 42),
        setupmenu = lg.newFont("gfx/DejaVuSansMono.ttf", 30),
    },
    languageSelector = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 25),
    menu = love.graphics.newFont("gfx/DejaVuSansMono.ttf", 32),
}
