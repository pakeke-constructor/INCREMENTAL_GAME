
local UpgradeDescription = require("src.ui.upgrades.upgrade_description_ui")

local newDevTree = require("src.upgrades.dev_tree")


local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")


---@class UpgradesScene: FreeCameraScene
local upgscene = FreeCameraScene()




function upgscene:init()
    self.dev_editMode = false
    ---@type {x:number,y:number,isAddingConnector:false}?
    self.dev_editModeSelection = nil

    self.dev_revealUpgrades = false

    ---@type ui.UpgradeDescription|nil
    self.upgradeDescription = nil
end



---@param x integer
---@param y integer
local function getUpgradeGridCoords(x, y)
    local spacing = consts.UPGRADE_GRID_SPACING + consts.UPGRADE_IMAGE_SIZE
    return math.floor((x + 0.5) * spacing), math.floor((y + 0.5) * spacing)
end



---Draws connector.
---@param upg1 g.Tree.Upgrade
---@param upg2 g.Tree.Upgrade
local function drawConnector(upg1, upg2)
    local x1,y1 = getUpgradeGridCoords(upg1.x, upg1.y)
    local x2,y2 = getUpgradeGridCoords(upg2.x, upg2.y)

    local lw=love.graphics.getLineWidth()
    love.graphics.setLineWidth(8)
    love.graphics.setColor(g.COLORS.UPGRADE_CONNECTOR)
    love.graphics.line(x1,y1,x2,y2)
    love.graphics.setLineWidth(lw)
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

    for _, upg in ipairs(tree:getUpgradesOnTree()) do
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
    for _, upg in ipairs(tree:getUpgradesOnTree()) do
        local level = upg.level

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


---@param self UpgradesScene
---@return g.Tree.Upgrade? hoveredUpgrade
local function drawUpgradeBoxes(self)
    --[[
    NOTE: there is a hard-assumption that all
    upgrades are within the same "map".
    ]]
    local hoveredUpgrade = nil
    local bestUpgradeThreshold = getBestUpgradeAffordThreshold()
    local prestige = g.getPrestige()

    local tree = g.getUpgTree()
    local upgrades = tree:getUpgradesOnTree()
    for _, upg in ipairs(upgrades) do
        if not tree:isUpgradeHidden(upg) then
            -- Draw connector first
            for _, upg2 in ipairs(tree:getNeighbors(upg.x,upg.y)) do
                drawConnector(upg, upg2)
            end
        end
    end

    for _, upg in ipairs(upgrades) do
        local forceVisible = (consts.DEV_MODE and (self.dev_revealUpgrades or self.dev_editMode))
        -- if editMode or revealUpgrades, 
        if forceVisible or (not tree:isUpgradeHidden(upg)) then
            local level = upg.level

            -- Then draw upgrade box
            local price = tree:getUpgradePrice(upg)
            local x, y = getUpgradeGridCoords(upg.x, upg.y)

            local dontDraw = g.getBundleCostRatio(price) < 0.2
            -- its WAYYY too expensive... just draw black square

            local isHovered, wasJustClicked, wasJustHovered = ui.upgradeBoxUI(tree, upg, level, x,y, dontDraw)
            if (not dontDraw) and isHovered then
                hoveredUpgrade = upg
            end
            if wasJustHovered then
                g.playUISound("ui_tick", 1,1)
            end
            if (not self.dev_editMode) and wasJustClicked then
                g.playUISound("ui_click_satisfying", 0.8,0.7,0,0)
                tree:tryBuyUpgrade(upg)
                hoveredUpgrade=nil
            end
        end
    end

    if self.dev_editMode then
        local lw = lg.getLineWidth()
        local sel = self.dev_editModeSelection
        for gridX=-50, 50 do
            for gridY=-50, 50 do
                local x,y = getUpgradeGridCoords(gridX,gridY)
                local size2 = math.floor(consts.UPGRADE_IMAGE_SIZE/2) + consts.UPGRADE_GRID_SPACING/2
                if sel and sel.x==gridX and sel.y==gridY then
                    lg.setColor(1,1,0, math.sin(love.timer.getTime()*9)/2 + 1)
                    lg.setLineWidth(5)
                else
                    lg.setColor(1,1,1,0.4)
                    lg.setLineWidth(1)
                end
                lg.rectangle("line",x-size2,y-size2, size2*2,size2*2)
                if iml.wasJustClicked(x-size2,y-size2,size2*2,size2*2) then
                    if sel and sel.isAddingConnector then
                        -- create connector
                        local upg1 = tree:get(gridX,gridY)
                        local upg2 = tree:get(sel.x,sel.y)
                        if upg1 and upg2 then
                            tree:addConnection(upg1, upg2)
                        end
                        self.dev_editModeSelection = nil
                    else
                        -- select new:
                        self.dev_editModeSelection = {x=gridX,y=gridY}
                    end
                end
            end
        end
        lg.setLineWidth(lw)
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



