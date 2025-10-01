


---@class upgrades
local upgrades = {}



---@param uinfo g.UpgradeInfo
---@return number
---@return number
---@return number
local function getUpgradeCoords(uinfo)
    local size = consts.UPGRADE_IMAGE_SIZE
    local spacing = consts.UPGRADE_GRID_SPACING + size
    local x = uinfo.x * spacing
    local y = uinfo.y * spacing
    -- x,y is center of box
    -- `size` is size of upgrade-box
    return x,y,size
end



---@return g.UpgradeInfo?
function upgrades._draw()
    --[[
    NOTE: there is a hard-assumption that all
    upgrades are within the same "map".

    I dont think there will be though; so its fine
    ]]
    local hoveredUpgrade = nil

    for _, id in ipairs(g.UPGRADE_LIST) do
        local uinfo = g.getUpgradeInfo(id)
        if not g.isUpgradeHidden(uinfo) then
            local level = g.getUpgradeLevel(uinfo)
            local cx,cy,size = getUpgradeCoords(uinfo)
            local x,y,w,h = cx-size/2, cy-size/2, size, size

            local isHovered, wasJustClicked = ui.upgradeBoxUI(uinfo, level, x,y,w,h)
            if isHovered then
                hoveredUpgrade = uinfo
            end
            if wasJustClicked then
                g.tryBuyUpgrade(uinfo)
            end
        end
    end

    return hoveredUpgrade
end





return upgrades


