

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")

local lg = love.graphics


---@class MapScene: FreeCameraScene
local map = FreeCameraScene()



-- Total duration of transition, including fade in and fade out.
-- fade in is half the duration and fade out is half of it too.
local TRANSITION_DURATION = 0.9
-- Target transition scale.
local TRANSITION_SCALE = 4


---@class (exact) _MapBuilding
---@field public x integer
---@field public y integer
---@field public image string?
---@field public getImage (fun():string)?
---@field public bobbing {amplitude:number, period:number}?

---@param b _MapBuilding
---@return string
local function getBuildingImage(b)
    if b.getImage then return b.getImage() end
    return b.image --[[@as string]]
end

---@type table<string, _MapBuilding>
local buildings = {
    questarea_buildings = {
        image = "questarea_buildings",
        x = 413, y = 269,
    },
    bossarea_statue = {
        image = "bossarea_statue",
        x = 484, y = 183,
    },
    harvestarea_windmill = {
        image = "harvestarea_windmill",
        x = 338, y = 158,
    },
    harvestarea_house = {
        image = "harvestarea_house",
        x = 237, y = 211,
    },
    harvestarea_platform = {
        getImage = function()
            local p = g.getPrestige()
            local img = "harvestarea_platform_" .. tostring(p)
            return img
        end,
        image = "harvestarea_platform",
        x = 294, y = 177,
        bobbing = {amplitude = 3, period = 4},
    },
    upgradearea_dome = {
        image = "upgradearea_dome",
        x = 181, y = 140,
    },
    upgradearea_plasmahut = {
        image = "upgradearea_plasmahut",
        x = 157, y = 95,
    },
    fishingarea_buildings = {
        image = "fishingarea_buildings",
        x = 393, y = 94,
    },
    fishingarea_dock = {
        image = "fishingarea_dock",
        x = 377, y = 90,
    },
    carnivalarea_attractions = {
        image = "carnivalarea_attractions",
        x = 221, y = 255,
    }
}



---@class (exact) _CloudPlacement: _MapBuilding
---@field public seed integer pick any random integer to be used to randomize cloud bobbing

-- key same as POI ID
---@type table<string, _CloudPlacement>
local clouds = {
    fishing = {
        image = "bigcloud_fishingzone", seed = 12345,
        x = 210, y = 64
    },
    minigame = {
        image = "bigcloud_minigamezone", seed = 1,
        x = 107, y = 247
    },
    quest = {
        image = "bigcloud_questzone", seed = 42,
        x = 256, y = 232
    },
    boss = {
        image = "bigcloud_bosszone", seed = 666,
        x = 367, y = 131
    },
    -- Use underscore to denote decoration.
    _empty1 = {
        image = "bigcloud_emptyzone", seed = 0,
        x = 158, y = 2,
    }
}

