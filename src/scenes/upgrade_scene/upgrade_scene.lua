
local UpgradeDescription = require("src.ui.upgrades.upgrade_description_ui")


local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")


---@class UpgradesScene: FreeCameraScene
local upgscene = FreeCameraScene()

---@type ui.UpgradeDescription|nil
upgscene.upgradeDescription = nil





---@param x integer
---@param y integer
local function getUpgradeCoords(x, y)
    local spacing = consts.UPGRADE_GRID_SPACING + consts.UPGRADE_IMAGE_SIZE
    return math.floor((x + 0.5) * spacing), math.floor((y + 0.5) * spacing)
end



---Draws connector.
---@param upg1 g.Tree.Upgrade
---@param upg2 g.Tree.Upgrade
local function drawConnector(upg1, upg2)
    local x1,y1 = getUpgradeCoords(upg1.x, upg1.y)
    local x2,y2 = getUpgradeCoords(upg2.x, upg2.y)

    love.graphics.setColor(g.COLORS.UPGRADE_CONNECTOR)
    love.graphics.line(x1,y1,x2,y2)
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




---@param tree g.Tree
---@return g.Tree.Upgrade?
local function getCheapestUpgrade(tree)
    local bestPrice = 0xfffffffffffff
    local bestUpgrade = nil

    for _, upg in ipairs(tree:getUpgrades()) do
        local uinfo = g.getUpgradeInfo(upg.id)
        local lv = upg.level

        if (not tree:isUpgradeHidden(upg)) and (lv < uinfo.maxLevel) then
            local price = tree:getUpgradePrice(upg)
            if price.money < bestPrice then
                bestPrice = price.money
                bestUpgrade = upg
            end
        end
    end

    return bestUpgrade
end



local function getBestUpgradeAffordThreshold()
    ---@type g.Bundle
    local result = {}

    local tree = g.getUpgTree()
    for _, upg in ipairs(tree:getUpgrades()) do
        local uinfo = g.getUpgradeInfo(upg.id)
        local level = g.getUpgradeLevel(uinfo)

        if level > 0 and not tree:isUpgradeHidden(upg) then
            local price = tree:getUpgradePrice(upg, level)

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
    local prestige = g.getPrestige()

    local tree = g.getUpgTree()
    local upgrades = tree:getUpgrades()
    for _, upg in ipairs(upgrades) do
        local uinfo = g.getUpgradeInfo(upg.id)
        if not tree:isUpgradeHidden(upg) then
            -- Draw connector first
            for _, upg2 in ipairs(tree:getConnectors(upg)) do
                drawConnector(upg, upg2)
            end
        end
    end

    for _, upg in ipairs(upgrades) do
        local uinfo = g.getUpgradeInfo(upg.id)
        if not tree:isUpgradeHidden(upg) then
            local level = g.getUpgradeLevel(uinfo)

            -- Then draw upgrade box
            local x, y = getUpgradeCoords(upg.x, upg.y)
            local isHovered, wasJustClicked, wasJustHovered = ui.upgradeBoxUI(tree, upg, level, x,y)
            if isHovered then
                hoveredUpgrade = uinfo
            end
            if wasJustHovered then
                g.playUISound("ui_tick", 1,1)
            end
            if wasJustClicked then
                g.playUISound("ui_click_satisfying", 0.8,0.7,0,0)
                tree:tryBuyUpgrade(upg)
                hoveredUpgrade=nil
            end
        end
    end
    return hoveredUpgrade
end



local drawBackground
do
local image = love.graphics.newImage("src/scenes/upgrade_scene/upgrade_background_tile.png")
function drawBackground()
    -- draw background:
    love.graphics.clear(0.4,0.6,0.8)
    local GAP = image:getWidth()*2
    local rot = math.sin(love.timer.getTime() / 1.5) / 4
    local w,h = image:getDimensions()
    love.graphics.scale(ui.getUIScaling())
    local delta = (love.timer.getTime() * 2) % GAP
    for x=-300, 3000, GAP do
        for y=-300, 2000, GAP do
            love.graphics.setColor(1,1,1,0.07)
            love.graphics.draw(image, x,y-delta, rot, 1,1,w/2,h/2)
        end
    end
end

end


function upgscene:draw()
    local header, body = Kirigami(0,0,ui.getScaledUIDimensions()):splitVertical(1,5)
    header = header:padRatio(0.2)

    drawBackground()

    love.graphics.setColor(1,1,1)

    self:setCamera()
    local hoveredUpgrade = drawUpgradeBoxes()

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    self:renderMapButton()

    g.getHUD():draw({profile = false})

    if hoveredUpgrade then
        if not self.upgradeDescription or self.upgradeDescription:getUpgrade() ~= hoveredUpgrade.type then
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
    local tree = g.getUpgTree()
    if consts.DEV_MODE then
        -- upgrades for dev
        if k == "u" then
            local u = getCheapestUpgrade(tree)
            local _ = u and tree:tryBuyUpgrade(u)
        end

        if k == "u" and love.keyboard.isDown("lshift")then
            for i=1,20 do
                local u = getCheapestUpgrade(tree)
                local _ = u and tree:tryBuyUpgrade(u)
            end
        end
    end
end



upgscene.keyreleased = upgscene.defaultKeyreleased
upgscene.wheelmoved = upgscene.defaultWheelmoved
upgscene.mousemoved = upgscene.defaultMousemoved



return upgscene


