
--[[

===============================================================
===============================================================

FreeCameraScene

A base-class for a Scene with a free-moving camera.
Contains a bunch of lil helpers n stuff

===============================================================
===============================================================

]]


---@class FreeCameraScene
---@field camera Camera
---@field panSpeed number
local FreeCameraScene = {}
local FreeCameraScene_mt = {
    __index = FreeCameraScene,
    __newindex = function(t,k,v)
        assert(type(FreeCameraScene[k]) ~= "function", "Attempted to overwrite method!")
        rawset(t,k,v)
    end
}


FreeCameraScene.panSpeed = 300
FreeCameraScene._isCamAttached = false
FreeCameraScene.allowMousePan = true


local Camera = require("lib.cam11")



function FreeCameraScene:setCamera()
    self:resetCamera()
    self.camera:attach()
    self._isCamAttached = true
    iml.pushTransform(self.camera:getTransform())
end


function FreeCameraScene:resetCamera()
    if self._isCamAttached then
        self._isCamAttached = false
        self.camera:detach()
        iml.popTransform()
    end
end




function FreeCameraScene:renderMapButton()
    local r = Kirigami(0,0,ui.getScaledUIDimensions())
    local header,_ = r:splitVertical(1,6)

    local left, right = header:splitHorizontal(1,1)
    right = right:padRatio(0.5,0.2,0.5,0.3)

    local MAIN=objects.Color.WHITE
    local BASE=objects.Color.GRAY
    -- TEMPORARY CODE
    if ui.Button("{o}MAP", MAIN,BASE, right:get()) then
        g.playUISound("ui_mouse_click", 1, 0.6, 0.1)
        g.gotoScene("map_scene")
    end
end





---@param dt number
function FreeCameraScene:updateCamera(dt)
    local camera = self.camera
    camera:setViewport(0, 0, love.graphics.getDimensions())

    local spd = self.panSpeed / math.sqrt(camera:getZoom())
    local movX,movY = 0,0
    if love.keyboard.isScancodeDown("w") then
        movY = movY - spd*dt
    end
    if love.keyboard.isScancodeDown("a") then
        movX = movX - spd*dt
    end
    if love.keyboard.isScancodeDown("s") then
        movY = movY + spd*dt
    end
    if love.keyboard.isScancodeDown("d") then
        movX = movX + spd*dt
    end
    local x,y = camera:getPos()
    camera:setPos(x+movX,y+movY)
end


---@param x number
function FreeCameraScene:scaleFromZoom(x)
    return math.exp(x)
end

---@param x number
function FreeCameraScene:zoomFromScale(x)
    return math.log(x)
end

---@param z number
function FreeCameraScene:setZoom(z)
    self._zoomIndex = z
    self.camera:setZoom(self:scaleFromZoom(self._zoomIndex))
end



---@param x number
---@param y number
---@param dx number
---@param dy number
function FreeCameraScene:defaultMousemoved(x, y, dx, dy)
    if self.allowMousePan and love.mouse.isDown(2, 3) then
        local cx, cy = self.camera:getPos() --[[@as number]]
        local z = self:scaleFromZoom(self._zoomIndex)

        self.camera:setPos(cx - dx / z, cy - dy / z)
    end
end



function FreeCameraScene:defaultWheelmoved(dx,dy)
    return self:setZoom(self._zoomIndex + dy/5)
end



function FreeCameraScene:defaultKeyreleased(k)
    if consts.DEV_MODE then
        if k == "f1" then
            g.gotoScene("dev_scene")
        elseif k == "f2" then
            -- TODO: Remove this once fishing are is accessible through map.
            g.gotoScene("fishing_scene")
        elseif k == "f3" then
            -- TODO: Remove this. This is only temporary.
            g.gotoScene("customization_scene")
        end
    end
end



local function newFreeCameraScene()
    local scene = setmetatable({
        camera = Camera(),
        _isCamAttached = false,
        _zoomIndex = 0,
        allowMousePan = true,
    }, FreeCameraScene_mt)
    scene.camera:setViewport(0, 0, love.graphics.getDimensions())

    return scene
end


return newFreeCameraScene


