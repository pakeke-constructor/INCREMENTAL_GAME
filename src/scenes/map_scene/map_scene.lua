

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")

local lg = love.graphics


---@class MapScene: FreeCameraScene
local map = FreeCameraScene()







local mapAnim = {
    lg.newImage("src/scenes/map_scene/maps/new_map1.png"),
    lg.newImage("src/scenes/map_scene/maps/new_map2.png"),
    -- lg.newImage("src/scenes/map_scene/maps/map1.png"),
    -- lg.newImage("src/scenes/map_scene/maps/map2.png")
}

local cloudImg = lg.newImage("src/scenes/map_scene/maps/new_map_clouds.png")



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
local GLOBAL_SCALE_INCREMENT = 0.25
local globalScaleTransform = love.math.newTransform()
local globalScale = 1
local gw, gh = 800, 600

local function getZoom()
	local w, h = lg.getDimensions()
	if w ~= gw or h ~= gh then
		local wscale = w / 600
		local hscale = h / 400
		local scale = math.min(wscale, hscale)
		local gscale = math.floor(scale / GLOBAL_SCALE_INCREMENT + 0.5) * GLOBAL_SCALE_INCREMENT
		globalScale = math.max(gscale, 1)
		globalScaleTransform:reset():scale(globalScale)
		gw = w
		gh = h
	end
end


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
    local ww,hh = love.graphics.getDimensions()
    camera:setZoom(math.floor(10*(ww+hh)/600)/10)
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

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    self:renderNavbar()
    -- self:renderMap()
    ui.endUI()
end




function map:update(dt)
    self:updateCamera(dt)
end



function map:keypressed(k)
end



function map:mousepressed(x,y, button)
end

function map:mousereleased(x,y, button)
end



return map

