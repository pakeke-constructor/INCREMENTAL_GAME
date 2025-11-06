

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")

local lg = love.graphics


---@class MapScene: FreeCameraScene
local map = FreeCameraScene()



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
    _empty1 = {
        image = "bigcloud_emptyzone", seed = 0,
        x = 158, y = 2,
    }
}

-- We can't just pairs(clouds) as they have undefined order
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

definePOI("harvest", "Harvest Area", {
    x = 219, y = 178, w = 55, h = 43,
    highlight = {"harvestarea_windmill", "harvestarea_house", "harvestarea_platform"},
    action = function()
        g.gotoScene("harvest_scene")
    end
})
definePOI("upgrade", "Upgrades", {
    x = 104, y = 135, w = 64, h = 59,
    highlight = {"upgradearea_dome", "upgradearea_plasmahut"},
    action = function()
        g.gotoScene("upgrade_scene")
    end
})
definePOI("fishing", "Fishing", {
    x = 238, y = 88, w = 136, h = 63,
    highlight = {"fishingarea_buildings", "fishingarea_dock"},
    price = {money = 5000, logs = 100},
    action = function()
        g.gotoScene("fishing_scene")
    end
})
definePOI("minigame", "Minigames", {
    x = 127, y = 269, w = 93, h = 63,
    highlight = {"carnivalarea_attractions"},
    -- TODO: Price
    price = {},
    -- TODO: Action
    action = function() end
})
definePOI("quest", "Quests", {
    x = 263, y = 276, w = 143, h = 71,
    highlight = {"questarea_buildings"},
    -- TODO: Price
    price = {},
    -- TODO: Action
    action = function() end
})
definePOI("boss", "Challenges", {
    x = 399, y = 183, w = 80, h = 70,
    highlight = {"bossarea_statue"},
    -- TODO: Price
    price = {},
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


function map:init()
    self.allowMousePan = false

    prop(302,215,"happy_cat")
end





-- Clamps camera position and zoom to stay within map bounds
---@param camera Camera instance
---@param mapX number 
---@param mapY number
---@param mapW number
---@param mapH number
local function clampCameraToMap2(camera, mapX, mapY, mapW, mapH)
    -- Adjust viewport and set position to center of map.
    local w, h = love.graphics.getDimensions()
    camera:setViewport(0, 0, w, h, 0.5, 0.5)
    camera:setPos(mapX + mapW / 2, mapY + mapH / 2)

    -- Adjust zooming
    local scale = math.min(w / mapW, h / mapH)
    -- Only allow integer scaling with minimum of 1
    scale = math.max(math.floor(scale), 1)
    camera:setZoom(scale)
end



---@param r layout.Region
---@param cam Camera
local function drawPOITooltip(r, cam, poi)
    local TOOLTIP_PADDING = 4
    local SCREEN_PADDING = 4

    local titleFont = g.getBigFont(32)
    local font = g.getSmallFont(16)
    local hasBought = unlockedPOIs:has(poi.type)
    local canAfford = hasBought or g.canAfford(poi.price)

    -- Calculate box width and height
    local height = titleFont:getHeight()
    local width = titleFont:getWidth(richtext.stripEffects(poi.name))
    local buyText = ""
    if not hasBought then
        local buyTextWidth = 0

        if canAfford then
            buyText = "Buy"
        end

        for _, resId in ipairs(g.RESOURCE_LIST) do
            if poi.price[resId] then
                local resInfo = g.getResourceInfo(resId)
                buyText = buyText.." {"..resInfo.image.."}"..poi.price[resId]
                buyTextWidth = buyTextWidth + 16
            end
        end

        buyTextWidth = buyTextWidth + font:getWidth(richtext.stripEffects(buyText))
        width = math.max(width, buyTextWidth)
        height = height + font:getHeight()
    end

    -- Compute regions
    local tx, ty = ui.getUIScalingTransform():inverseTransformPoint(cam:toScreen(poi.x + poi.w / 2, poi.y + poi.h))
    local tooltipR = Kirigami(tx - width / 2, ty + 16, width, height)
        -- Apply padding
        :padUnit(-TOOLTIP_PADDING)
        -- Clamp
        :clampInside(r:padUnit(SCREEN_PADDING))
    local tooltipContentR = tooltipR:padUnit(TOOLTIP_PADDING)

    -- Draw it
    if canAfford then
        love.graphics.setColor(0.2, 0.2, 0.4, 0.8)
    else
        love.graphics.setColor(0.4, 0.2, 0.2, 0.8)
    end
    love.graphics.rectangle("fill", tooltipR:get())

    love.graphics.setColor(0.,0.,0.08)
    love.graphics.rectangle("line", tooltipR:get())

    love.graphics.setColor(1, 1, 1)
    richtext.printRich(poi.name, titleFont, tooltipContentR.x, tooltipContentR.y, tooltipContentR.w, "center")
    if not hasBought then
        richtext.printRich(buyText, font, tooltipContentR.x, tooltipContentR.y + titleFont:getHeight(), tooltipContentR.w, "center")
    end
end


function map:draw()
    lg.clear(MAP_BACKGROUND)

    local mapW,mapH = mapAnim[1]:getDimensions()
    clampCameraToMap2(self.camera,0,0,mapW,mapH)
    self:setCamera()

    lg.setColor(1,1,1)
    local t = love.timer.getTime()
    local i = (math.floor(t) % #mapAnim) + 1
    lg.draw(mapAnim[i],0,0)

    for _,p in ipairs(props) do
        g.drawImage(p.image,p.x,p.y)
    end

    -- POI outline, tooltip, and action.
    local hoveredPOI = nil
    for _, poi in pairs(POI) do
        local hasBought = unlockedPOIs:has(poi.type)

        if iml.isHovered(poi.x, poi.y, poi.w, poi.h) then
            hoveredPOI = poi

            if hasBought then
                local a = math.sin((t % 1) * math.pi) ^ 2
                lg.setColor(1, 1, 1, a)

                for _, buildingId in ipairs(poi.highlight) do
                    local b = buildings[buildingId]
                    -- Buildings are relative to top right
                    g.drawImageOffset(b.image.."_outline", b.x + 2, b.y - 2, 0, 1, 1, 1, 0)
                end
            end
        end

        if iml.wasJustClicked(poi.x, poi.y, poi.w, poi.h, 1) then
            local canAfford = hasBought or g.canAfford(poi.price)

            if hasBought then
                poi.action()
            elseif canAfford then
                g.subtractResources(poi.price)
                unlockedPOIs:add(poi.type)
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
            local offsetStartBase = (cloud.seed * 214013 + 2531011) % 65536
            local frequencyBase = (offsetStartBase * 214013 + 2531011) % 65536
            local offset = (offsetStartBase / 65536) * 2 * math.pi
            -- Tweak these values to tune the bobbing speed
            local frequency = 0.1 + (frequencyBase / 65536) * 0.3

            local yoff = math.sin(2 * math.pi * frequency * t + offset)
            g.drawImageOffset(cloud.image, cloud.x, cloud.y + yoff, 0, 1, 1, 0, 0)
        end
    end

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    self:renderNavbar()
    if hoveredPOI then
        local r = Kirigami(0, 0, ui.getScaledUIDimensions())
        drawPOITooltip(r, self.camera, hoveredPOI)
    end
    ui.endUI()
end




function map:update(dt)
    self:updateCamera(dt)
end



function map.wheelmoved() end -- disable zooming
map.mousemoved = map.defaultMousemoved
map.keyreleased = map.defaultKeyreleased




return map

