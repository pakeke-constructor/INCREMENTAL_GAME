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

    local W1,W2 = objects.Color.WHITE, objects.Color({0.8,0.8,0.84})

    if ui.Button("{o}MAX "..resId, W1,W2, b1:padUnit(4):get()) then
        g.addResource(resId, limit)
    end
    if ui.Button("{o}+10% "..resId, W1,W2, b2:padUnit(4):get()) then
        g.addResource(resId, math.floor(limit/10+0.5))
    end
    if ui.Button("{o}-10% ".. resId, W1,W2, b3:padUnit(4):get()) then
        g.addResource(resId, -math.floor(limit/10+0.5))
    end
    if ui.Button("{o}ZERO "..resId, W1,W2, b4:padUnit(4):get()) then
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
    "[LMB] = Spawn @ Mouse Pos"
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
---@field public x integer
---@field public y integer

---@class _dev.Connector: _dev.UpgradePosition
---@field public length integer
---@field public isVertical boolean
local _dev_Connector = {__tostring = function(self)
    return (self.isVertical and "vert" or "horz").." connector"
end}

---@class _g.UpgradePrestigeData
---@field public upgrades table<string, _dev.UpgradePosition>
---@field public connectors _dev.Connector[]

---@param prestige integer
---@return _g.UpgradePrestigeData, boolean
local function loadUpgradeList(prestige)
    local path = "src/upgrades/prestige_"..prestige..".json"
    if love.filesystem.getInfo(path, "file") then
        return json.decode((assert(love.filesystem.read(path)))), true
    end
    return {upgrades = {}, connectors = {}}, false
end

