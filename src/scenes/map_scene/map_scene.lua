

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")

local lg = love.graphics


---@class MapScene: FreeCameraScene
local map = FreeCameraScene()



-- Total duration of transition, including fade in and fade out.
-- fade in is half the duration and fade out is half of it too.
local TRANSITION_DURATION = 1
-- Target transition scale.
local TRANSITION_SCALE = 4


---@class (exact) _MapBuilding
---@field public x integer
---@field public y integer
---@field public image string

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
        image = "harvestarea_platform",
        x = 294, y = 177,
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
---@field public x integer
---@field public y integer
---@field public w integer
---@field public h integer
---@field public highlight string[] building to highlight
---@field public tx number text position
---@field public ty number text position
---@field public tcolor objects.Color Outline text color (actual text color always white)
---@field public price g.Bundle?
---@field public action function

---@class (exact) _POI: _POI.Def
---@field public type string
---@field public name string

---@type table<string, _POI>
local POI = {}
local unlockedPOIs = objects.Set()
---@param id string
---@param name string
---@param def _POI.Def
local function definePOI(id, name, def)
    ---@cast def _POI
    def.type = id
    def.name = loc(name)
    POI[id] = def

    if def.price then
        assert(clouds[id], "cloud info must exist for this POI")
    else
        unlockedPOIs:add(id)
    end
end

definePOI("harvest", "Harvest", {
    x = 203, y = 174, w = 123, h = 54,
    highlight = {"harvestarea_windmill", "harvestarea_house", "harvestarea_platform"},
    tx = 262, ty = 169, tcolor = objects.Color("#".."FF0FA569"),
    action = function()
        g.gotoScene("harvest_scene")
    end
})
definePOI("upgrade", "Upgrade", {
    x = 104, y = 135, w = 64, h = 59,
    highlight = {"upgradearea_dome", "upgradearea_plasmahut"},
    tx = 152, ty = 132, tcolor = objects.Color("#".."FF41D7D7"),
    action = function()
        g.gotoScene("upgrade_scene")
    end
})
definePOI("fishing", "Fish", {
    x = 238, y = 88, w = 136, h = 63,
    highlight = {"fishingarea_buildings", "fishingarea_dock"},
    tx = 323, ty = 100, tcolor = objects.Color("#".."FF14A0CD"),
    price = {money = 5000},
    action = function()
        g.gotoScene("fishing_scene")
    end
})
definePOI("minigame", "Minigames", {
    x = 127, y = 269, w = 93, h = 63,
    highlight = {"carnivalarea_attractions"},
    tx = 188, ty = 277, tcolor = objects.Color("#".."FFE65AE6"),
    -- TODO: Price
    price = {money = 1000},
    -- TODO: Action
    action = function() end
})
definePOI("quest", "Quests", {
    x = 263, y = 276, w = 143, h = 71,
    highlight = {"questarea_buildings"},
    tx = 327, ty = 291, tcolor = objects.Color("#".."FFB4236E"),
    -- TODO: Price
    price = {money = 7000},
    -- TODO: Action
    action = function() end
})
definePOI("boss", "Challenges", {
    x = 399, y = 183, w = 80, h = 70,
    highlight = {"bossarea_statue"},
    tx = 441, ty = 175, tcolor = objects.Color("#".."FF7891A5"),
    -- TODO: Price
    price = {money = 10000},
    -- TODO: Action
    action = function() end
})



local MAP_BACKGROUND = objects.Color("#".."FF0F379B")

