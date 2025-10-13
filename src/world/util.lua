local worldutil = {}


---@param x integer
---@param y integer
function worldutil.getUpgradeCoords(x, y)
    local size = consts.UPGRADE_IMAGE_SIZE
    local spacing = consts.UPGRADE_GRID_SPACING + size
    return x * spacing, y * spacing, size
end


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


return worldutil