---@return table<string, _dev.UpgradePosition>[] @List of upgrades by prestige
---@return _dev.Connector[][] @only the left or the top endpoints
---@return table<integer, string|_dev.Connector> @Hashmap of the whole upgrades
local function loadAllUpgrades()
    local prestige = 0
    local output = {}
    local connectors = {}
    local hashmap = {}
    while true do
        local r, continue = loadUpgradeList(prestige)
        local con = {}

        output[#output+1] = r.upgrades
        connectors[#connectors+1] = con

        -- Iterate upgrades
        for utype, upos in pairs(r.upgrades) do
            local h = g.hashPos(upos.x, upos.y, prestige)
            if hashmap[h] then
                error(string.format(
                    "prestige %d position %dx%d trying to put '%s' occupied by '%s'",
                    prestige,
                    upos.x,
                    upos.y,
                    tostring(utype),
                    tostring(hashmap[h])
                ))
            end
            hashmap[h] = utype
        end

        -- Iterate connectors
        for _, cpos in ipairs(r.connectors) do
            --[[
            Connector X and Y only either points to the top (vertical)
            or the left endpoint. Consider this example:

              01234
            0 U===U
            1 U
            2 |
            3 |
            4 U

            '=' is horizontal connector, and '|' is vertical connector. The connector
            stored in JSON is:
            * For horizontal: {"x": 1, "y": 0, "isVertical": false, "length": 3}
            * For vertical: {"x": 0, "y": 1, "isVertical": true, "length": 2}
            ]]
            for i = 0, cpos.length - 1 do
                local dx = cpos.isVertical and 0 or i
                local dy = cpos.isVertical and i or 0
                local ctype = setmetatable(cpos, _dev_Connector)
                local h = g.hashPos(cpos.x + dx, cpos.y + dy, prestige)
                if hashmap[h] then
                    error(string.format(
                        "prestige %d position %dx%d trying to put '%s' on '%s'",
                        prestige,
                        cpos.x + dx,
                        cpos.y + dy,
                        tostring(ctype),
                        tostring(hashmap[h])
                    ))
                end
                hashmap[h] = ctype
            end

            con[#con+1] = cpos
        end

        if not continue then
            break
        end

        prestige = prestige + 1
    end

    return output, connectors, hashmap
end

local upgradePosList, upgradeConnectors, upgradeHashmap = loadAllUpgrades()
local isUpgradeDataModified = false
local currentPrestige = 0
---@type {pos:_dev.UpgradePosition,info:g.UpgradeInfo}|nil
local lastUpgradeHovered = nil
---@type {pos:_dev.UpgradePosition,info:g.UpgradeInfo}|nil
local lastUpgradeSelected = nil

local function saveAllUpgrades()
    -- We gotta be careful with the saving as it may be [{stuff}, {}, {}, {stuff}, {}]
    local maxIndicesToSave = 0
    for i, ulist in ipairs(upgradePosList) do
        if next(ulist) then
            maxIndicesToSave = i
        end
    end

    for i = 1, maxIndicesToSave do
        -- "root" is our game source directory but RW.
        -- i - 1 because prestige starts at 0
        local data = json.encode({
            upgrades = upgradePosList[i],
            connectors = upgradeConnectors[i]
        })
        love.filesystem.write("root/src/upgrades/prestige_"..(i - 1)..".json", data)
    end

    for i = maxIndicesToSave + 1, #upgradePosList do
        -- Delete empty prestiges
        love.filesystem.remove("root/src/upgrades/prestige_"..(i - 1)..".json")
    end

    -- Reload
    lastUpgradeHovered = nil
    lastUpgradeSelected = nil
    upgradePosList, upgradeConnectors, upgradeHashmap = loadAllUpgrades()
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
local ABOVE_PRESTIGE_COLOR = objects.Color("#".."FFDDB0EB")

local function drawPrestigeShadow(prestige)
    for _, upos in pairs(upgradePosList[prestige]) do
        local x, y, sz = getUpgradeCoords(upos.x, upos.y)
        love.graphics.rectangle("line", x, y, sz, sz)
    end

    for _, con in ipairs(upgradeConnectors[prestige]) do
        local x, y, sz = getUpgradeCoords(con.x, con.y)
        if con.isVertical then
            love.graphics.rectangle(
                "line",
                x + consts.UPGRADE_GRID_SPACING,
                y - consts.UPGRADE_GRID_SPACING,
                sz - 2 * consts.UPGRADE_GRID_SPACING,
                (sz + consts.UPGRADE_GRID_SPACING) * con.length + consts.UPGRADE_GRID_SPACING
            )
        else
            love.graphics.rectangle(
                "line",
                x - consts.UPGRADE_GRID_SPACING,
                y + consts.UPGRADE_GRID_SPACING,
                (sz + consts.UPGRADE_GRID_SPACING) * con.length + consts.UPGRADE_GRID_SPACING,
                sz - 2 * consts.UPGRADE_GRID_SPACING
            )
        end
    end
end



---@param x integer
---@param y integer
---@param length integer
---@param isVertical boolean
local function drawConnector(x, y, length, isVertical)
    local tx, ty, sz = getUpgradeCoords(x, y)
    local rx, ry, rw, rh

    if isVertical then
        rx = tx + consts.UPGRADE_GRID_SPACING
        ry = ty - consts.UPGRADE_GRID_SPACING
        rw = sz - 2 * consts.UPGRADE_GRID_SPACING
        rh = (sz + consts.UPGRADE_GRID_SPACING) * length + consts.UPGRADE_GRID_SPACING
    else
        rx = tx - consts.UPGRADE_GRID_SPACING
        ry = ty + consts.UPGRADE_GRID_SPACING
        rw = (sz + consts.UPGRADE_GRID_SPACING) * length + consts.UPGRADE_GRID_SPACING
        rh = sz - 2 * consts.UPGRADE_GRID_SPACING
    end

    love.graphics.setColor(g.COLORS.UPGRADE_CONNECTOR)
    love.graphics.rectangle("fill", rx, ry, rw, rh)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", rx, ry, rw, rh)
end

---@param pos1 _dev.UpgradePosition
---@param pos2 _dev.UpgradePosition
---@param prestige integer
local function canAttachConnector(pos1, pos2, prestige)
    --[[
    Connector attachment criteria:
    * Either only the X or Y is different (horizontal or vertical)
    * No other connectors or upgrades on the way
    * The delta difference of each position must be larger than 1
    ]]

    local dx = math.abs(pos1.x - pos2.x)
    local dy = math.abs(pos1.y - pos2.y)
    -- Either only the X or Y different (horz or vert)
    if dx > 0 and dy > 0 then
        return false
    end
    local length = math.max(dx, dy)
    local isVertical = dy > 0

    -- Delta difference must be larger than 1
    if length < 2 then
        return false
    end

    local startX, startY = math.min(pos1.x, pos2.x), math.min(pos1.y, pos2.y)
    local targetCon = nil
    -- No other connectors or upgrades on the way
    for i = 1, math.max(dx, dy) - 1 do
        local inmap
        if isVertical then
            inmap = upgradeHashmap[g.hashPos(startX, startY + i, prestige)]
        else
            inmap = upgradeHashmap[g.hashPos(startX + i, startY, prestige)]
        end

        if inmap then
            if type(inmap) == "string" then
                -- Another upgrade is on the way
                return false
            elseif inmap.isVertical ~= isVertical then
                -- Different kind of connector
                return false
            elseif targetCon ~= nil and targetCon ~= inmap then
                -- Different kind of connector
                return false
            else
                targetCon = inmap
            end
        end
    end

    -- Checks passed
    return true, targetCon
end

---Note: Checks are not performed!
---@param x integer
---@param y integer
---@param length integer
---@param isVertical boolean
local function addUpgradeConnector(x, y, length, isVertical)
    ---@type _dev.Connector
    local result = {
        x = x,
        y = y,
        length = length,
        isVertical = isVertical
    }
    -- Spread the connector hashmaps
    for i = 0, length do
        local dx = isVertical and 0 or i
        local dy = isVertical and i or 0
        upgradeHashmap[g.hashPos(x + dx, y + dy, currentPrestige)] = result
    end
    table.insert(upgradeConnectors[currentPrestige + 1], result)
    isUpgradeDataModified = true
    return result
end

---@param con _dev.Connector
local function removeUpgradeConnector(con)
    -- Sanity check: Ensure it's in current prestige
    local ok = false
    for i, c in ipairs(upgradeConnectors[currentPrestige + 1]) do
        if c == con then
            ok = true
            table.remove(upgradeConnectors[currentPrestige + 1], i)
            break
        end
    end

    assert(ok, "attempt to remove connector across different prestige")

    -- Nil out the connector hashmaps
    for i = 0, con.length - 1 do
        local dx = con.isVertical and 0 or i
        local dy = con.isVertical and i or 0
        upgradeHashmap[g.hashPos(con.x + dx, con.y + dy, currentPrestige)] = nil
    end

    isUpgradeDataModified = true
end

local NEIGHBORS = {{1,0},{-1,0},{0,1},{0,-1}}
---@param x integer
---@param y integer
local function getConnectorAround(x, y)
    ---@type _dev.Connector[]
    local result = {}
    for _, d in ipairs(NEIGHBORS) do
        local vert = d[2] ~= 0
        local h = g.hashPos(x + d[1], y + d[2], currentPrestige)
        local inmap = upgradeHashmap[h]

        if inmap and type(inmap) ~= "string" and inmap.isVertical == vert then
            result[#result+1] = inmap
        end
    end

    return result
end



local function drawUpgradeScene()
    lastUpgradeHovered = nil

    -- Draw upgrade positions below current prestige
    if currentPrestige > 0 then
        love.graphics.setColor(BELOW_PRESTIGE_COLOR)
        drawPrestigeShadow(currentPrestige)
    end

    love.graphics.setColor(1, 1, 1)
    -- Draw connectors on current prestige
    for _, con in ipairs(upgradeConnectors[currentPrestige + 1]) do
        drawConnector(con.x, con.y, con.length, con.isVertical)
    end

    -- Draw upgrades on current prestige
    for utype, upos in pairs(upgradePosList[currentPrestige + 1]) do
        local uinfo = g.getUpgradeInfo(utype)
        local x, y, sz = getUpgradeCoords(upos.x, upos.y)
        local highlight = not not (lastUpgradeSelected and lastUpgradeSelected.pos == upos)
        local isHovered, wasClicked = ui.upgradeBoxUI(uinfo, 1, x, y, sz, sz, highlight)

        if isHovered then
            lastUpgradeHovered = {pos = upos, info = uinfo}
        end
        if wasClicked then
            if love.keyboard.isDown("lshift", "rshift") then
                if lastUpgradeSelected then
                    local canAttach, con = canAttachConnector(upos, lastUpgradeSelected.pos, currentPrestige)

                    if canAttach then
                        if con then
                            -- Remove connector
                            removeUpgradeConnector(con)
                        else
                            -- Add connector
                            local conX = math.min(lastUpgradeSelected.pos.x, upos.x)
                            local conY = math.min(lastUpgradeSelected.pos.y, upos.y)
                            local vert = lastUpgradeSelected.pos.x == upos.x
                            local length = math.max(
                                math.abs(lastUpgradeSelected.pos.x - upos.x),
                                math.abs(lastUpgradeSelected.pos.y - upos.y)
                            ) - 1
                            addUpgradeConnector(conX + (vert and 0 or 1), conY + (vert and 1 or 0), length, vert)
                        end
                    end
                end
            else
                lastUpgradeSelected = {pos = upos, info = uinfo}
            end
        end
    end

    -- Draw upgrade positions above current prestige
    if upgradePosList[currentPrestige + 2] then
        love.graphics.setColor(ABOVE_PRESTIGE_COLOR)
        drawPrestigeShadow(currentPrestige + 2)
    end
end

---@param utype string
---@param x integer
---@param y integer
local function spawnUpgrade(utype, x, y)
    local upos = upgradePosList[currentPrestige + 1][utype]
    -- If there's none in the current prestige, spawn new one
    if not upos then
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
        upos = {x = tx, y = ty}
        upgradeHashmap[g.hashPos(tx, ty, currentPrestige)] = utype
        upgradePosList[currentPrestige + 1][utype] = upos
        isUpgradeDataModified = true
    end

    lastUpgradeSelected = {pos = upos, info = g.getUpgradeInfo(utype)}
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
}, "\n").."{/o}"

---@param r layout.Region
---@param cam Camera
local function drawUpgradeSceneUI(r, cam)
    local font = g.getSmallFont(16)
    love.graphics.setColor(1, 1, 1)

    if lastUpgradeSelected then
        local textTab = {
            string.format("%s (%s)", lastUpgradeSelected.info.name, lastUpgradeSelected.info.type),
            string.format("X: %d | Y: %d", lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y),
            "[Esc|Enter] = Deselect",
        }
        if #getConnectorAround(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y) > 0 then
            textTab[#textTab+1] = "{c r=1 g=0.1 b=0.1}Detach Connector To Move{/c}"
        else
            textTab[#textTab+1] = "[Arrow Keys] = Move"
            textTab[#textTab+1] = "[T|G] = Move Prestige"
        end
        local text = "{o}"..table.concat(textTab, "\n").."{/o}"
        local x, y = getUpgradeCoords(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y)
        local mx, my = ui.getUIScalingTransform():inverseTransformPoint(cam:toScreen(x + 14, y + 14))
        richtext.printRich(text, font, mx, my, 20000, "left")
    end

    if lastUpgradeHovered then
        local textTab = {
            string.format("%s (%s)", lastUpgradeHovered.info.name, lastUpgradeHovered.info.type),
            string.format("X: %d | Y: %d", lastUpgradeHovered.pos.x, lastUpgradeHovered.pos.y),
        }

        if lastUpgradeSelected and canAttachConnector(lastUpgradeSelected.pos, lastUpgradeHovered.pos, currentPrestige) then
            textTab[#textTab+1] = "[Shift+LMB] = Attach/Detach Connector"
        end

        local text = "{o}"..table.concat(textTab, "\n").."{/o}"
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
        upgradeConnectors[i + 1] = upgradeConnectors[i + 1] or {}
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
    local utype = assert(upgradeHashmap[hold])
    upgradeHashmap[hold] = nil
    upgradeHashmap[hnew] = utype

    -- Remove old upgrade from list
    upgradePosList[currentPrestige + 1][utype] = nil
    -- Ensure prestige table sequentially generated
    reservePrestige(prestige)
    -- Insert
    upgradePosList[prestige + 1][utype] = upos
    -- Update
    upos.x = x
    upos.y = y
    -- Mark as modified
    isUpgradeDataModified = true
end


--------------------
-- All Upgrade Scene
--------------------

local UpgradeDescription = require("src.ui.upgrades.upgrade_description_ui")

---@type ui.UpgradeDescription|nil
local selectedUpgradeDescription = nil

---@type g.UpgradeKind[]
local UPGRADE_KINDS = {"TOKEN", "HARVESTING", "TOKEN_MODIFIER", "MISC"}

local function drawAllUpgrades()
    ---@type table<g.UpgradeKind, string[]>
    local listByCategory = {}
    ---@type string[]
    local unknownUpgradeKind = {}

    for _, kind in ipairs(UPGRADE_KINDS) do
        listByCategory[kind] = {}
    end

    for _, utype in ipairs(g.UPGRADE_LIST) do
        local uinfo = g.getUpgradeInfo(utype)

        if not listByCategory[uinfo.kind] then
            unknownUpgradeKind[#unknownUpgradeKind+1] = uinfo.kind
            listByCategory[uinfo.kind] = {}
        end

        table.insert(listByCategory[uinfo.kind], utype)
    end

    -- Merge
    ---@type string[]
    local allKinds = {}
    table.move(UPGRADE_KINDS, 1, #UPGRADE_KINDS, 1, allKinds)
    table.move(unknownUpgradeKind, 1, #unknownUpgradeKind, #allKinds, allKinds)

    local MAX_X = 9 -- inclusive
    local y = 0
    local x = 0
    local hovered = nil

    for _, kind in ipairs(allKinds) do
        for _, utype in ipairs(listByCategory[kind]) do
            local uinfo = g.getUpgradeInfo(utype)
            local level = g.getUpgradeLevel(uinfo)
            local tx, ty, sz = getUpgradeCoords(x, y)

            local isHovered, wasJustClicked = ui.upgradeBoxUI(uinfo, level, tx,ty,sz,sz, false)
            if isHovered then
                hovered = uinfo
            end
            if wasJustClicked then
                local session = g.getSn()

                -- Uh...
                if love.keyboard.isDown("lshift", "rshift") then
                    session.upgradeLevels[utype] = uinfo.maxLevel
                elseif love.keyboard.isDown("lctrl", "rctrl") then
                    session.upgradeLevels[utype] = nil
                elseif level < uinfo.maxLevel then
                    session.upgradeLevels[utype] = (session.upgradeLevels[utype] or 0) + 1
                end
                hovered = nil
            end

            x = x + 1
            if x > MAX_X then
                y = y + 1
                x = 0
            end
        end

        if x > 0 then
            y = y + 2 -- Leave empty space for next upgrade kind
            x = 0
        else
            y = y + 1
        end
    end

    -- Create description UI
    if hovered then
        if not selectedUpgradeDescription or selectedUpgradeDescription:getType() ~= hovered.type then
            selectedUpgradeDescription = UpgradeDescription(hovered)
        end
    else
        selectedUpgradeDescription = nil
    end
end

---@param r layout.Region
local function drawAllUpgradesUI(r)
    if selectedUpgradeDescription then
        local mx, my = ui.getMouse()
        local descriptionBoxR = Kirigami(0, 0, selectedUpgradeDescription:getDimensions())
            :set(mx + 14, my - 3)
            :clampInside(r:padUnit(4))

        -- Upgrade description
        selectedUpgradeDescription:draw(descriptionBoxR.x, descriptionBoxR.y)
    end
end



---------------
-- Main handler
---------------

local function dummy() end
local SCENES = {
    -- Update, draw, drawUI
    {
        name = "Show Resource Hack",
        update = dummy,
        draw = dummy,
        drawUI = drawResourceSceneUI
    },
    {
        name = "Show Upgade Pos Editor",
        update = dummy,
        draw = drawUpgradeScene,
        drawUI = drawUpgradeSceneUI
    },
    {
        name = "Show All Upgrades",
        update = dummy,
        draw = drawAllUpgrades,
        drawUI = drawAllUpgradesUI,
    },
    {
        name = "Show Harvest Area",
        update = updateHarvestScene,
        draw = drawHarvestScene,
        drawUI = drawHarvestSceneUI
    },
}
local currentSceneNumber = 1





---@param scene FreeCameraScene
local function drawDevUI(scene)
    SCENES[currentSceneNumber].drawUI(g.getHUD():getSafeArea(), scene.camera)

    local font = g.getSmallFont(16)
    local textTab = {"[C] = Reset Camera", "", "Scenes:"}
    for i, v in ipairs(SCENES) do
        local t = "["..i.."] = "..v.name

        if currentSceneNumber == i then
            textTab[#textTab+1] = "> {c r=0 g=1 b=0}{wavy}"..t.."{/wavy}{/c} <"
        else
            textTab[#textTab+1] = t
        end
    end

    local finalText = "{o}"..table.concat(textTab, "\n").."{/o}"
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

    SCENES[currentSceneNumber].draw()

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    drawDevUI(self)
    self:renderMapButton()
    g.getHUD():draw({profile = false})
    ui.endUI()
end

function dev:update(dt)
    self:updateCamera(dt)
    g.getHUD():update(dt)
    SCENES[currentSceneNumber].update(dt)
end

---@param scene FreeCameraScene
local function trySpawnTokenAtMouse(scene)
    local worldW, worldH = g.getWorldDimensions()
    local mx, my = love.mouse.getPosition()
    local wx, wy = scene.camera:toWorld(mx, my)

    if wx >= 0 and wy >= 0 and wx < worldW and wy < worldH then
        g.spawnToken(g.TOKEN_LIST[selectedTokenIndex], wx, wy)
    end
end

local DELTAS = {
    left = {-1, 0},
    up = {0, -1},
    right = {1, 0},
    down = {0, 1}
}
---@param self DevScene
function dev:keyreleased(k)
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

    local num = tonumber(k)

    if num and SCENES[num] then
        currentSceneNumber = num
    elseif k == "c" then
        self.camera:setPos(0, 0)
        self:setZoom(0)
    elseif currentSceneNumber == 4 then
        if k == "up" then
            selectedTokenIndex = (selectedTokenIndex - 2) % #g.TOKEN_LIST + 1
        elseif k == "down" then
            selectedTokenIndex = selectedTokenIndex % #g.TOKEN_LIST + 1
        elseif k == "t" then
            trySpawnTokenAtMouse(self)
        end
    elseif currentSceneNumber == 2 then
        if k == "s" and love.keyboard.isDown("lctrl", "rctrl") then
            saveAllUpgrades()
        elseif k == "t" or k == "g" then
            local targetPrestige = math.min(math.max(currentPrestige + (k == "t" and 1 or -1), 0), 499)
            reservePrestige(targetPrestige)

            if lastUpgradeSelected then
                if
                    #getConnectorAround(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y) == 0 and
                    canMoveUpgradeTo(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y, targetPrestige)
                then
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
                local h = g.hashPos(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y, currentPrestige)
                -- Remove connectors
                for _, con in ipairs(getConnectorAround(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y)) do
                    removeUpgradeConnector(con)
                end

                -- Remove upgrade
                upgradeHashmap[h] = nil
                upgradePosList[currentPrestige + 1][lastUpgradeSelected.info.type] = nil
                lastUpgradeHovered = nil
                lastUpgradeSelected = nil
            elseif DELTAS[k] then
                local d = DELTAS[k]
                local tx = lastUpgradeSelected.pos.x + d[1]
                local ty = lastUpgradeSelected.pos.y + d[2]
                if
                    #getConnectorAround(lastUpgradeSelected.pos.x, lastUpgradeSelected.pos.y) == 0 and
                    canMoveUpgradeTo(tx, ty, currentPrestige)
                then
                    moveUpgradeTo(lastUpgradeSelected.pos, tx, ty, currentPrestige)
                end
            end
        end
    end
end


function dev:mousereleased(_, _, m)
    if currentSceneNumber == 4 and m == 1 then
        trySpawnTokenAtMouse(self)
    end
end

dev.mousemoved = dev.defaultMousemoved


return dev
