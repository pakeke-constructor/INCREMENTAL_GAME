
local UpgradeDescription = require("src.ui.upgrades.upgrade_description_ui")
local Tree = require("src.upgrades.Tree")

local newDevTree = require("src.upgrades.dev_tree")


local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")


---@class UpgradesScene: FreeCameraScene
local upgscene = FreeCameraScene()

local UNLOCKED_UPGRADE_ANIMATION_DURATION = 0.7

local CONTROL_TEXT = table.concat({
    loc("Click-Hold Background to Pan", nil, {context = "mouse controls on list of upgrades"}),
    loc("Hover on Upgrades to See More", nil, {context = "mouse controls about an upgrade"}),
    loc("Click on Upgrades to Buy", nil, {context = "mouse controls about an upgrade"}),
}, "\n")

local TUTORIAL_UPGRADES = "{w}{o thickness=2}"..loc("These are permanent {c r=0 g=1 b=0}upgrades{/c}.\nClick to buy!").."{/o}{/w}"




function upgscene:init()
    self.dev_editMode = false
    ---@type {x:number,y:number,isAddingConnector:boolean}?
    self.dev_editModeSelection = nil
    self.dev_showDistances = false
    self.dev_showPrices = false
    self.dev_maxLevelInput = ui.newTextBox()
    self.dev_priceInput = ui.newTextBox()

    ---@type ui.UpgradeDescription|nil
    self.upgradeDescription = nil

    ---@type [g.Tree.Upgrade?, number]
    self.lastUpgradeMaxxed = {nil, 0} -- {upgradeId, lifetime}

    ---@type iml.Drag|nil
    self.lmbPan = nil
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

        if (not tree:isUpgradeHidden(upg)) and (lv < tree:getUpgradeMaxLevel(upg)) then
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


local NEW_UPGRADE_RAY_COLOR = objects.Color("#".."ff0ac6fa")