-- We can't just `pairs(clouds)` when drawing as they have undefined order
---@type string[]
local cloudsOrder = {}
for k in pairs(clouds) do
    cloudsOrder[#cloudsOrder+1] = k
end
table.sort(cloudsOrder, function(a, b)
    return clouds[a].y > clouds[b].y
end)





---@class (exact) _POI.Def
---@field public nameContext string?
---@field public scene string
---@field public x integer
---@field public y integer
---@field public w integer
---@field public h integer
---@field public highlight string[] building to highlight
---@field public tx number text position
---@field public ty number text position
---@field public tcolor objects.Color Outline text color (actual text color always white)
---@field public price g.Bundle?
---@field public zoomOx number? zoom offsets, if we wanna zoom to a particular pos
---@field public zoomOy number? 
---@field public disabled boolean? Whether to disable this POI

---@class (exact) _POI: _POI.Def
---@field public type string
---@field public name string

---@type table<string, _POI>
local POI = {}
---@type table<string, string>
local sceneNamePOIMap = {}
---@param id string
---@param name string
---@param def _POI.Def
local function definePOI(id, name, def)
    ---@cast def _POI
    def.type = id
    def.name = loc(name, nil, {context = def.nameContext})
    POI[id] = def

    if def.price then
        assert(clouds[id], "cloud info must exist for this POI")
    end

    sceneNamePOIMap[def.scene] = id
end

---@param poiId string
---@return boolean
local function isUnlocked(poiId)
    local def = assert(POI[poiId])
    if def.disabled then
        return false
    end
    if not def.price then
        return true -- no price => unlocked
    end
    return g.getSn().unlockedPOI:has(poiId)
end


definePOI("harvest", "Harvest", {
    nameContext = "Place to harvest crops",
    scene = "harvest_scene",
    x = 197, y = 156, w = 144, h = 98,
    highlight = {"harvestarea_windmill", "harvestarea_house", "harvestarea_platform"},
    tx = 262, ty = 169, tcolor = objects.Color("#".."FF0FA569"),
    zoomOx = -4, zoomOy = 0
})
definePOI("upgrade", "Upgrade", {
    nameContext = "Place to get upgrades to improve gameplay",
    scene = "upgrade_scene",
    x = 106, y = 94, w = 91, h = 104,
    highlight = {"upgradearea_dome", "upgradearea_plasmahut"},
    tx = 152, ty = 132, tcolor = objects.Color("#".."FF41D7D7"),
    zoomOx = -2, zoomOy = 18
})
definePOI("fishing", "Fish", {
    disabled = true,
    scene = "fishing_scene",
    x = 236, y = 82, w = 142, h = 74,
    highlight = {"fishingarea_buildings", "fishingarea_dock"},
    tx = 323, ty = 100, tcolor = objects.Color("#".."FF14A0CD"),
    price = {money = 5000},
})
definePOI("minigame", "Chests and Rewards!", {
    scene = "chest_scene",
    x = 121, y = 246, w = 109, h = 93,
    highlight = {"carnivalarea_attractions"},
    tx = 188, ty = 277, tcolor = objects.Color("#".."FFE65AE6"),
    -- TODO: Price
    price = {money = 1000},
})
definePOI("quest", "Town", {
    scene = "customization_scene",
    x = 252, y = 267, w = 165, h = 100,
    highlight = {"questarea_buildings"},
    tx = 327, ty = 291, tcolor = objects.Color("#".."FFB4236E"),
    -- TODO: Price
    price = {money = 7000},
})
definePOI("boss", "Challenges", {
    nameContext = "Place to do in-game challenge (such as summoning boss)",
    scene = "boss_scene",
    x = 391, y = 168, w = 98, h = 90,
    highlight = {"bossarea_statue"},
    tx = 441, ty = 175, tcolor = objects.Color("#".."FF7891A5"),
    -- TODO: Price
    price = {money = 10000},
})



local MAP_BACKGROUND = objects.Color("#".."FF0F379B")

local mapAnim = {
    lg.newImage("src/scenes/map_scene/maps/map_dark.png"),
    -- lg.newImage("src/scenes/map_scene/maps/new_map2.png"),
    -- lg.newImage("src/scenes/map_scene/maps/map1.png"),
    -- lg.newImage("src/scenes/map_scene/maps/map2.png")
}




local props = {}


local function prop(x,y,img)
    table.insert(props, {
        x=x,y=y,
        image=img
    })
end



---@param t number
---@param seed integer
local function computeOffsetBySeed(t, seed)
    local offsetStartBase = helper.hashInteger(seed) % 65536
    local frequencyBase = helper.hashInteger(offsetStartBase) % 65536
    local offset = (offsetStartBase / 65536) * 2 * math.pi
    -- Tweak these values to tune the bobbing speed
    local frequency = 0.1 + (frequencyBase / 65536) * 0.3
    return math.sin(2 * math.pi * frequency * t + offset)
end



---@class (exact) _MapTransitionTarget
---@field public time number
---@field public x number
---@field public y number
---@field public action function?
---@field public duration number

function map:init()
    self.allowMousePan = false
    ---@type _MapTransitionTarget|nil
    self.transitionTarget = nil
    ---@type string|nil
    self.queuedTransitionTargetScene = nil
end





-- Clamps camera position and zoom to stay within map bounds
---@param camera Camera instance
---@param mapX number 
---@param mapY number
---@param mapW number
---@param mapH number
---@param ttgt _MapTransitionTarget?
local function clampCameraToMap(camera, mapX, mapY, mapW, mapH, ttgt)
    -- Adjust viewport and set position to center of map.
    local w, h = love.graphics.getDimensions()
    camera:setViewport(0, 0, w, h, 0.5, 0.5)
    local posX = mapX + mapW / 2
    local posY = mapY + mapH / 2

    local transitionScale = 1
    if ttgt then
        local t = 1 - math.abs(1 - helper.clamp(ttgt.time / ttgt.duration, 0, 1) * 2)
        local tt = helper.EASINGS.easeInCubic(t)
        local tt2 = helper.EASINGS.sineIn(t)
        posX = helper.lerp(posX, ttgt.x, tt2)
        posY = helper.lerp(posY, ttgt.y, tt2)
        transitionScale = helper.lerp(1, TRANSITION_SCALE, tt)
    end
    camera:setPos(posX, posY)

    -- Adjust zooming
    local scale = math.min(w / mapW, h / mapH)
    -- scale = math.max(math.floor(scale), 1)  -- OLD CODE: Only allow integer scaling with minimum of 1
    scale = math.max(scale, 1)
    camera:setZoom(scale * transitionScale)
end



---@param poi _POI
---@param x number?
---@param y number?
local function drawPOIText(poi, x, y)
    local r, g, b = poi.tcolor:getRGBA()
    local text = string.format("{wavy}{o thickness=2}{c  r=%.2f g=%.2f b=%.2f}%s{/c}{/o}{/wavy}", r, g, b, poi.name)

    richtext.printRich(text, _G.g.getBigFont(32), x or poi.tx, y or poi.ty, 1000, "center", 0, 1, 1, 500, 16)
end


local function dummy() end
---@param poi _POI
local function makePOIAction(poi)
    local action = dummy
    if poi.scene ~= "" then
        function action()
            return g.gotoScene(poi.scene)
        end
    end

    return action
end




local drawEdgeClouds
do

-- Constants for tweaking
local CLOUD_VERTICAL_MOVE_AMOUNT = 20  -- How far clouds move up/down
local CLOUD_MOVE_SPEED = 0.2  -- Speed of vertical oscillation
local CLOUD_OFFSET_FROM_CORNER = -20  -- Distance from actual corner point
local CLOUD_OFFSET_FROM_EDGE = -100  -- Distance from actual corner point
local CLOUD_OVERLAP_SPACING = 60  -- Spacing between clouds to cover corner

---@param cloudName string
---@param x number
---@param y number
---@param seed number
local function drawCornerCloud(cloudName, x, y, seed)
    local t = love.timer.getTime()
    -- Vertical movement based on time and seed
    local offsetY = math.sin(t * CLOUD_MOVE_SPEED + seed) * CLOUD_VERTICAL_MOVE_AMOUNT
    g.drawImage(cloudName, x, y + offsetY)
end



---@param x number
---@param y number
---@param w number
---@param h number
function drawEdgeClouds(x, y, w, h)
    -- Existing Corner Logic
    local o = CLOUD_OFFSET_FROM_CORNER
    local s = CLOUD_OVERLAP_SPACING
    local eo = CLOUD_OFFSET_FROM_EDGE

    -- Top-left corner (3 different clouds)
    drawCornerCloud("bigcloud_fishingzone", x + o, y + o, 1)
    drawCornerCloud("bigcloud_minigamezone", x + o + s, y + o, 2)
    drawCornerCloud("bigcloud_questzone", x + o, y + o + s, 3)

    -- Top-right corner (3 different clouds)
    drawCornerCloud("bigcloud_bosszone", x + w - o, y + o, 4)
    drawCornerCloud("bigcloud_emptyzone", x + w - o - s, y + o, 5)
    drawCornerCloud("bigcloud_fishingzone", x + w - o, y + o + s, 6)

    -- Bottom-left corner (3 different clouds)
    drawCornerCloud("bigcloud_minigamezone", x + o, y + h - o, 7)
    drawCornerCloud("bigcloud_bosszone", x + o + s, y + h - o, 8)
    drawCornerCloud("bigcloud_emptyzone", x + o, y + h - o - s, 9)

    -- Bottom-right corner (3 different clouds)
    drawCornerCloud("bigcloud_questzone", x + w - o, y + h - o, 10)
    drawCornerCloud("bigcloud_fishingzone", x + w - o - s, y + h - o, 11)
    drawCornerCloud("bigcloud_minigamezone", x + w - o, y + h - o - s, 12)

    --- Edge Clouds ---
    -- These use 'eo' to stay tucked against the outer edges
    drawCornerCloud("bigcloud_emptyzone", x + w / 2, y + eo, 13)         -- Top Edge
    drawCornerCloud("bigcloud_bosszone", x + w / 2, y + h - eo, 14)     -- Bottom Edge
    drawCornerCloud("bigcloud_fishingzone", x + eo, y + h / 2, 15)      -- Left Edge
    drawCornerCloud("bigcloud_questzone", x + w - eo, y + h / 2, 16)    -- Right Edge
end
end




---@param t number
---@param oy number
---@param clearRadius number
---@param cloudRadius number
---@param cloudSpacing number
local function drawIndividualClouds(t, oy, clearRadius, cloudRadius, cloudSpacing)
    local cx, cy = ui.getFullScreenRegion():getCenter()
    local ncircles = math.ceil(math.pi * (clearRadius + cloudSpacing) / cloudSpacing)
    local centerRadius = helper.magnitude(cx + 4, cy + 4) + cloudRadius
    local targetRadius = helper.lerp(centerRadius, clearRadius, t)

    local cloudCount = 0
    for i = 0, 1 do
        local cdist = targetRadius + i * cloudSpacing
        local ioff = i % 2 / 2
        for j = 0, ncircles do
            local angle = (j + ioff) * 2 * math.pi / ncircles

            local hash = helper.hashInteger(cloudCount + 12345) % 65536
            local x = math.cos(angle) * cdist + helper.lerp(-4, 4, hash / 65535)

            hash = helper.hashInteger(hash + 12345) % 65536
            local y = math.sin(angle) * cdist + helper.lerp(-4, 4, hash / 65535)

            hash = helper.hashInteger(hash + 12345) % 65536
            local r = cloudRadius + oy + i + helper.lerp(-10, 20, hash / 65535)

            love.graphics.circle("fill", x + cx, y + cy + oy, r)
            cloudCount = cloudCount + 1
        end
    end
end

---@param t number 0 = no clouds, 1 = fully covered
---@param clearRadius number Radius that it shouldn't have clouds on
---@param cloudRadius number Size of each individual cloud
---@param cloudSpacing number? Spacing of each individual cloud (default to `cloudRadius`)
local function drawCloudTransition(t, clearRadius, cloudRadius, cloudSpacing)
    prof_push("drawCloudTransition")

    cloudSpacing = cloudSpacing or cloudRadius
    love.graphics.setColor(1, 0.55, 0.78, 1)
    drawIndividualClouds(t, 9, clearRadius, cloudRadius, cloudSpacing)

    -- We want to fill the screen with white but keep a circle hole
    -- in the middle with specific radius.
    local cx, cy = ui.getFullScreenRegion():getCenter()
    local centerRadius = helper.magnitude(cx + 4, cy + 4) + cloudRadius
    local targetRadius = helper.lerp(centerRadius, clearRadius, t)
    love.graphics.setColor(1, 1, 1)
    love.graphics.clear(false, true, true)
    love.graphics.setStencilMode("draw", 1)
    love.graphics.circle("fill", cx, cy, targetRadius)
    love.graphics.setStencilMode("test", 0)
    love.graphics.rectangle("fill", ui.getFullScreenRegion():get())
    love.graphics.setStencilMode()

    love.graphics.setColor(1, 1, 1)
    drawIndividualClouds(t, 0, clearRadius, cloudRadius, cloudSpacing)

    prof_pop()
end



function map:draw()
    lg.clear(MAP_BACKGROUND)

    local mapW,mapH = mapAnim[1]:getDimensions()
    clampCameraToMap(self.camera,0,0,mapW,mapH,self.transitionTarget)
    self:setCamera()

    local unlockedPOIs = g.getSn().unlockedPOI

    lg.setColor(1,1,1)
    local t = love.timer.getTime()
    local i = (math.floor(t) % #mapAnim) + 1
    lg.draw(mapAnim[i],0,0)

    for _,p in ipairs(props) do
        g.drawImage(p.image,p.x,p.y)
    end

    -- Draw POI outline only.
    for poiType, poi in pairs(POI) do
        if isUnlocked(poiType) and iml.isHovered(poi.x, poi.y, poi.w, poi.h) then
            lg.setColor(1, 1, 1, 1)

            for _, buildingId in ipairs(poi.highlight) do
                local b = buildings[buildingId]
                -- Buildings are relative to top right
                local oy = 0
                if b.bobbing then
                    oy = b.bobbing.amplitude * math.sin((love.timer.getTime()*(math.pi*2)) / b.bobbing.period)
                end
                g.drawImageOffset(b.image.."_outline", b.x + 2, b.y - 2 + oy, 0, 1, 1, 1, 0)
            end
        end
    end

    -- Draw buildings
    lg.setColor(1, 1, 1)
    for _, b in pairs(buildings) do
        local oy = 0
        if b.bobbing then
            oy = b.bobbing.amplitude * math.sin((love.timer.getTime()*(math.pi*2)) / b.bobbing.period)
        end
        g.drawImageOffset(getBuildingImage(b), b.x, b.y + oy, 0, 1, 1, 1, 0)
    end

    -- Draw clouds
    for _, clid in ipairs(cloudsOrder) do
        if (not (POI[clid] and isUnlocked(clid))) then
            local cloud = clouds[clid]
            local yoff = computeOffsetBySeed(t, cloud.seed)
            g.drawImageOffset(cloud.image, cloud.x, cloud.y + yoff, 0, 1, 1, 0, 0)
        end
    end

    -- Draw POI tooltip
    local smallFont = g.getSmallFont(16)
    for _, poi in pairs(POI) do
        if consts.DEV_MODE and love.keyboard.isDown("space") then
            ui.debugRegion(Kirigami(poi.x, poi.y, poi.w, poi.h))
        end
        if isUnlocked(poi.type) then
            if iml.isHovered(poi.x, poi.y, poi.w, poi.h) then
                -- dont draw text when zooming; it looks weird
                if not self.transitionTarget then
                    drawPOIText(poi)
                end
            end

            if iml.wasJustClicked(poi.x, poi.y, poi.w, poi.h, 1) and not self.transitionTarget then
                self.transitionTarget = {
                    time = 0,
                    x = (poi.x + poi.w / 2) + (poi.zoomOx or 0),
                    y = (poi.y + poi.h / 2) + (poi.zoomOy or 0),
                    action = makePOIAction(poi),
                    duration = TRANSITION_DURATION
                }
                g.playUISound("map_zoom_woosh3",1,0.4)
            end
        elseif not poi.disabled then
            local buyText = ""

            for _, resId in ipairs(g.RESOURCE_LIST) do
                if poi.price[resId] then
                    local resInfo = g.getResourceInfo(resId)
                    buyText = buyText.." {"..resInfo.image.."} "..g.formatNumber(poi.price[resId])
                end
            end

            -- Compute cloud bobbing offset
            local cloud = clouds[poi.type]
            local yoff = computeOffsetBySeed(t, cloud.seed)

            local cx = poi.x + poi.w / 2
            local cy = poi.y
            g.drawImageOffset("map_unlockbutton", cx, cy + yoff, 0, 1, 1, 0.5, 0)
            richtext.printRich("{o}"..buyText.."{/o}", smallFont, cx, cy + 10, 1000, "center", 0, 1, 1, 500, 0)

            -- Button dimensions
            local bw, bh = select(3, g.getImageQuad("map_unlockbutton"):getViewport()) --[[@as number]]

            if iml.isHovered(cx - bw / 2, cy, bw, bh) then
                drawPOIText(poi, cx, cy - 16)
            end

            if iml.wasJustClicked(cx - bw / 2, cy, bw, bh, 1) then
                if g.canAfford(poi.price) then
                    g.subtractResources(poi.price)
                    unlockedPOIs:add(poi.type)
                end
            end
        end
    end

    -- Well it's unfortunate that we iterate POI twice, but we need to ensure
    -- the draw order is correct.

    do
    local x,y,w,h = 0,0, mapAnim[1]:getDimensions()
    drawEdgeClouds(x,y,w,h)
    end

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    do
    local ttgt = self.transitionTarget
    if ttgt then
        local val = 0
        if ttgt.action then
            val = helper.remap(ttgt.time, 0, ttgt.duration / 2, 0, 1)
        else
            -- its zooming out! invert it:
            val = helper.remap(ttgt.time, ttgt.duration / 2, ttgt.duration, 1, 0)
        end
        val = helper.EASINGS.sineInOut(helper.clamp(val, 0, 1))

        if val > 0 then
            drawCloudTransition(val, 160, 14)
        end
    end
    end
    self:renderPause()
    ui.endUI()
end



---@param scname string
local function makeTransitionTarget(scname)
    local poi = helper.assert(POI[sceneNamePOIMap[scname]], "invalid scene", scname)
    g.playUISound("map_zoom_woosh3",1,0.4)
    return {
        time = 0,
        x = (poi.x + poi.w / 2) + (poi.zoomOx or 0),
        y = (poi.y + poi.h / 2) + (poi.zoomOy or 0),
        action = makePOIAction(poi),
        duration = TRANSITION_DURATION
    }
end

function map:update(dt)
    self:updateCamera(dt)

    g.requestBGM(g.BGMID.MAP)

    -- Update transition data
    if self.transitionTarget then
        self.transitionTarget.time = self.transitionTarget.time + dt

        if self.transitionTarget.time >= self.transitionTarget.duration / 2 and self.transitionTarget.action then
            self.transitionTarget.action()
            self.transitionTarget.action = nil
        elseif self.transitionTarget.time >= self.transitionTarget.duration then
            if self.queuedTransitionTargetScene then
                self.transitionTarget = makeTransitionTarget(self.queuedTransitionTargetScene)
                self.queuedTransitionTargetScene = nil
                g.playUISound("map_zoom_woosh3",1,0.4)
            else
                self.transitionTarget = nil
            end
        end
    elseif self.queuedTransitionTargetScene then
        self.transitionTarget = makeTransitionTarget(self.queuedTransitionTargetScene)
        self.queuedTransitionTargetScene = nil
        g.playUISound("map_zoom_woosh3",1,0.4)
    end

    local w = g.getMainWorld()
    w:_disableMouseHarvester()
end



function map:enter()
    g.playUISound("map_zoom_woosh3",1,0.4)
end



function map.wheelmoved() end -- disable zooming
map.mousemoved = map.defaultMousemoved
map.keyreleased = map.defaultKeyreleased



---@param name string
function map:queueDestinationScene(name)
    self.queuedTransitionTargetScene = name
end



function map:keyreleased(k)
    if k == "escape" then
        local s = g.getSn()
        s.paused = not s.paused
    end
end



return map

