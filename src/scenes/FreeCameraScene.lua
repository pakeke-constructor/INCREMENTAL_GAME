
---@class FreeCameraScene
---@field camera Camera
---@field panSpeed number
local FreeCameraScene = {}
local FreeCameraScene_mt = {
    __index = FreeCameraScene,
    __newindex = function(t,k,v)
        assert(not FreeCameraScene[k], "Attempted to overwrite method!")
        rawset(t,k,v)
    end
}


FreeCameraScene.panSpeed = 300
FreeCameraScene._isCamAttached = false



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



---@param dt number
function FreeCameraScene:updateCamera(dt)
    local camera = self.camera
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


local function zoom(x, k)
    k = k or 1.0  -- growth/decay rate
    return math.exp(k * x)
end


function FreeCameraScene:wheelmoved(dx,dy)
    self._zoomIndex = self._zoomIndex + dy/5
    self.camera:setZoom(zoom(self._zoomIndex, 1))
    print(self._zoomIndex, self.camera:getZoom())
end




local function newFreeCameraScene()
    local scene = setmetatable({
        camera = Camera(),
        _isCamAttached = false,
        _zoomIndex = 0
    }, FreeCameraScene_mt)

    return scene
end


return newFreeCameraScene