---@param upg g.Tree.Upgrade
---@param lifetime number
local function drawUnlockedUpgradeAnimation(upg, lifetime)
    local t = 1 - (lifetime / UNLOCKED_UPGRADE_ANIMATION_DURATION)
    local time = love.timer.getTime() - 100
    local x, y = getUpgradeGridCoords(upg.x, upg.y)

    local r = time % (2 * math.pi)
    local r2 = (time * 0.8 + 1) % (2 * math.pi)
    local size = (t ^ 0.6 * (1 - t)) * 200
    local width = (lifetime/UNLOCKED_UPGRADE_ANIMATION_DURATION)*6
    godrays.drawRays(x, y, r, {color = NEW_UPGRADE_RAY_COLOR, rayCount = 6, startWidth = width+1, length = size, fadeTo=0})
    godrays.drawRays(x, y, -r2, {color = NEW_UPGRADE_RAY_COLOR, rayCount = 4, startWidth = width, length = size, fadeTo=0})
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

    local isHiddenCache = {}
    for _, upg in ipairs(upgrades) do
        -- cache it, because :isUpgradeHidden is kinda an expensive operation
        isHiddenCache[upg] = tree:isUpgradeHidden(upg)
    end
    ---@param upg g.Tree.Upgrade
    ---@return boolean
    local function isVisible(upg)
        local forceVisibility = (consts.DEV_MODE and self.dev_editMode)
        local hidden = isHiddenCache[upg]
        return forceVisibility or (not hidden)
    end

    local toAnimate = objects.Set() -- contains the upgrade tree
    for _, upg in ipairs(upgrades) do
        if isVisible(upg) then
            -- Draw connector first
            for _, upg2 in ipairs(tree:getNeighbors(upg.x,upg.y)) do
                if isVisible(upg2) then
                    drawConnector(upg, upg2)

                    if self.lastUpgradeMaxxed[2] > 0 and self.lastUpgradeMaxxed[1] == upg and upg2.level == 0 then
                        toAnimate:add(upg2)
                    end
                end
            end
        end
    end

    local sn = g.getSn()
    for _, upg in ipairs(upgrades) do
        if isVisible(upg) then
            local level = upg.level

            -- Then draw upgrade box
            local price = tree:getUpgradePrice(upg)
            local x, y = getUpgradeGridCoords(upg.x, upg.y)

            local dontDraw = false -- and g.getBundleCostRatio(price) < 0.2
            -- Removed this ^^^^ system, coz its bad.

            local isHovered, wasJustClicked, wasJustHovered = ui.upgradeBoxUI(tree, upg, level, x,y, dontDraw)
            if (not dontDraw) then
                if isHovered then
                    hoveredUpgrade = upg
                end

                if toAnimate:has(upg) then
                    drawUnlockedUpgradeAnimation(upg, self.lastUpgradeMaxxed[2])
                end
            end
            if wasJustHovered then
                g.playUISound("ui_tick", 1,1)
            end
            if (not self.dev_editMode) and wasJustClicked then
                g.playUISound("ui_click_satisfying", 0.8,0.7,0,0)
                local maxLevel = tree:getUpgradeMaxLevel(upg)
                if tree:tryBuyUpgrade(upg) and upg.level == maxLevel then
                    self.lastUpgradeMaxxed = {upg, UNLOCKED_UPGRADE_ANIMATION_DURATION}
                    sn.showTutorials.upgrades = false
                end
                hoveredUpgrade=nil
            end

            if self.dev_showDistances then
                local dist = tree:distanceFromRoot(upg)
                lg.setColor(1,1,1)
                richtext.printRichContained("{o}" .. tostring(dist), g.getSmallFont(16), x-15,y-15, 30,30)
            end
            if self.dev_showPrices then
                local num = tree:getUpgradePrice(upg, 0).money
                local basePrice = num and g.formatNumber(num) or 0
                lg.setColor(1,1,1)
                richtext.printRichContained("{o}{c r=0.9 g=0.6 b=0.3}$" .. tostring(basePrice), g.getSmallFont(16), x-10,y, 20,20)
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
                local xx,yy,ww,hh = x-size2,y-size2, size2*2,size2*2
                lg.rectangle("line",xx,yy,ww,hh)
                if iml.wasJustClicked(xx,yy,ww,hh) then
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
                        self.dev_maxLevelInput:reset()
                        self.dev_priceInput:reset()
                    end
                end
                if iml.isHovered(xx,yy,ww,hh) then
                    local upg = tree:get(gridX,gridY)
                    if upg then
                        lg.setColor(1,1,1)
                        local desc = UpgradeDescription(tree, upg)
                        desc:draw(xx,yy)
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
function drawBackground()
    -- draw background:
    love.graphics.clear(0.4,0.6,0.8)
    helper.gradientRect("vertical",
        objects.Color("#".."FF6B8BEB"),
        objects.Color("#".."FF5339E9"),
        0,0,love.graphics.getDimensions()
    )
    local GAP = 150
    local rot = math.sin(3*love.timer.getTime() / 3.5) / 12
    love.graphics.scale(ui.getUIScaling())
    local delta = 0--(love.timer.getTime() * 8) % GAP
    for x=-300, 3000, GAP do
        for y=-300, 2000, GAP do
            love.graphics.setColor(1,1,1,0.07)
            g.drawImage("upgrade_cat_background_symbol", x+delta,y+delta/3, rot, 1,1)
        end
    end
end

end


---@param str string
---@return number?
local function dev_fromFormattedNumber(str)
    if str == "" then
        return nil -- fail
    end
    local last = str:sub(-1,-1)
    if last:find("%.") then
        return nil -- no decimals
    end
    local mult = 1
    if last == "k" then mult = 1000 end
    if last == "m" then mult = 1000000 end
    local num = str
    if not num:match("%d$") then
        num = str:sub(1,-2) -- last digit isnt number!
    end
    if tonumber(num) then
        return tonumber(num) * mult
    end
    return nil -- failed
end


