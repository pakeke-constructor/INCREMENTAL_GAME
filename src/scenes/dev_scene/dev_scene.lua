local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")

---@class DevScene: FreeCameraScene
local dev = FreeCameraScene()

function dev:init()
end



---@param font love.Font
---@param width number
---@param text string
local function regionFromText(font, width, text)
    local maxwidth, lines = font:getWrap(richtext.stripEffects(text), width)
    return Kirigami(0, 0, maxwidth, #lines * font:getHeight())
end


---------------------
-- Resource Mod scene
---------------------

---@param r layout.Region
---@param resId string
local function drawResourceType(r, resId)
    local b1, b2, b3, b4 = r:splitVertical(1, 1, 1, 1)
    local limit = g.getResourceLimit(resId)

    if ui.Button("MAX "..resId, b1:padUnit(4):get()) then
        g.addResource(resId, limit)
    end
    if ui.Button("+10% "..resId, b2:padUnit(4):get()) then
        g.addResource(resId, math.floor(limit/10+0.5))
    end
    if ui.Button("-10% ".. resId, b3:padUnit(4):get()) then
        g.addResource(resId, -math.floor(limit/10+0.5))
    end
    if ui.Button("ZERO "..resId, b4:padUnit(4):get()) then
        g.addResource(resId, -limit)
    end
end

---@param r layout.Region
local function drawResourceSceneUI(r)
    local grid = r:padRatio(0.05):grid(#g.RESOURCE_LIST, 1)

    for i, resId in ipairs(g.RESOURCE_LIST) do
        drawResourceType(grid[i], resId)
    end
end


----------------
-- Harvest scene
----------------

---@param dt number
local function updateHarvestScene(dt)
    local world = g.getMainWorld()
    world:_update(dt)
end

local function drawHarvestScene()
    local world = g.getMainWorld()
    world:_draw()
end

local harvestTokenSpawnText = table.concat({
    "Token Spawner",
    "[Up Arrow] = Select Above",
    "%d. %s",
    "> {wavy}%d. %s{/wavy} <",
    "%d. %s",
    "[Down Arrow] = Select Below",
    "[T | MB4] = Spawn @ Mouse Pos"
}, "\n")

local selectedTokenIndex = 1

---@param r layout.Region
local function drawHarvestSceneUI(r)
    local font = g.getSmallFont(16)
    local tokenPrev = (selectedTokenIndex - 2) % #g.TOKEN_LIST + 1
    local tokenNext = selectedTokenIndex % #g.TOKEN_LIST + 1
    local fmt = string.format(
        harvestTokenSpawnText,
        tokenPrev, g.TOKEN_LIST[tokenPrev],
        selectedTokenIndex, g.TOKEN_LIST[selectedTokenIndex],
        tokenNext, g.TOKEN_LIST[tokenNext]
    )
    local finalText = "{o}"..fmt.."{/o}"
    local textR = regionFromText(font, 500, finalText)
        :attachToBottomOf(r)
        :attachToRightOf(r)
        :moveRatio(-1, -1)
        :moveUnit(-4, -4)
    richtext.printRich(finalText, font, textR.x, textR.y, textR.w, "left")
end


----------------
-- Upgrade scene
----------------

if consts.DEV_MODE and not love.filesystem.isFused() then
    local srcdir = love.filesystem.getSource().."/src"
    assert(love.filesystem.mountFullPath(srcdir, "root/src", "readwrite", true))
end

---@class _dev.UpgradePosition
---@field public type string
---@field public x integer
---@field public y integer

---@param prestige integer
---@return _dev.UpgradePosition[], boolean
local function loadUpgradeList(prestige)
    local path = "src/upgrades/prestige_"..prestige..".json"
    if love.filesystem.getInfo(path, "file") then
        return json.decode((assert(love.filesystem.read(path)))), true
    end
    return {}, false
end

---@return _dev.UpgradePosition[][], table<integer, string>
local function loadAllUpgrades()
    local prestige = 0
    local output = {}
    local hashmap = {}
    while true do
        local r, continue = loadUpgradeList(prestige)

        output[#output+1] = r

        for _, upos in ipairs(r) do
            hashmap[g.hashPos(upos.x, upos.y, prestige)] = upos.type
        end

        if not continue then
            break
        end

        prestige = prestige + 1
    end

    return output, hashmap
end

local upgradePosList, upgradeHashmap = loadAllUpgrades()
local isUpgradeDataModified = false
local currentPrestige = 0
---@type {pos:_dev.UpgradePosition,info:g.UpgradeInfo}|nil
local lastUpgradeHovered = nil
---@type {pos:_dev.UpgradePosition,info:g.UpgradeInfo}|nil
local lastUpgradeSelected = nil

local function saveUpgradePositions()
    -- We gotta be careful with the saving as it may be [{stuff}, {}, {}, {stuff}, {}]
    local maxIndicesToSave = 0
    for i, ulist in ipairs(upgradePosList) do
        if #ulist > 0 then
            maxIndicesToSave = i
        end
    end

    for i = 1, maxIndicesToSave do
        -- "root" is our game source directory but RW.
        -- i - 1 because prestige starts at 0
        love.filesystem.write("root/src/upgrades/prestige_"..(i - 1)..".json", json.encode(upgradePosList[i]))
    end

    for i = maxIndicesToSave + 1, #upgradePosList do
        -- Delete empty prestiges
        love.filesystem.remove("root/src/upgrades/prestige_"..(i - 1)..".json")
    end

    -- Reload
    lastUpgradeHovered = nil
    lastUpgradeSelected = nil
    upgradePosList, upgradeHashmap = loadAllUpgrades()
    isUpgradeDataModified = false
end

---@param x integer
---@param y integer
local function getUpgradeCoords(x, y)
    local size = consts.UPGRADE_IMAGE_SIZE
    local spacing = consts.UPGRADE_GRID_SPACING + size
    return x * spacing, y * spacing, size
end

local BELOW_PRESTIGE_COLOR = objects.Color("#".."FFE5DA01")
local ABOVE_PRESTIGE_COLOR = objects.Color("#".."FFddb0eb")

local function drawUpgradeScene()
    lastUpgradeHovered = nil

    -- Draw upgrade positions below current prestige
    if currentPrestige > 0 then
        love.graphics.setColor(BELOW_PRESTIGE_COLOR)

        for _, upos in ipairs(upgradePosList[currentPrestige]) do
            local x, y, sz = getUpgradeCoords(upos.x, upos.y)
            love.graphics.rectangle("line", x, y, sz, sz)
        end
    end

    -- Draw upgrades on current prestige
    love.graphics.setColor(1, 1, 1)
    for _, upos in ipairs(upgradePosList[currentPrestige + 1]) do
        local uinfo = g.getUpgradeInfo(upos.type)
        local x, y, sz = getUpgradeCoords(upos.x, upos.y)
        local highlight = not not (lastUpgradeSelected and lastUpgradeSelected.pos == upos)
        local isHovered, wasClicked = ui.upgradeBoxUI(uinfo, 1, x, y, sz, sz, highlight)

        if isHovered then
            lastUpgradeHovered = {pos = upos, info = uinfo}
        end
        if wasClicked then
            lastUpgradeSelected = {pos = upos, info = uinfo}
        end
    end

    -- Draw upgrade positions above current prestige
    if upgradePosList[currentPrestige + 2] then
        love.graphics.setColor(ABOVE_PRESTIGE_COLOR)

        for _, upos in ipairs(upgradePosList[currentPrestige + 2]) do
            local x, y, sz = getUpgradeCoords(upos.x, upos.y)
            love.graphics.rectangle("line", x, y, sz, sz)
        end
    end
end

---@param utype string
---@param x integer
---@param y integer
local function spawnUpgrade(utype, x, y)
    -- Search in + pattern
    local r = 1
    local tx, ty = x, y
    if upgradeHashmap[g.hashPos(tx, ty, currentPrestige)] then
        while true do
            if not upgradeHashmap[g.hashPos(x + r, y, currentPrestige)] then
                tx = x + r
                break
            end
            if not upgradeHashmap[g.hashPos(x - r, y, currentPrestige)] then
                tx = x - r
                break
            end
            if not upgradeHashmap[g.hashPos(x, y + r, currentPrestige)] then
                ty = y + r
                break
            end
            if not upgradeHashmap[g.hashPos(x, y - r, currentPrestige)] then
                ty = y - r
                break
            end
            r = r + 1
        end
    end

    ---@type _dev.UpgradePosition
    local upos = {type = utype, x = tx, y = ty}
    upgradeHashmap[g.hashPos(tx, ty, currentPrestige)] = utype
    table.insert(upgradePosList[currentPrestige + 1], upos)
    lastUpgradeSelected = {pos = upos, info = g.getUpgradeInfo(utype)}
    isUpgradeDataModified = true
end

---@type string[]|nil
local typedUpgradeId = nil -- if nil, disable text input

---@param col objects.Color
---@param text string
local function colorRichText(col, text)
    local r, g, b = col:getRGBA()
    return string.format("{c r=%.02f g=%.02f b=%.02f}", r, g, b)..text.."{/c}"
end

local upgradePrestigeChangerText = "{o}"..table.concat({
    "Color Legend:",
    colorRichText(g.COLORS.RECOMMENDED, "(Blinking) Selected Upgrade"),
    colorRichText(BELOW_PRESTIGE_COLOR, "Upgrade Below Prestige Level"),
    colorRichText(ABOVE_PRESTIGE_COLOR, "Upgrade Above Prestige Level"),
    "",
    "[/] = Open Upgrade Spawner",
    "[Ctrl+S] = Save Upgrade Pos%s", -- (the %s is if it's modified)
    "",
    "Prestige: %d",
    "[T] = Increase Prestige",
    "[G] = Decrease Prestige"
}, "\n").."{/o}"

local selectedUpgradeText = "{o}"..table.concat({
    -- string.format("%s (%s)", lastUpgradeSelected.info.name, lastUpgradeSelected.info.type),
    -- string.format("X: %d | Y: %d", lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y),
    "%s (%s)",
    "X: %d | Y: %d",
    "[Esc|Enter] = Deselect",
    "[Arrow Keys] = Move",
    "[Delete] = Delete",
    "[T] = Increase Prestige",
    "[G] = Decrease Prestige"
}, "\n").."{/o}"

---@param r layout.Region
---@param cam Camera
local function drawUpgradeSceneUI(r, cam)
    local font = g.getSmallFont(16)
    love.graphics.setColor(1, 1, 1)

    if lastUpgradeSelected then
        local w = g.getMainWorld()
        -- Just simple text will do
        local text = string.format(
            selectedUpgradeText,
            lastUpgradeSelected.info.name,
            lastUpgradeSelected.info.type,
            lastUpgradeSelected.pos.x,
            lastUpgradeSelected.pos.y
        )
        local x, y = getUpgradeCoords(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y)
        local mx, my = ui.getUIScalingTransform():inverseTransformPoint(cam:toScreen(x + 14, y + 14))
        richtext.printRich(text, font, mx, my, 20000, "left")
    end

    if lastUpgradeHovered then
        -- Just simple text will do
        local text = "{o}"..table.concat({
            string.format("%s (%s)", lastUpgradeHovered.info.name, lastUpgradeHovered.info.type),
            string.format("X: %d | Y: %d", lastUpgradeHovered.pos.x, lastUpgradeHovered.pos.y),
        }, "\n").."{/o}"
        local mx, my = ui.getMouse()

        richtext.printRich(text, font, mx + 14, my - 10, 20000, "left")
    end

    if typedUpgradeId then
        local char = iml.consumeText()
        if char and #char > 0 then
            typedUpgradeId[#typedUpgradeId+1] = char
        end

        local query = table.concat(typedUpgradeId)
        local queryLower = query:lower()
        local candidates = {}

        if #query > 0 then
            for _, utype in ipairs(g.UPGRADE_LIST) do
                local uinfo = g.getUpgradeInfo(utype)

                if utype:lower():find(queryLower, 1, true) or uinfo.name:lower():find(queryLower) then
                    candidates[#candidates+1] = utype
                end
            end
        end

        local grid = r:padUnit(8, 8)
            :set(nil, nil, nil, 24 * 17)
            :grid(1, 17)

        -- Draw typed text
        local gtext = grid[1]:padUnit(0, 2)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", gtext:get())
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(query, font, gtext.x + 2, gtext.y + 2)

        -- Draw buttons
        for i = 1, 16 do
            local utype = candidates[i]
            if not utype then
                break
            end

            local uinfo = g.getUpgradeInfo(utype)
            local gcur = grid[i + 1]:padUnit(0, 2)

            if iml.isHovered(gcur:get()) then
                love.graphics.setColor(0.9, 0.9, 0.9)
            else
                love.graphics.setColor(1, 1, 1)
            end
            love.graphics.rectangle("fill", gcur:get())
            love.graphics.setColor(0, 0, 0)
            richtext.printRich(uinfo.name, font, gcur.x + 2, gcur.y + 2, gcur.w - 4, "left")
            if iml.wasJustClicked(gcur:get()) then
                local wx, wy = cam:getPos()
                local usz = consts.UPGRADE_IMAGE_SIZE + consts.UPGRADE_GRID_SPACING
                local ux = math.floor(wx / usz)
                local uy = math.floor(wy / usz)
                typedUpgradeId = nil
                spawnUpgrade(utype, ux, uy)
                break
            end
        end
    end

    local helpText = string.format(upgradePrestigeChangerText, isUpgradeDataModified and " *" or "", currentPrestige)
    local textR = regionFromText(font, 1000, helpText)
        :attachToRightOf(r)
        :attachToBottomOf(r)
        :moveRatio(-1, -1)
        :moveUnit(-4, -4)
    love.graphics.setColor(1, 1, 1)
    richtext.printRich(helpText, font, textR.x, textR.y, textR.w, "left")
    ui.debugRegion(r)
end

---@param x integer
---@param y integer
---@param prestige integer
---@return boolean
local function canMoveUpgradeTo(x, y, prestige)
    local h = g.hashPos(x, y, prestige)
    return not upgradeHashmap[h]
end

---@param maxnum integer
local function reservePrestige(maxnum)
    for i = 0, maxnum do
        upgradePosList[i + 1] = upgradePosList[i + 1] or {}
    end
end

---This does not perform any check. Use `canMoveUpgradeTo` to check!
---@param upos _dev.UpgradePosition
---@param x integer
---@param y integer
---@param prestige integer
local function moveUpgradeTo(upos, x, y, prestige)
    local hold = g.hashPos(upos.x, upos.y, currentPrestige)
    local hnew = g.hashPos(x, y, prestige)
    upgradeHashmap[hold] = nil
    upgradeHashmap[hnew] = upos.type

    -- Remove old upgrade from list
    for i, upos2 in ipairs(upgradePosList[currentPrestige + 1]) do
        if upos2 == upos then
            table.remove(upgradePosList[currentPrestige + 1], i)
            break
        end
    end

    -- Ensure prestige table sequentially generated
    reservePrestige(prestige)
    -- Insert
    table.insert(upgradePosList[prestige + 1], upos)
    -- Update
    upos.x = x
    upos.y = y
    -- Mark as modified
    isUpgradeDataModified = true
end



---------------
-- Main handler
---------------

local function dummy() end
local SCENES = {
    -- Update, draw, drawUI
    {dummy, dummy, drawResourceSceneUI},
    {updateHarvestScene, drawHarvestScene, drawHarvestSceneUI},
    {dummy, drawUpgradeScene, drawUpgradeSceneUI}
}
local currentSceneNumber = 1



local helpText = table.concat({
    "[H] = Show Harvest Area",
    "[U] = Show Upgrade Editor",
    "[R] = Show Resource Hack",
    "[C] = Reset Camera"
}, "\n")


---@param scene FreeCameraScene
local function drawDevUI(scene)
    SCENES[currentSceneNumber][3](g.getHUD():getSafeArea(), scene.camera)

    local font = g.getSmallFont(16)
    local finalText = "{o}"..helpText.."{/o}"
    local r = Kirigami(0, 0, ui.getScaledUIDimensions())
    local textR = regionFromText(font, 500, finalText)
        :attachToBottomOf(r)
        :attachToLeftOf(r)
        :moveRatio(1, -1)
        :moveUnit(4, -4)

    love.graphics.setColor(1, 1, 1)
    richtext.printRich(finalText, font, textR.x, textR.y, textR.w, "left")
end

function dev:draw()
    local COL = objects.Color("#FF00A2E8")
    love.graphics.clear(COL)

    self:setCamera()

    SCENES[currentSceneNumber][2]()

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    drawDevUI(self)
    self:renderNavbar()
    g.getHUD():drawResourceHUD(self.camera)
    ui.endUI()
end

function dev:update(dt)
    self:updateCamera(dt)
    g.getHUD():update(dt)
    SCENES[currentSceneNumber][1](dt)
end

---@param scene FreeCameraScene
local function trySpawnTokenAtMouse(scene)
    local world = g.getMainWorld()
    local mx, my = love.mouse.getPosition()
    local wx, wy = scene.camera:toWorld(mx, my)

    if wx >= 0 and wy >= 0 and wx < world.WIDTH and wy < world.HEIGHT then
        g.spawnToken(g.TOKEN_LIST[selectedTokenIndex], wx, wy)
    end
end

---@param self DevScene
rawset(dev, "keyreleased", function(self, k)
    if typedUpgradeId then
        if k == "return" then
            -- Pick first candidate
            local query = table.concat(typedUpgradeId):lower()

            if #query > 0 then
                for _, utype in ipairs(g.UPGRADE_LIST) do
                    local uinfo = g.getUpgradeInfo(utype)

                    if utype:lower():find(query, 1, true) or uinfo.name:lower():find(query) then
                        local wx, wy = self.camera:getPos()
                        local usz = consts.UPGRADE_IMAGE_SIZE + consts.UPGRADE_GRID_SPACING
                        local ux = math.floor(wx / usz)
                        local uy = math.floor(wy / usz)
                        spawnUpgrade(utype, ux, uy)
                        break
                    end
                end
            end

            typedUpgradeId = nil
            love.keyboard.setTextInput(false)
        elseif k == "escape" then
            typedUpgradeId = nil
            love.keyboard.setTextInput(false)
        elseif k == "backspace" then
            table.remove(typedUpgradeId)
        end

        return
    end

    if k == "h" then
        currentSceneNumber = 2
    elseif k == "r" then
        currentSceneNumber = 1
    elseif k == "u" then
        currentSceneNumber = 3
    elseif k == "c" then
        self.camera:setPos(0, 0)
        self:setZoom(0)
    elseif currentSceneNumber == 2 then
        if k == "up" then
            selectedTokenIndex = (selectedTokenIndex - 2) % #g.TOKEN_LIST + 1
        elseif k == "down" then
            selectedTokenIndex = selectedTokenIndex % #g.TOKEN_LIST + 1
        elseif k == "t" then
            trySpawnTokenAtMouse(self)
        end
    elseif currentSceneNumber == 3 then
        if k == "s" and love.keyboard.isDown("lctrl", "rctrl") then
            saveUpgradePositions()
        elseif k == "t" then
            local targetPrestige = math.min(currentPrestige + 1, 499)
            reservePrestige(targetPrestige)

            if lastUpgradeSelected then
                if canMoveUpgradeTo(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y, targetPrestige) then
                    moveUpgradeTo(
                        lastUpgradeSelected.pos,
                        lastUpgradeSelected.pos.x,
                        lastUpgradeSelected.pos.y,
                        targetPrestige
                    )
                    currentPrestige = targetPrestige
                end
            else
                currentPrestige = targetPrestige
            end
        elseif k == "g" then
            -- TODO: Deduplicate? Maybe not.
            local targetPrestige = math.max(currentPrestige - 1, 0)
            reservePrestige(targetPrestige)

            if lastUpgradeSelected then
                if canMoveUpgradeTo(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y, targetPrestige) then
                    moveUpgradeTo(
                        lastUpgradeSelected.pos,
                        lastUpgradeSelected.pos.x,
                        lastUpgradeSelected.pos.y,
                        targetPrestige
                    )
                    currentPrestige = targetPrestige
                end
            else
                currentPrestige = targetPrestige
            end
        elseif k == "/" then
            typedUpgradeId = {}
            love.keyboard.setTextInput(true)
        elseif lastUpgradeSelected then
            if k == "escape" or k == "return" then
                lastUpgradeSelected = nil
            elseif k == "delete" then
                for i, upos in ipairs(upgradePosList[currentPrestige + 1]) do
                    if upos == lastUpgradeSelected.pos then
                        local h = g.hashPos(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y, currentPrestige)
                        upgradeHashmap[h] = nil
                        table.remove(upgradePosList[currentPrestige + 1], i)
                        lastUpgradeSelected = nil
                        lastUpgradeHovered = nil -- just in case
                    end
                end
            elseif k == "left" then
                if canMoveUpgradeTo(lastUpgradeSelected.pos.x - 1, lastUpgradeSelected.pos.y, currentPrestige) then
                    moveUpgradeTo(
                        lastUpgradeSelected.pos,
                        lastUpgradeSelected.pos.x - 1,
                        lastUpgradeSelected.pos.y,
                        currentPrestige
                    )
                end
            elseif k == "up" then
                if canMoveUpgradeTo(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y - 1, currentPrestige) then
                    moveUpgradeTo(
                        lastUpgradeSelected.pos,
                        lastUpgradeSelected.pos.x,
                        lastUpgradeSelected.pos.y - 1,
                        currentPrestige
                    )
                end
            elseif k == "right" then
                if canMoveUpgradeTo(lastUpgradeSelected.pos.x + 1, lastUpgradeSelected.pos.y, currentPrestige) then
                    moveUpgradeTo(
                        lastUpgradeSelected.pos,
                        lastUpgradeSelected.pos.x + 1,
                        lastUpgradeSelected.pos.y,
                        currentPrestige
                    )
                end
            elseif k == "down" then
                if canMoveUpgradeTo(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y + 1, currentPrestige) then
                    moveUpgradeTo(
                        lastUpgradeSelected.pos,
                        lastUpgradeSelected.pos.x,
                        lastUpgradeSelected.pos.y + 1,
                        currentPrestige
                    )
                end
            end
        end
    end
end)

rawset(dev, "mousereleased", function(self, _, _, m)
    if currentSceneNumber == 2 and m == 4 then
        trySpawnTokenAtMouse(self)
    end
end)

return dev
