
local geo = {}

function geo.isPointInCircle(px, py, cx, cy, cr)
    return (px - cx)^2 + (py - cy)^2 <= cr ^ 2
end

-- check - is point lie on circle
function isPointOnCircle(px, py, cx, cy, cr, theta)
    return ((px - cx)^2 + (py - cy)^2 - cr ^ 2) <= theta
end

function isPointOnLine(px, py, x1, y1, x2, y2)
    local p = (px - x2) / (x1 - x2)
    if 0 <= p and p <= 1 then
        local x = p * x1 + (1 - p) * x2
        local y = p * y1 + (1 - p) * y2
        return x == y
    end
    return false
end

function geo.dist(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function geo.lineCross(x1, y1, x2, y2, x3, y3, x4, y4)
    --print(x1, y1, x2, y2, x3, y3, x4, y4)
    local divisor = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
    
    -- lines are parralell
    if divisor == 0 then return nil end

    local ua = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)
    ua = ua / divisor
    --local ub = (x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)
    --ub = ub / divisor
    --print("lineCross ua: ",ua, " ub: ", ub)
    local x, y = x1 + ua * (x2 - x1), y1 + ua * (y2 - y1)
    if not (x > x1 and x < x2 and y < y2 and y > y1) then 
        --print("point is not on segment")
        return nil
    end
    return x, y
end

-- [[
-- Function expect array of (x, y) points in yantra internal coordinate format(-1, 1) and translates
-- it to screen size of width and height. Returns translated points array.
-- ]]
function translate2Screen(points, w, h)
    local ret = {}
    for _, v in pairs(points) do
        assert(v.x >= -1 and v.x <= 1, string.format("unsupported x = %f for range (-1, 1)", v.x))
        assert(v.y >= -1 and v.y <= 1, string.format("unsupported y = %f for range (-1, 1)", v.y))
        local t = { x = 2.0 / (v.x + 1) * w, y = 2.0 / (v.y - 1) * h}
        ret[#ret + 1] = t
    end
    return ret
end

return geo