---@param self UpgradesScene
local function drawDevEditModeUI(self)
    local region = Kirigami(0,0,ui.getScaledUIDimensions())
    local leftbar, _, sidebar = region:splitHorizontal(1,4,1)
    local _, bigSidebar = region:splitHorizontal(3,2)
    lg.setColor(1,1,1)
    lg.rectangle("line",sidebar:get())

    local regs = sidebar:grid(1,9)

    local on_or_off = self.dev_showDistances and "(ON)" or "(OFF)"
    if ui.Button("Distances " .. on_or_off, objects.Color.GRAY, objects.Color.BLACK, regs[1]) then
        self.dev_showDistances = not self.dev_showDistances
    end

    on_or_off = self.dev_showPrices and "(ON)" or "(OFF)"
    if ui.Button("Prices " .. on_or_off, objects.Color.GRAY, objects.Color.BLACK, regs[2]) then
        self.dev_showPrices = not self.dev_showPrices
    end

    local tree = g.getUpgTree()
    if ui.DefaultButton("Reset levels", regs[3]) then
        -- resets all upgrades to level 0
        for _, upg in ipairs(tree:getAllUpgrades()) do
            upg.level = 0
        end
        tree.unboundUpgrades = {}
        tree:finalize()
    end

    local treeURL = "file://" .. (love.filesystem.getSaveDirectory() .. consts.FILE_SEP .. consts.DEV_UPGRADE_TREE_PATH)
    if ui.DefaultButton("Open Folder", regs[4]) then
        love.filesystem.createDirectory(consts.DEV_UPGRADE_TREE_PATH)
        love.system.openURL(treeURL)
    end

    if ui.Button("NEW TREE", objects.Color.LIME, objects.Color.DARK_GREEN, regs[5]) then
        love.filesystem.createDirectory(consts.DEV_UPGRADE_TREE_PATH)
        for i=1,100 do
            local fname = "NEW_TREE_"..i..".json"
            local fpath = consts.DEV_UPGRADE_TREE_PATH..consts.FILE_SEP..fname
            if not love.filesystem.getInfo(fpath) then
                local ok,er = love.filesystem.write(fpath, "{}")
                log.debug("writing file:",ok,er)
                love.system.openURL(treeURL)
                local sn = g.getSn()
                sn.tree = Tree()
                sn.tree._filename = fname
                break
            end
        end
    end

    if tree._filename and ui.Button("SAVE TREE", objects.Color.AQUA,objects.Color.BLACK, regs[6]) then
        local fname = consts.DEV_UPGRADE_TREE_PATH..consts.FILE_SEP..tree._filename
        love.filesystem.write(fname, json.encode(g.getUpgTree():serialize()))
    end

    local function calculateGrid(itemCount, regionWidth, regionHeight)
        local aspectRatio = regionWidth / regionHeight
        local cols = math.ceil(math.sqrt(itemCount * aspectRatio))
        local rows = math.ceil(itemCount / cols)
        return cols, rows
    end

    local sel = self.dev_editModeSelection
    if sel then
        local selectArea,bot = bigSidebar:splitVertical(8,2)
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

            -- draw upgr icon:
            local uinfo = g.getUpgradeInfo(utype)
            g.drawImageContained(uinfo.image, x,y,w,h)
            if uinfo.tokenType then
                local tinfo = g.getTokenInfo(uinfo.tokenType)
                if tinfo.growths then
                    g.drawImageContained(tinfo.growths.growth, Kirigami(x,y,w,h):padRatio(0.7):get())
                end
            end
            if uinfo.drawUI then
                uinfo:drawUI(1, x,y,w,h)
            end

            if iml.wasJustClicked(x,y,w,h) then
                -- put upgrade:
                if not tree:get(sel.x,sel.y) then
                    tree:put(sel.x, sel.y, uinfo)
                end
            end
        end

        local cancelButton, bot2 = bot:splitVertical(1,1)
        local makeRootButton, connectButton, deleteButton = bot2:splitHorizontal(1,1,1)
        if ui.DefaultButton("Cancel", cancelButton) then
            self.dev_editModeSelection = nil
        end

        if ui.Button("DELETE", {0.9,0,0}, {0.6,0,0}, deleteButton) then
            tree:clear(sel.x,sel.y)
        end

        if ui.Button("CONNECT", {0.1,0.9,0.0}, {0.0,0.6,0.0}, connectButton) then
            local upg = tree:get(sel.x,sel.y)
            if upg then
                sel.isAddingConnector = true
            end
        end

        local upg = tree:get(sel.x,sel.y)
        local txt = upg and ("ROOT" .. (upg.isRoot and "(currently ON)" or "(currently OFF)"))
        if upg and ui.Button(txt, objects.Color.DARK_GRAY,objects.Color.BLACK, makeRootButton) then
            if upg then
                upg.isRoot=not upg.isRoot
            end
        end

        -- LEFT SIDEBAR:
        if upg then
            local _,leftbar1 = leftbar:splitVertical(2,5)
            local leftregs = leftbar1:grid(1,10)
            lg.setColor(0,0,0,0.4)
            lg.rectangle("fill", leftbar:get())
            lg.setColor(1,1,1)
            local font=g.getSmallFont(16)
            richtext.printRichContainedNoWrap("maxLevel", font, leftregs[1]:get())
            self.dev_maxLevelInput:draw(leftregs[2])

            richtext.printRichContainedNoWrap("price", font, leftregs[4]:get())
            self.dev_priceInput:draw(leftregs[5])
            local price = dev_fromFormattedNumber(self.dev_priceInput.txt)
            if price then
                -- TODO: handle other currencies here.
                tree:setUpgradeBasePrice(upg, {
                    money = price
                })
            end

            local maxLevel = dev_fromFormattedNumber(self.dev_maxLevelInput.txt)
            if maxLevel then
                upg.maxLevelOverride = maxLevel
            end
        end
    end

