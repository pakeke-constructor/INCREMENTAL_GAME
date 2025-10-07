
local UpgradeDescription = require("src.ui.upgrades.upgrade_description_ui")


local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")


---@class UpgradesScene: FreeCameraScene
local upgscene = FreeCameraScene()

---@type ui.UpgradeDescription|nil
upgscene.upgradeDescription = nil





---@param uinfo g.UpgradeInfo
---@param prestige integer
---@return number
---@return number
---@return number
local function getUpgradeCoords(uinfo, prestige)
    local upos = g.getUpgradePosition(uinfo, prestige)
    local size = consts.UPGRADE_IMAGE_SIZE
    local spacing = consts.UPGRADE_GRID_SPACING + size
    local x = upos[1] * spacing
    local y = upos[2] * spacing
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

local function getBestUpgradeType()
    --[[
    TODO: in future, instead of only highlighting "the best"
    upgrade,

    we should highlight all upgrades that
    the player should OBVIOUSLY buy.

    EG if the player has $12,000
    and there is an upgrade that costs $50,
    then they should obviously buy it, and we should highlight that upgrade.
    ]]
    local target = nil
    -- Prioritize sumprice then level
    local sumprice = math.huge
    local level = math.huge

    for _, id in ipairs(g.UPGRADE_LIST) do
        local uinfo = g.getUpgradeInfo(id)
        local price = g.getUpgradePrice(uinfo)

        if not g.isUpgradeHidden(uinfo) and g.canAfford(price) then
            local sp = sumPriceBundle(price)
            local lvl = g.getUpgradeLevel(uinfo)
            if sp < sumprice or (sp == sumprice and lvl < level) then
                target = uinfo
                sumprice = sp
                level = lvl
            end
        end
    end

    return target
end


---@return g.UpgradeInfo? hoveredUpgrade
local function drawUpgradeBoxes()
    --[[
    NOTE: there is a hard-assumption that all
    upgrades are within the same "map".
    ]]
    local hoveredUpgrade = nil
    local bestUpgrade = getBestUpgradeType()

    for _, id in ipairs(g.UPGRADE_LIST) do
        local uinfo = g.getUpgradeInfo(id)
        if not g.isUpgradeHidden(uinfo) then
            local level = g.getUpgradeLevel(uinfo)
            local cx,cy,size = getUpgradeCoords(uinfo, g.getPrestige())
            local x,y,w,h = cx-size/2, cy-size/2, size, size

            local isRecommended = not not (bestUpgrade and (bestUpgrade.type == uinfo.type))
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
            local u = getBestUpgradeType()
            local _ = u and g.tryBuyUpgrade(u)
        end

        if k == "u" and love.keyboard.isDown("lshift")then
            for i=1,20 do
                local u = getBestUpgradeType()
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


