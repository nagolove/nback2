require "math"

lume = require "lume"
lovebird = require "lovebird"

function love.load()
end

function love.update()
    lovebird.update()
    print "to console?"
end

function love.draw()
    for i=1, 10, 0.1 do
       love.graphics.print('Hello World!', 400 + 150 * math.cos(i), 300 + 150 * math.sin(i))
    end
end
