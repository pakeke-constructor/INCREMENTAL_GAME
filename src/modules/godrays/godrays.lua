

local godrays = {}



---@param x number
---@param y number
---@param rot number
---@param length number
---@param color objects.Color
---@param startWidth number
---@param widthGrowRate number?
---@param divisions integer?
---@param fadeTo number?
function godrays.drawRay(x, y, rot, length, color, startWidth, widthGrowRate, divisions, fadeTo)
    divisions = divisions or 20
    widthGrowRate = widthGrowRate or 0.1
    fadeTo = fadeTo or 0

    -- Calculate the step length for each division
    local stepLength = length / divisions

    -- Calculate direction vector from rotation
    local dx = math.cos(rot)
    local dy = math.sin(rot)

    -- Perpendicular vector for width
    local px = -dy
    local py = dx
    -- Draw each segment with decreasing opacity
    for i = 0, divisions - 1 do
        -- Calculate opacity for this segment (starts at full, ends at near-zero)
        local alpha = (1 - (i/divisions)) + fadeTo

        -- Width tapers as the ray extends
        local function getWidth(ii)
            return startWidth + startWidth * ((ii+1)/divisions) * ((1+widthGrowRate))
        end

        local sw = getWidth(i)
        local ew = getWidth(i+1)

        local startDist = i * stepLength
        local endDist = (i + 1) * stepLength

        local sx = x + (dx*startDist)
        local sy = y + (dy*startDist)

        local ex = x + (dx*endDist)
        local ey = y + (dy*endDist)

        -- Four corners of the trapezoid
        local x1 = sx - px*sw
        local y1 = sy - py*sw

        local x2 = ex - px*ew
        local y2 = ey - py*ew

        local x3 = ex + px*ew
        local y3 = ey + py*ew

        local x4 = sx + px*sw
        local y4 = sy + py*sw

        -- Set color with diminishing alpha
        love.graphics.setColor(color[1], color[2], color[3], alpha*color[4])

        -- Draw the polygon segment
        love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3, x4, y4)
    end
end



---@class godrays.RayBundle
---@field rayCount integer
---@field color objects.Color
---@field startWidth number
---@field length number
---@field divisions integer?
---@field growRate number?
---@field fadeTo number?
local godrays_RayBundle



---@param x number
---@param y number
---@param rot number
---@param opt godrays.RayBundle
function godrays.drawRays(x,y, rot, opt)
    for i=0, opt.rayCount-1 do
        local r = rot + (2*math.pi) * i/opt.rayCount
        godrays.drawRay(
            x,y, r,
            opt.length, opt.color, opt.startWidth,
            opt.growRate, opt.divisions, opt.fadeTo
        )
    end
end

return godrays

