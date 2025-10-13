local worldutil = {}


---@param x integer
---@param y integer
function worldutil.getUpgradeCoords(x, y)
    local size = consts.UPGRADE_IMAGE_SIZE
    local spacing = consts.UPGRADE_GRID_SPACING + size
    return x * spacing, y * spacing, size
end


return worldutil