local function drawDevEditModeUI(self)
    local region = Kirigami(0,0,ui.getScaledUIDimensions())
    local leftbar, sidebar = region:splitHorizontal(5,1)
    local _, bigSidebar = region:splitHorizontal(3,2)
    lg.setColor(1,1,1)
    lg.rectangle("line",sidebar:get())

    local regs = sidebar:grid(1,9)
    if ui.DefaultButton("Reset all", regs[1]) then
        -- resets all upgrades to level 0
        
    end

    local function calculateGrid(itemCount, regionWidth, regionHeight)
        local aspectRatio = regionWidth / regionHeight
        local cols = math.ceil(math.sqrt(itemCount * aspectRatio))
        local rows = math.ceil(itemCount / cols)
        return cols, rows
    end

    local tree = g.getUpgTree()
    local sel = self.dev_editModeSelection
    if sel then
        local selectArea,bot = bigSidebar:splitVertical(8,1)
        selectArea = selectArea:padUnit(4)
        lg.setColor(0,0,0,0.5)
        lg.rectangle("fill", selectArea:get())
        lg.setColor(1,1,1)

        local ww, hh = calculateGrid(#g.UPGRADE_LIST, selectArea.w, selectArea.h)
        for i, utype in ipairs(g.UPGRADE_LIST) do
            local col = (i - 1) % ww
            local row = math.floor((i - 1) / ww)
            local x = col * (selectArea.w / ww) + selectArea.x
            local y = row * (selectArea.h / hh) + selectArea.y
            local w = selectArea.w/ww
            local h = selectArea.h/hh
            
            local uinfo = g.getUpgradeInfo(utype)
            g.drawImageContained(uinfo.image, x,y,w,h)
            if iml.wasJustClicked(x,y,w,h) then
                -- put upgrade:
                if not tree:get(sel.x,sel.y) then
                    tree:put(sel.x, sel.y, uinfo)
                end
            end
        end

        local cancelButton, connectButton, deleteButton = bot:splitHorizontal(5,2,2)
        if ui.DefaultButton("Cancel", cancelButton) then
            self.dev_editModeSelection = nil
        end

        if ui.Button("DELETE", {0.9,0,0}, {0.6,0,0}, deleteButton) then
            tree:clear(sel.x,sel.y)
        end

        if ui.Button("CONNECT", {0.1,0.9,0.0}, {0.0,0.6,0.0}, connectButton) then
            sel.isAddingConnector = true
        end
    end

end


---@param self UpgradesScene
local function drawDevUI(self)
    local region = Kirigami(0,0,ui.getScaledUIDimensions())
    local header, body,_ = region:splitVertical(1,5)
    _,header = header:splitHorizontal(1,2,1)
    local editButton, revealButton = header:padRatio(0.2):splitHorizontal(1,1)
    local editTxt = self.dev_editMode and "ON" or "OFF"
    local revealTxt = self.dev_revealUpgrades and "ON" or "OFF"
    if ui.DefaultButton(("dev:Edit (%s)"):format(editTxt), editButton:padRatio(0.3)) then
        self.dev_editMode = not self.dev_editMode
    end
    if ui.DefaultButton(("dev:Reveal: (%s)"):format(revealTxt), revealButton:padRatio(0.3)) then
        self.dev_revealUpgrades = not self.dev_revealUpgrades
    end

    if self.dev_editMode then
        drawDevEditModeUI(self)
    end
end


function upgscene:draw()
    drawBackground()

    love.graphics.setColor(1,1,1)

    self:setCamera()
    local hoveredUpgrade = drawUpgradeBoxes(self)

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    self:renderMapButton()

    g.getHUD():draw({profile = false})

    if hoveredUpgrade then
        if not self.upgradeDescription or self.upgradeDescription:getUpgrade() ~= hoveredUpgrade then
            self.upgradeDescription = UpgradeDescription(g.getUpgTree(), hoveredUpgrade)
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

    if consts.DEV_MODE then
        drawDevUI(self)
    end

    ui.endUI()
end




function upgscene:update(dt)
    self:updateCamera(dt)
    g.getHUD():update(dt)
end


function upgscene:keypressed(k)
    local tree = g.getUpgTree()
    if k == "tab" then
        g.gotoSceneViaMap("harvest_scene")
    elseif consts.DEV_MODE then
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

        if k == "1" then
            local session = g.getSn()
            local oldTree = session.tree
            local upgradeLevels = {}
            -- Preserve upgrade levels
            for _, upg in ipairs(oldTree:getAllUpgrades()) do
                upgradeLevels[upg.id] = upg.level
            end

            session.tree = newDevTree()

            -- Restore upgrade levels
            for _, upg in ipairs(session.tree:getAllUpgrades()) do
                upg.level = upgradeLevels[upg.id] or 0
            end
        end
    end
end



upgscene.keyreleased = upgscene.defaultKeyreleased
upgscene.wheelmoved = upgscene.defaultWheelmoved
upgscene.mousemoved = upgscene.defaultMousemoved



return upgscene


