
local UpgradeDescription = require("src.ui.upgrades.upgrade_description_ui")
local Tree = require("src.upgrades.Tree")

local newDevTree = require("src.upgrades.dev_tree")
local procGen = require("src.upgrades.proc_gen")


local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")


---@class UpgradesScene: FreeCameraScene
local upgscene = FreeCameraScene()

local UNLOCKED_UPGRADE_ANIMATION_DURATION = 0.7

local _controlTextList = {
    loc("Click-Hold Background to Pan", nil, {context = "mouse controls on list of upgrades"}),
    loc("Hover on Upgrades to See More", nil, {context = "mouse controls about an upgrade"}),
    loc("Click on Upgrades to Buy", nil, {context = "mouse controls about an upgrade"}),
}
if not consts.IS_MOBILE then
    _controlTextList[#_controlTextList+1] = loc("Press Tab to move to Harvesting Area", nil, {
        context = "A hotkey (Tab) to move quickly between scenes"
    })
end
local CONTROL_TEXT = table.concat(_controlTextList, "\n")

local TUTORIAL_UPGRADES = "{w}{o thickness=2}"..loc("These are permanent {c r=0 g=1 b=0}upgrades{/c}.\nClick to buy!").."{/o}{/w}"
local TUTORIAL_UPGRADES_MOBILE = "{w}{o thickness=2}"..loc("These are permanent {c r=0 g=1 b=0}upgrades{/c}.\nTap once to view about the upgrade.\nTap again to buy!").."{/o}{/w}"




function upgscene:init()
    self.dev_editMode = false
    ---@type {x:number,y:number,isAddingConnector:boolean}?
    self.dev_editModeSelection = nil
    self.dev_showDistances = false
    self.dev_showUnusedUpgradesInSelect = true
    self.dev_showTokensInSelect = true
    self.dev_showPrices = false
    self.dev_maxLevelInput = ui.newTextBox()
    self.dev_priceInputs = {}
    for _, resId in ipairs(g.RESOURCE_LIST) do
        self.dev_priceInputs[resId] = ui.newTextBox()
    end

    ---@type ui.UpgradeDescription|nil
    self.upgradeDescription = nil

    ---@type [g.Tree.Upgrade?, number]
    self.lastUpgradeMaxxed = {nil, 0} -- {upgradeId, lifetime}

    ---@type iml.Drag|nil
    self.lmbPan = nil

    ---@type g.Tree.Upgrade|nil
    self.lastHoveredUpgrade = nil

    --
    self.touchZoomData = {
        ---@type lightuserdata?
        m1 = nil,
        ---@type lightuserdata?
        m2 = nil,
        m1x = 0, m1y = 0, m2x = 0, m2y = 0
    }
end



---@param x integer
---@param y integer
local function getUpgradeGridCoords(x, y)
    local spacing = consts.UPGRADE_GRID_SPACING + consts.UPGRADE_IMAGE_SIZE
    return math.floor((x + 0.5) * spacing), math.floor((y + 0.5) * spacing)
end

---@param upg g.Tree.Upgrade
---@param frame string
local function getUpgradeClickableArea(upg, frame)
    local x, y = getUpgradeGridCoords(upg.x, upg.y)
    local w, h = select(3, g.getImageQuad(frame):getViewport()) --[[@as number]]
    -- subtract by half the dimensions
    return x - w / 2, y - h / 2, w, h
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


local RAY_COLOR = objects.Color("#".."FFF2E46C")

