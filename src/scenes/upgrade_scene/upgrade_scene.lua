
local UpgradeDescription = require("src.ui.upgrades.upgrade_description_ui")


local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")


---@class UpgradesScene: FreeCameraScene
local upgscene = FreeCameraScene()

---@type ui.UpgradeDescription|nil
upgscene.upgradeDescription = nil





---@param tx integer
---@param ty integer
---@return number
---@return number
---@return number
local function getUpgradeCoords(tx, ty)
    local size = consts.UPGRADE_IMAGE_SIZE
    local spacing = consts.UPGRADE_GRID_SPACING + size
    local x = tx * spacing
    local y = ty * spacing
    -- x,y is center of box
    -- `size` is size of upgrade-box
    return x,y,size
end


---@param bundle g.Bundle
---@return number
local function sumPriceBundle(bundle)
    local result = 0

    for _, v in pairs(bundle) do
        result = result + v
    end

    return result
end




---@return g.UpgradeInfo|nil
local function getCheapestUpgrade()
    local bestPrice = 0xfffffffffffff
    local bestUpgrade = nil

    for _, id in g.iterateUpgradeTree(g.getPrestige()) do
        local uinfo = g.getUpgradeInfo(id)
        local lv = g.getUpgradeLevel(uinfo)

        if (not g.isUpgradeHidden(uinfo)) and (lv < uinfo.maxLevel) then
            local price = g.getUpgradePrice(uinfo)
            if price.money < bestPrice then
                bestPrice = price.money
                bestUpgrade = uinfo
            end
        end
    end

    return bestUpgrade
end



local function getBestUpgradeAffordThreshold()
    ---@type g.Bundle
    local result = {}

    for _, id in g.iterateUpgradeTree(g.getPrestige()) do
        local uinfo = g.getUpgradeInfo(id)
        local level = g.getUpgradeLevel(uinfo)

        if level > 0 and not g.isUpgradeHidden(uinfo) then
            local price = g.getUpgradePrice(uinfo, level)

            for k, v in pairs(price) do
                result[k] = math.max(result[k] or 0, v)
            end
        end
    end

    -- Apply 5% threshold
    for k, v in pairs(result) do
        result[k] = math.floor(v * 0.05 + 0.5)
    end
    return result
end

---Performs b1 >= b2 across all bundle elements
---@param b1 g.Bundle
---@param b2 g.Bundle
local function bundleGreaterOrEqual(b1, b2)
    local keys = {}
    for k in pairs(b1) do
        keys[k] = true
    end
    for k in pairs(b2) do
        keys[k] = true
    end

    for k in pairs(keys) do
        if (b1[k] or 0) < (b2[k] or 0) then
            return false
        end
    end

    return true
end


---@return g.UpgradeInfo? hoveredUpgrade
local function drawUpgradeBoxes()
    --[[
    NOTE: there is a hard-assumption that all
    upgrades are within the same "map".
    ]]
    local hoveredUpgrade = nil
    local bestUpgradeThreshold = getBestUpgradeAffordThreshold()

    for pos, id in g.iterateUpgradeTree(g.getPrestige()) do
        local uinfo = g.getUpgradeInfo(id)
        if not g.isUpgradeHidden(uinfo) then
            local level = g.getUpgradeLevel(uinfo)
            local cx,cy,size = getUpgradeCoords(pos.x, pos.y)
            local x,y,w,h = cx-size/2, cy-size/2, size, size

            local isRecommended = bundleGreaterOrEqual(bestUpgradeThreshold, g.getUpgradePrice(uinfo, level))
            local isHovered, wasJustClicked = ui.upgradeBoxUI(uinfo, level, x,y,w,h, isRecommended)
            if isHovered then
                hoveredUpgrade = uinfo
            end
            if wasJustClicked then
                g.tryBuyUpgrade(uinfo)
                hoveredUpgrade=nil
            end
        end
    end
    return hoveredUpgrade
end



function upgscene:draw()
    self:setCamera()
    local header, body = Kirigami(0,0,ui.getScaledUIDimensions()):splitVertical(1,5)
    header = header:padRatio(0.2)

    love.graphics.clear(0.2,0.4,0.8)
    love.graphics.setColor(1,1,1)

    local hoveredUpgrade = drawUpgradeBoxes()

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    self:renderNavbar()

    g.getHUD():draw(self.camera, {profile = false})

    if hoveredUpgrade then
        if not self.upgradeDescription or self.upgradeDescription:getType() ~= hoveredUpgrade.type then
            self.upgradeDescription = UpgradeDescription(hoveredUpgrade)
        end

        local r = Kirigami(0, 0, ui.getScaledUIDimensions())
        local mx, my = ui.getMouse()
        local descriptionBoxR = Kirigami(0, 0, self.upgradeDescription:getDimensions())
            :set(mx + 14, my - 3)
            :clampInside(r:padUnit(4))

        -- Upgrade description
        self.upgradeDescription:draw(descriptionBoxR.x, descriptionBoxR.y)
    else
        self.upgradeDescription = nil
    end

    ui.endUI()
end




function upgscene:update(dt)
    self:updateCamera(dt)
    g.getHUD():update(dt)
end


function upgscene:keypressed(k)
    if consts.DEV_MODE then
        -- upgrades for dev
        if k == "u" then
            local u = getCheapestUpgrade()
            local _ = u and g.tryBuyUpgrade(u)
        end

        if k == "u" and love.keyboard.isDown("lshift")then
            for i=1,20 do
                local u = getCheapestUpgrade()
                local _ = u and g.tryBuyUpgrade(u)
            end
        end
    end
end


function upgscene:mousepressed(x,y, button)
    
end

function upgscene:mousereleased(x,y, button)
end



return upgscene