local mapAnim = {
    lg.newImage("src/scenes/map_scene/maps/map.png"),
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
    local offsetStartBase = (seed * 214013 + 2531011) % 65536
    local frequencyBase = (offsetStartBase * 214013 + 2531011) % 65536
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

    prop(302,215,"happy_cat")
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

    local transitionT = 0
    local transitionScale = 1
    if ttgt then
        local t = 1 - math.abs(1 - helper.clamp(ttgt.time / ttgt.duration, 0, 1) * 2)
        transitionT = helper.EASINGS.sineOut(t)
        posX = helper.lerp(posX, ttgt.x, transitionT)
        posY = helper.lerp(posY, ttgt.y, transitionT)
        transitionScale = helper.lerp(1, TRANSITION_SCALE, transitionT)
    end
    camera:setPos(posX, posY)

    -- Adjust zooming
    local scale = math.min(w / mapW, h / mapH)
    -- Only allow integer scaling with minimum of 1
    scale = math.max(math.floor(scale), 1)
    camera:setZoom(scale * transitionScale)
end




---@param poi _POI
---@param x number?
---@param y number?
local function drawPOIText(poi, x, y)
    local r, g, b = poi.tcolor:getRGBA()
    local text = string.format("{o thickness=2 r=%.2f g=%.2f b=%.2f}%s{/o}", r, g, b, poi.name)

    richtext.printRich(text, _G.g.getBigFont(32), x or poi.tx, y or poi.ty, 1000, "center", 0, 1, 1, 500, 16)
end


function map:draw()
    lg.clear(MAP_BACKGROUND)

    local mapW,mapH = mapAnim[1]:getDimensions()
    clampCameraToMap(self.camera,0,0,mapW,mapH,self.transitionTarget)
    self:setCamera()

    lg.setColor(1,1,1)
    local t = love.timer.getTime()
    local i = (math.floor(t) % #mapAnim) + 1
    lg.draw(mapAnim[i],0,0)

    for _,p in ipairs(props) do
        g.drawImage(p.image,p.x,p.y)
    end

    -- Draw POI outline only.
    for _, poiType in ipairs(unlockedPOIs) do
        local poi = POI[poiType]

        if iml.isHovered(poi.x, poi.y, poi.w, poi.h) then
            lg.setColor(1, 1, 1, 1)

            for _, buildingId in ipairs(poi.highlight) do
                local b = buildings[buildingId]
                -- Buildings are relative to top right
                g.drawImageOffset(b.image.."_outline", b.x + 2, b.y - 2, 0, 1, 1, 1, 0)
            end
        end
    end

    -- Draw buildings
    lg.setColor(1, 1, 1)
    for _, b in pairs(buildings) do
        g.drawImageOffset(b.image, b.x, b.y, 0, 1, 1, 1, 0)
    end

    -- Draw clouds
    for _, clid in ipairs(cloudsOrder) do
        if not unlockedPOIs:has(clid) then
            local cloud = clouds[clid]
            local yoff = computeOffsetBySeed(t, cloud.seed)
            g.drawImageOffset(cloud.image, cloud.x, cloud.y + yoff, 0, 1, 1, 0, 0)
        end
    end

    -- Draw POI tooltip
    local smallFont = g.getSmallFont(16)
    for _, poi in pairs(POI) do
        if unlockedPOIs:has(poi.type) then
            if iml.isHovered(poi.x, poi.y, poi.w, poi.h) then
                drawPOIText(poi)
            end

            if iml.wasJustClicked(poi.x, poi.y, poi.w, poi.h, 1) and not self.transitionTarget then
                self.transitionTarget = {
                    time = 0,
                    x = poi.x + poi.w / 2,
                    y = poi.y + poi.h / 2,
                    action = poi.action,
                    duration = TRANSITION_DURATION
                }
            end
        else
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

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    ui.endUI()
end




function map:update(dt)
    self:updateCamera(dt)

    -- Update transition data
    if self.transitionTarget then
        self.transitionTarget.time = self.transitionTarget.time + dt

        if self.transitionTarget.time >= self.transitionTarget.duration / 2 and self.transitionTarget.action then
            self.transitionTarget.action()
            self.transitionTarget.action = nil
        elseif self.transitionTarget.time >= self.transitionTarget.duration then
            -- TODO: Don't set this to nil when we chain transition later.
            self.transitionTarget = nil
        end
    end
end



function map.wheelmoved() end -- disable zooming
map.mousemoved = map.defaultMousemoved
map.keyreleased = map.defaultKeyreleased




return map

