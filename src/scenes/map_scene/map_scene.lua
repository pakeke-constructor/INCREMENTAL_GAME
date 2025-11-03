

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")

local lg = love.graphics


---@class MapScene: FreeCameraScene
local map = FreeCameraScene()



local POI = {}
local unlockedPOIs = objects.Set()
local POI_CLICK_RADIUS = 8
local function definePOI(id, name, def)
    def.type = id
    def.name = name
    POI[id] = def
end

definePOI("fishing", "Fishing", {
    x = 593, y = 91,
    price = {money = 5000, logs = 100},
    action = function()
        g.gotoScene("fishing_scene")
    end
})



local mapAnim = {
    lg.newImage("src/scenes/map_scene/maps/new_map1.png"),
    lg.newImage("src/scenes/map_scene/maps/new_map2.png"),
    -- lg.newImage("src/scenes/map_scene/maps/map1.png"),
    -- lg.newImage("src/scenes/map_scene/maps/map2.png")
}


local cloudImg = lg.newImage("src/scenes/map_scene/maps/new_map_clouds.png")

local WASD = lg.newImage("src/scenes/map_scene/maps/wasd_image.png")



local props = {}


local function prop(x,y,img)
    table.insert(props, {
        x=x,y=y,
        image=img
    })
end


function map:init()
    local w,h = mapAnim[1]:getDimensions()
    self.camera:setPos(w/2,h/2-200)

    prop(300,150,"happy_cat")
end



local clampCameraToMap
do


-- Clamps camera position and zoom to stay within map bounds
---@param camera Camera instance
---@param mapX number 
---@param mapY number
---@param mapW number
---@param mapH number
function clampCameraToMap(camera, mapX, mapY, mapW, mapH)
    -- Get viewport dimensions from camera if not provided
    local vpx, vpy, vpw, vph = camera:getViewport()
    local viewportWidth = vpw or lg.getWidth()
    local viewportHeight = vph or lg.getHeight()

    local zoom = camera:getZoom()
    local x, y = camera:getPos()

    local visibleWidth = viewportWidth / zoom
    local visibleHeight = viewportHeight / zoom

    -- Clamp X position
    if visibleWidth >= mapW then
        x = mapX + mapW / 2
    else
        local minX = mapX + visibleWidth / 2
        local maxX = mapX + mapW - visibleWidth / 2
        x = math.max(minX, math.min(maxX, x))
    end

    -- Clamp Y position
    if visibleHeight >= mapH then
        y = mapY + mapH / 2
    else
        local minY = mapY + visibleHeight / 2
        local maxY = mapY + mapH - visibleHeight / 2
        y = math.max(minY, math.min(maxY, y))
    end

    -- Optional: Clamp zoom to ensure map always fills viewport
    local minZoomX = viewportWidth / mapW
    local minZoomY = viewportHeight / mapH
    local minZoom = math.max(minZoomX, minZoomY)

    if zoom < minZoom then
        zoom = minZoom
    end

    -- Apply clamped values back to camera
    camera:setPos(x, y)

    -- HACK: Scale with respect to dimensions
    local ww,hh = lg.getDimensions()
    camera:setZoom(math.floor(10*(ww+hh)/600)/10)
end

end



local function drawWASDVisual()
    local x=10
    local y=10
    lg.push()
    lg.scale(1.5)
    love.graphics.setColor(0.3,0.3,0.4)
    lg.draw(WASD, x+2, y)
    lg.draw(WASD, x+2, y+2)
    lg.draw(WASD, x, y+2)
    lg.setColor(0,0,0)
    for dx=-1,1,2 do
        for dy=-1,1,2 do
            lg.draw(WASD, x+dx, y+dy)
        end
    end
    lg.setColor(1,1,1)
    lg.draw(WASD,x,y)
    lg.pop()
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
    local tx, ty = ui.getUIScalingTransform():inverseTransformPoint(cam:toScreen(poi.x, poi.y))
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

    -- Action area
    local poid = POI_CLICK_RADIUS * 2
    if iml.wasJustClicked(tx - POI_CLICK_RADIUS, ty - POI_CLICK_RADIUS, poid, poid) then
        if hasBought then
            poi.action()
        elseif canAfford then
            g.subtractResources(poi.price)
            unlockedPOIs:add(poi.type)
        end
    end
end


function map:draw()
    local COL = objects.Color("#FF2080D8")
    lg.clear(COL)

    local mapW,mapH = mapAnim[1]:getDimensions()
    clampCameraToMap(self.camera,0,0,mapW,mapH)
    self:setCamera()

    lg.setColor(1,1,1)
    local t = love.timer.getTime()
    local i = (math.floor(t) % 2) + 1
    lg.draw(mapAnim[i],0,0)

    local cloudW = cloudImg:getDimensions()
    lg.draw(cloudImg, (mapW-cloudW)/2 + math.sin(t/4)*10,0)

    for _,p in ipairs(props) do
        g.drawImage(p.image,p.x,p.y)
    end

    local mwx, mwy = self.camera:toWorld(ui.getUIScalingTransform():transformPoint(ui.getMouse()))
    local hoveredPOI = nil
    for _, poi in pairs(POI) do
        -- TODO: Use better icon?
        love.graphics.circle("fill", poi.x, poi.y, POI_CLICK_RADIUS)

        if helper.magnitude(mwx - poi.x, mwy - poi.y) <= POI_CLICK_RADIUS then
            hoveredPOI = poi
        end
    end

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    self:renderNavbar()
    drawWASDVisual()
    if hoveredPOI then
        local r = Kirigami(0, 0, ui.getScaledUIDimensions())
        drawPOITooltip(r, self.camera, hoveredPOI)
    end
    ui.endUI()
end




function map:update(dt)
    self:updateCamera(dt)
end



map.wheelmoved = map.defaultWheelmoved
map.mousemoved = map.defaultMousemoved
map.keyreleased = map.defaultKeyreleased




return map

