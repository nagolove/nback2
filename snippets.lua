local gr = love.graphics

function write2Canvas(func)
    local fname = "draft.png"
    local image
    pcall(function()
        image = gr.newImage(fname)
    end)
    local canvas = gr.newCanvas()
    gr.setCanvas(canvas)
    if image then
        gr.setColor{0, 0, 0}
        gr.draw(image)
    end
    func()
    gr.setCanvas()
    local imgdata = canvas:newImageData()
    imgdata:encode("png", fname)
end

function dist(x1, y1, x2, y2) 
    return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5 
end

function pointInPolygon(pgon, tx, ty)
    if (#pgon < 6) then
        return false
    end

    local x1 = pgon[#pgon - 1]
    local y1 = pgon[#pgon]
    local cur_quad = getQuad(tx,ty,x1,y1)
    local next_quad
    local total = 0
    local i

    for i = 1,#pgon,2 do
        local x2 = pgon[i]
        local y2 = pgon[i+1]
        next_quad = getQuad(tx,ty,x2,y2)
        local diff = next_quad - cur_quad

        if (diff == 2) or (diff == -2) then
            if (x2 - (((y2 - ty) * (x1 - x2)) / (y1 - y2))) < tx then
                diff = -diff
            end
        elseif diff == 3 then
            diff = -1
        elseif diff == -3 then
            diff = 1
        end

        total = total + diff
        cur_quad = next_quad
        x1 = x2
        y1 = y2
    end

    return (math.abs(total)==4)
end

function getQuad(axis_x,axis_y,vert_x,vert_y)
    if vert_x < axis_x then
        if vert_y < axis_y then
            return 1
        else
            return 4
        end
    else
        if vert_y < axis_y then
            return 2
        else
            return 3
        end	
    end
end