end


---@param self UpgradesScene
local function drawDevUI(self)
    local region = Kirigami(0,0,ui.getScaledUIDimensions())
    local header, body,editname = region:splitVertical(2,9,1)
    local _
    _,header,_ = header:splitHorizontal(1,2,1)
    local _, editButton, _ = header:padRatio(0.2):splitHorizontal(1,1,1)
    local editTxt = self.dev_editMode and "ON" or "OFF"
    if ui.DefaultButton(("Edit (%s)"):format(editTxt), editButton:padRatio(0.3)) then
        self.dev_editMode = not self.dev_editMode
    end
    local tree = g.getUpgTree()
    local font=g.getSmallFont(16)
    if tree and tree._filename then
        richtext.printRichContained("{o}EDITING: {c r=1 g=1 b=0}" .. tree._filename, font, editname:padRatio(-0.2):get())
    elseif not tree._filename then
        richtext.printRichContained("{o}{c r=1 g=0 b=0}No file open.{/c}\n(Drag file onto screen to open)", font,
            editname:padRatio(-0.5):moveRatio(0,-0.5):get()
        )
    end

    if self.dev_editMode then
        drawDevEditModeUI(self)
    end
end


function upgscene:draw()
    drawBackground()

    love.graphics.setColor(1,1,1)

    self:setCamera()
    do
        local x, y = self.camera:toWorld(0, 0) --[[@as number]]
        local x2, y2 = self.camera:toWorld(love.graphics.getDimensions())
        local w, h = x2 - x, y2 - y
        local drag = iml.consumeDrag("upgscene:viewport", x, y, w, h, 1)

        if drag then
            local dx, dy = 0, 0
            if self.lmbPan then
                dx = self.lmbPan.dx - drag.dx
                dy = self.lmbPan.dy - drag.dy
            end

            local px, py = self.camera:getPos()
            self.camera:setPos(px + dx, py + dy)
        end

        self.lmbPan = drag
    end

    local hoveredUpgrade = drawUpgradeBoxes(self)

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    self:renderMapButton()

    g.getHUD():draw({profile = false})

    -- Draw tutorial text if needed
    if g.getSn().showTutorials.upgrades and (not consts.DEV_MODE) then
        local safeArea = g.getHUD():getSafeArea()
        local tutTextR = safeArea:padRatio(0.1)
        richtext.printRich(TUTORIAL_UPGRADES, g.getBigFont(32), tutTextR.x, tutTextR.y, tutTextR.w, "center")
    end

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

    -- Draw control tooltip
    do
        local font = g.getSmallFont(16)
        local safeAreaR = g.getHUD():getSafeArea()
        local nl = 1 + select(2, CONTROL_TEXT:gsub("\n", ""))
        local controlTextR = safeAreaR:set(nil, nil, nil, font:getHeight() * (1 + nl))
            :attachToBottomOf(safeAreaR)
            :moveRatio(0, -1)
            :moveUnit(2, 10)
        love.graphics.setColor(1, 1, 1, 0.5)
        richtext.printRich(CONTROL_TEXT, font, controlTextR.x, controlTextR.y, controlTextR.w, "left")
    end

    if consts.DEV_MODE then
        drawDevUI(self)
    end

    self:renderPause()

    ui.endUI()
end




function upgscene:update(dt)
    self:updateCamera(dt)
    g.getHUD():update(dt)
    self.lastUpgradeMaxxed[2] = math.max(self.lastUpgradeMaxxed[2] - dt, 0)
end


function upgscene:keypressed(k)
    local tree = g.getUpgTree()
    if k == "tab" then
        g.gotoSceneViaMap("harvest_scene")
    elseif k == "escape" then
        local s = g.getSn()
        s.paused = not s.paused
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

        if love.keyboard.isDown("lshift") and k == "1" then
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



---@param file love.File
function upgscene:filedropped(file)
    if consts.DEV_MODE then
        file:open("r")
        local data = json.decode(file:read())
        local tree
        if next(data) then
            -- it has data! deserialize tree
            tree = Tree.deserialize(data)
        else
            tree = Tree()
        end
        local path = file:getFilename()
        tree._filename = path:match("([^/\\]+)$")
        local sn = g.getSn()
        sn.tree = tree
    end
end

upgscene.keyreleased = upgscene.defaultKeyreleased
upgscene.wheelmoved = upgscene.defaultWheelmoved
upgscene.mousemoved = upgscene.defaultMousemoved



return upgscene