---@param self UpgradesScene
local function drawUpgradeBoxes(self)
    --[[
    INTUITION VISUALS:

    - LOCKED: EVERY COLOR is gray, locked-icon

    - Hasnt been purchased: Icon is black!


    - Cant afford: Everything made slightly darker. Red-border.
    - Can afford:  Regular colors, Regular border. Occasionally shakes

    - SHOULD BUY:  Rapidly shakes, pulses in scale

    - Can afford + Hasnt-been-purchased:  Green Plus hovering in bottom-right

    - Token-Upgrade: transparent-ish background behind token-image
    - Misc-Upgrade: white-border
    ]]

    prof_push("drawUpgradeBoxes")

    local hoveredUpgrade = nil
    local tree = g.getUpgTree()
    local upgrades = tree:getUpgradesOnTree()
    local sn = g.getSn()

    ---@type table<g.Tree.Upgrade, boolean>
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

    ---@type table<g.Tree.Upgrade, boolean>
    local isNextToVisibleCache = {}
    for _, upg in ipairs(upgrades) do
        -- cache, (another expensive operation)
        -- MUST BE DONE 2-PASS, THATS WHY THERES 2 LOOPS.
        local neighs = tree:getNeighbors(upg.x,upg.y)
        for _, upg2 in ipairs(neighs) do
            if isVisible(upg2) then
                isNextToVisibleCache[upg] = true
                break
            end
        end
    end

    local function isNextToVisible(upg)
        return isNextToVisibleCache[upg] or isVisible(upg)
    end

    -- Draw connectors
    local toAnimate = objects.Set() -- contains the upgrade tree
    prof_push("drawConnectors")
    for _, upg in ipairs(upgrades) do
        -- Draw connector first
        for _, upg2 in ipairs(tree:getNeighbors(upg.x,upg.y)) do
            if isNextToVisible(upg2) and isNextToVisible(upg) then
                drawConnector(upg, upg2)

                if self.lastUpgradeMaxxed[2] > 0 and self.lastUpgradeMaxxed[1] == upg and upg2.level == 0 then
                    toAnimate:add(upg2)
                end
            end
        end
    end
    prof_pop() -- prof_push("drawConnectors")

    ---@type table<g.Tree.Upgrade, string?>
    local backgrounds = {}
    ---@type table<g.Tree.Upgrade, string>
    local frames = {}
    ---@type table<g.Tree.Upgrade, boolean>
    local canAffords = {}
    -- Determine bg, frame, blacked out, and input
    prof_push("processUpgrades")
    for _, upg in ipairs(upgrades) do
        local uinfo = g.getUpgradeInfo(upg.id)
        local maxLevel = tree:getUpgradeMaxLevel(upg)
        local isMaxLevel = upg.level >= maxLevel
        local canAfford = upg.level < maxLevel and tree:canAffordUpgrade(upg, upg.level+1)
        canAffords[upg] = canAfford

        if uinfo.kind == "TOKEN" then
            if canAfford then
                frames[upg] = "upgradeborder_token_golden"
            elseif isMaxLevel then
                frames[upg] = "upgradeborder_token"
            else
                frames[upg] = "upgradeborder_token_gray"
            end
        else
            if canAfford then
                backgrounds[upg] = "upgradebackground_golden"
                frames[upg] = "upgradeborder_golden"
            elseif isMaxLevel then
                backgrounds[upg] = "upgradebackground_upgrade"
                frames[upg] = "upgradeborder_upgrade"
            else
                backgrounds[upg] = "upgradebackground_gray"
                frames[upg] = "upgradeborder_cantafford"
            end
        end

        -- If not blacked out, process inputs
        if isVisible(upg) then
            local x, y, w, h = getUpgradeClickableArea(upg, frames[upg])

            if iml.isHovered(x, y, w, h) then
                hoveredUpgrade = upg
            end

            if iml.wasJustHovered(x, y, w, h) then
                g.playUISound("ui_tick", 1,1)
            end

            if (not self.dev_editMode) and iml.wasJustClicked(x, y, w, h) then
                g.playUISound("ui_click_satisfying", 0.8,0.7,0,0)

                local shouldTryBuy = consts.IS_MOBILE and self.lastHoveredUpgrade == upg or (not consts.IS_MOBILE)
                if shouldTryBuy and tree:tryBuyUpgrade(upg) and upg.level == maxLevel then
                    self.lastUpgradeMaxxed = {upg, UNLOCKED_UPGRADE_ANIMATION_DURATION}
                    sn.showTutorials.upgrades = false
                    g.playUISound("ui_upgrade_level_maxxed", 0.65,0.3,0.2,0.1)
                end

                self.lastHoveredUpgrade = hoveredUpgrade
                hoveredUpgrade = nil
            end
        end
    end
    prof_pop() -- prof_push("processUpgrades")


    -- Draw godrays
    lg.setColor(1, 1, 1)
    local time = love.timer.getTime()
    prof_push("drawGodrays")
    for _, upg in ipairs(upgrades) do
        if isVisible(upg) and canAffords[upg] then
            local x, y = getUpgradeGridCoords(upg.x, upg.y)
            local t = time % (2 * math.pi)
            local t2 = (time * 0.8 + 1) % (2 * math.pi)
            if upg.level == 0 then
                godrays.drawRays(x, y, t, {color = RAY_COLOR, rayCount = 6, startWidth = 2, length = 32, fadeTo=0.15})
                godrays.drawRays(x, y, -t2, {color = RAY_COLOR, rayCount = 4, startWidth = 2, length = 32, fadeTo=0.15})
            else
                godrays.drawRays(x, y, t, {color = RAY_COLOR, rayCount = 3, startWidth = 2, length = 25, fadeTo=0})
                godrays.drawRays(x, y, -t2, {color = RAY_COLOR, rayCount = 4, startWidth = 2, length = 25, fadeTo=0})
            end
            lg.setColor(1, 1, 1)
        end
    end
    prof_pop() -- prof_push("drawGodrays")


    -- Draw upgrade background and frame
    prof_push("drawUpgradeFrameBackground")
    for _, upg in ipairs(upgrades) do
        if isNextToVisible(upg) then
            local x, y = getUpgradeGridCoords(upg.x, upg.y)

            lg.setColor(1, 1, 1)
            if not isVisible(upg) then
                lg.setColor(0, 0, 0, 0.8)
            end

            if backgrounds[upg] then
                g.drawImage(backgrounds[upg], x, y)
            end

            g.drawImage(frames[upg], x, y)
        end
    end
    prof_pop() -- prof_push("drawUpgradeFrameBackground")


    -- Draw image/icon/custom shit
    prof_push("drawImageIconCustomShit")
    for _, upg in ipairs(upgrades) do
        if isVisible(upg) then
            local uinfo = g.getUpgradeInfo(upg.id)
            local cx, cy = getUpgradeGridCoords(upg.x, upg.y)
            lg.setColor((upg.level > 0 or self.dev_editMode) and objects.Color.WHITE or objects.Color.BLACK)

            if uinfo.kind == "TOKEN" then
                local tinfo = g.getTokenInfo(uinfo.tokenType)
                g.drawTokenImage(tinfo, cx, cy)
            elseif uinfo.image then
                g.drawImage(uinfo.image, cx, cy)
            end

            -- custom rendering:
            if uinfo.drawUI then
                uinfo:drawUI(upg.level, getUpgradeClickableArea(upg, frames[upg]))
            end
        end
    end
    prof_pop() -- prof_push("drawImageIconCustomShit")


    -- Draw level
    local levelFont = g.getBigFont(16)
    prof_push("drawUpgradeLevel")
    for _, upg in ipairs(upgrades) do
        if isVisible(upg) and upg.level > 0 then
            local maxLevel = tree:getUpgradeMaxLevel(upg)
            love.graphics.setColor(1, 1, 1)
            if upg.level >= maxLevel then
                love.graphics.setColor(0.1, 0.7, 0)
            end

            local x, y, w, h = getUpgradeClickableArea(upg, frames[upg])
            local txtDy = 0
            if upg.level < maxLevel then
                txtDy = math.sin(love.timer.getTime()*4) - 1
            end
            helper.printTextOutlineSimple(
                tostring(upg.level), levelFont, 1,
                math.floor(x + w * 3 / 4), math.floor(y + h / 2) + txtDy
            )
        end
    end
    prof_pop() -- prof_push("drawUpgradeLevel")


    -- Draw unlocked upgrade animation
    prof_push("drawTopAnimation")
    for _, upg in ipairs(upgrades) do
        if toAnimate:has(upg) then
            drawUnlockedUpgradeAnimation(upg, self.lastUpgradeMaxxed[2])
        end
    end
    prof_pop() -- prof_push("drawTopAnimation")

    prof_pop() -- prof_push("drawUpgradeBoxes")

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
                            if tree:areConnected(upg1, upg2) then
                                tree:removeConnection(upg1, upg2)
                            else
                                tree:addConnection(upg1, upg2)
                            end
                        end
                        self.dev_editModeSelection = nil
                    else
                        -- select new:
                        self.dev_editModeSelection = {x=gridX,y=gridY}
                        self.dev_maxLevelInput:reset()
                        for _, resId in ipairs(g.RESOURCE_LIST) do
                            self.dev_priceInputs[resId]:reset()
                        end
                    end
                end
                if iml.isHovered(xx,yy,ww,hh) then
                    local upg = tree:get(gridX,gridY)
                    if upg then
                        lg.setColor(1,1,1)
                        hoveredUpgrade = upg
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
    prof_push("drawBackground")

    -- draw background:
    love.graphics.clear(0.4,0.6,0.8)
    helper.gradientRect("vertical",
        objects.Color("#".."FF5B77DA"),
        objects.Color("#".."FF4228D5"),
        0,0,love.graphics.getDimensions()
    )
    local GAP = 150
    local rot = math.sin(3*love.timer.getTime() / 1.2) / 8
    lg.push()
    love.graphics.scale(ui.getUIScaling())
    local delta = 0--(love.timer.getTime() * 8) % GAP
    for x=-300, 3000, GAP do
        for y=-300, 2000, GAP do
            love.graphics.setColor(1,1,1,0.07)
            g.drawImage("upgrade_cat_background_symbol", x+delta,y+delta/3, rot, 1,1)
        end
    end
    lg.pop()

    prof_pop() -- prof_push("drawBackground")
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
---@param treeUpgrades g.Tree.Upgrade[]
local function drawDevEditModeUI(self, treeUpgrades)
    local region = ui.getScreenRegion()
    local leftbar, _, sidebar = region:splitHorizontal(1,4,1)
    local _, bigSidebar = region:splitHorizontal(3,2)
    lg.setColor(1,1,1)

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

    local exists = {}
    for _,upg in ipairs(treeUpgrades)do
        exists[upg.id] = true
    end

    local function shouldShow(upgId)
        if not self.dev_showTokensInSelect then
            local uinfo = g.getUpgradeInfo(upgId)
            if uinfo.tokenType then
                return false
            end
        end
        if self.dev_showUnusedUpgradesInSelect then
            return true
        end
        return not exists[upgId]
    end

    local sel = self.dev_editModeSelection
    if sel then
        local selectArea,bot = bigSidebar:splitVertical(8,2)
        selectArea = selectArea:padUnit(4)
        lg.setColor(0,0,0,0.5)
        lg.rectangle("fill", selectArea:get())
        lg.setColor(1,1,1)
        iml.panel(selectArea:get())

        local ww, hh = calculateGrid(#g.UPGRADE_LIST, selectArea.w, selectArea.h)
        local hovered = nil
        for i, utype in ipairs(g.UPGRADE_LIST) do
            if shouldShow(utype) then
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

                if iml.isHovered(x,y,w,h) then
                    hovered = uinfo
                end
            end
        end

        if hovered then
            local mx, my = iml.getTransformedPointer()
            local f = g.getSmallFont(16)
            local labelR = Kirigami(mx + 6, my + 6, richtext.getWidth(hovered.name, f), f:getHeight())
                :clampInside(ui.getScreenRegion())
            helper.printTextOutline(hovered.name, f, 1, labelR.x, labelR.y, labelR.w, "left")
        end

        local bot1, bot2 = bot:splitVertical(1,1)
        local makeRootButton, connectButton, deleteButton = bot2:splitHorizontal(1,1,1)
        local toggleUnused, toggleTokens, cancelButton = bot1:splitHorizontal(1,1,3)
    
        if ui.DefaultButton("Cancel", cancelButton) then
            self.dev_editModeSelection = nil
        end

        if ui.DefaultButton("Show unused?", toggleUnused) then
            self.dev_showUnusedUpgradesInSelect = not self.dev_showUnusedUpgradesInSelect
        end
        if ui.DefaultButton("Show tokens?", toggleTokens) then
            self.dev_showTokensInSelect = not self.dev_showTokensInSelect
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
            local font=g.getSmallFont(16)
            local topleft,leftbar1 = leftbar:splitVertical(2,5)
            local leftregs = leftbar1:grid(1,14)
            lg.setColor(0,0,0,0.4)
            lg.rectangle("fill", leftbar:get())
            lg.setColor(1,1,1)
            richtext.printRichContainedNoWrap("maxLevel", font, leftregs[1]:get())
            self.dev_maxLevelInput:draw(leftregs[2])

            local bundle = {}
            local hasPrice = false
            local idx = 4
            for _, resId in ipairs(g.RESOURCE_LIST) do
                richtext.printRichContainedNoWrap(resId, font, leftregs[idx]:get())
                idx = idx + 1
                self.dev_priceInputs[resId]:draw(leftregs[idx])
                idx = idx + 1
                local val = dev_fromFormattedNumber(self.dev_priceInputs[resId].txt)
                if val then
                    bundle[resId] = val
                    hasPrice = true
                end
            end
            if hasPrice then
                tree:setUpgradeBasePrice(upg, bundle)
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
    local region = ui.getScreenRegion()
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

    local treeUpgrades = tree:getUpgradesOnTree()
    local numUpgs = #treeUpgrades
    richtext.printRichContained("{o}Num Upgrades:" .. tostring(numUpgs) .. "/140", font, header:moveRatio(0.5,0.0):padRatio(0.6):get())

    if self.dev_editMode then
        drawDevEditModeUI(self, treeUpgrades)
    end
end


function upgscene:draw()
    lg.setColor(1,1,1)
    drawBackground()

    love.graphics.setColor(1,1,1)

    self:setCamera()
    do
        local x, y = self.camera:toWorld(0, 0) --[[@as number]]
        local x2, y2 = self.camera:toWorld(love.graphics.getDimensions())
        local w, h = x2 - x, y2 - y
        local drag = iml.consumeDrag("upgscene:viewport", x, y, w, h, 1)

        if #love.touch.getTouches() ~= 1 and consts.IS_MOBILE then
            drag = nil
        end

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
        local txt = consts.IS_MOBILE and TUTORIAL_UPGRADES_MOBILE or TUTORIAL_UPGRADES
        richtext.printRich(txt, g.getBigFont(32), tutTextR.x, tutTextR.y, tutTextR.w, "center")
    end

    if hoveredUpgrade then
        if not self.upgradeDescription or self.upgradeDescription:getUpgrade() ~= hoveredUpgrade then
            self.upgradeDescription = UpgradeDescription(g.getUpgTree(), hoveredUpgrade)
        end

        local r = ui.getScreenRegion()
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
        love.graphics.printf(CONTROL_TEXT, font, controlTextR.x, controlTextR.y, controlTextR.w, "left")
    end

    if consts.SHOW_DEV_STUFF then
        drawDevUI(self)
    end

    self:renderPause()

    ui.endUI()
end




function upgscene:update(dt)
    -- Have to do tracking manually because scene manager limitation with touches
    -- If we need this behavior on different scene, we should move this out to FreeCameraScene.
    local touches = love.touch.getTouches()
    if #touches >= 2 then
        self.allowMousePan = false

        if not self.touchZoomData.m1 then
            self.touchZoomData.m1 = touches[1]
            self.touchZoomData.m1x, self.touchZoomData.m1y = love.touch.getPosition(touches[1])
        end

        if not self.touchZoomData.m2 then
            self.touchZoomData.m2 = touches[2]
            self.touchZoomData.m2x, self.touchZoomData.m2y = love.touch.getPosition(touches[2])
        end

        local m1x, m1y, m2x, m2y = nil, nil, nil, nil
        for _, t in ipairs(touches) do
            if self.touchZoomData.m1 == t then
                m1x, m1y = love.touch.getPosition(touches[1])
            elseif self.touchZoomData.m2 == t then
                m2x, m2y = love.touch.getPosition(touches[2])
            end

            if m1x and m1y and m2x and m2y then
                break
            end
        end

        if m1x and m1y and m2x and m2y then
            local olddist = helper.magnitude(
                self.touchZoomData.m2x - self.touchZoomData.m1x,
                self.touchZoomData.m2y - self.touchZoomData.m1y
            )
            local newdist = helper.magnitude(m2x - m1x, m2y - m1y)
            local zoom = self._zoomIndex + (newdist - olddist) / 500
            self:setZoom(zoom)

            self.touchZoomData.m1x, self.touchZoomData.m1y = m1x, m1y
            self.touchZoomData.m2x, self.touchZoomData.m2y = m2x, m2y
        end
    else
        self.allowMousePan = true
        self.touchZoomData.m1, self.touchZoomData.m2 = nil, nil
    end

    self:updateCamera(dt)
    g.getHUD():update(dt)
    g.requestBGM(g.BGMID.UPGRADE)
    self.lastUpgradeMaxxed[2] = math.max(self.lastUpgradeMaxxed[2] - dt, 0)

    local w = g.getMainWorld()
    w:_disableMouseHarvester()
end


---@param k love.KeyConstant
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

        if k == "z" and self.dev_editMode then
            local sel = self.dev_editModeSelection
            if sel then
                local upg = tree:get(sel.x,sel.y)
                -- zero everything.
                tree:setUpgradeBasePrice(upg, {money=0})
                tree:setUpgradeLevel(upg, 0)
                upg.maxLevelOverride = 0
            end
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

        if love.keyboard.isDown("lshift") and k == "2" then
            local oldFilename = g.getSn().tree._filename
            g.getSn().tree = procGen.generateTestTree()
            g.getSn().tree._filename = oldFilename
        end

        if love.keyboard.isDown("lshift") and k == "t" then
            local oldFilename = g.getSn().tree._filename
            g.getSn().tree = g.getSn().tree:transpose(true,true)
            g.getSn().tree._filename = oldFilename
        end

        if self.dev_editModeSelection then
            local sel = assert(self.dev_editModeSelection)
            local dx, dy = 0, 0
            if k == "left" then
                dx = -1
            elseif k == "right" then
                dx = 1
            elseif k == "up" then
                dy = -1
            elseif k == "down" then
                dy = 1
            end

            if dx ~= 0 or dy ~= 0 then
                local upg = tree:get(sel.x, sel.y)
                local nx, ny = sel.x + dx, sel.y + dy
                if upg then
                    if tree:move(upg, nx, ny) then
                        self.dev_editModeSelection = {x = nx, y = ny, isAddingConnector = sel.isAddingConnector}
                    end
                else
                    -- If no upgrade, just move the selection cursor
                    self.dev_editModeSelection = {x = nx, y = ny, isAddingConnector = sel.isAddingConnector}
                end
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

function upgscene:keyreleased(k)
    if consts.DEV_MODE and k == "f12" then
        local tree = g.getSn().tree

        for _, upg in ipairs(tree:getUpgradesOnTree()) do
            upg.level = tree:getUpgradeMaxLevel(upg)
        end
    end
end

function upgscene:textinput()
    self.upgradeDescription = nil
end

upgscene.wheelmoved = upgscene.defaultWheelmoved
upgscene.mousemoved = upgscene.defaultMousemoved



return upgscene


