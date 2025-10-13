local worldutil = {}


---@param x number
---@param y number
---@param rad number
---@param circleColor objects.Color
---@param circleBorderColor objects.Color
function worldutil.drawHarvestCircle(x, y, rad, circleColor, circleBorderColor)
    love.graphics.setColor(circleColor)
    love.graphics.circle("fill", x,y, rad)
    local lw = love.graphics.getLineWidth()
    love.graphics.setLineWidth(math.floor(rad / 15))
    love.graphics.setColor(circleBorderColor)
    love.graphics.circle("line", x,y, rad)
    love.graphics.setLineWidth(lw)
end


---@param dt number
---@param value number
---@param velocity number
---@param maxvalue number
---@return number @New value
---@return boolean @Should direction be flipped?
local function computeValueBouncing(dt, value, velocity, maxvalue)
    value = value + velocity * dt
    if value < 0 then
        return -value, true
    elseif value >= maxvalue then
        return 2 * maxvalue - value, true
    end

    return value, false
end

---@param world g.World
---@param obj {x:number,y:number,dirX:number,dirY:number,speed:number}
---@param dt number
function worldutil.updateLikeDVD(world, obj, dt)
    local flip

    obj.x, flip = computeValueBouncing(dt, obj.x, obj.speed * obj.dirX, world.WIDTH)
    if flip then
        obj.dirX = -obj.dirX
    end

    obj.y, flip = computeValueBouncing(dt, obj.y, obj.speed * obj.dirY, world.HEIGHT)
    if flip then
        obj.dirY = -obj.dirY
    end
end


return worldutil
