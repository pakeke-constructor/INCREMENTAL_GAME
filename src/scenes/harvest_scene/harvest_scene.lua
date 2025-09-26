

local FreeCameraScene = require("src.scenes.FreeCameraScene")

---@class HarvestScene: FreeCameraScene
local harvest = FreeCameraScene()



function harvest:init()
    self.allowMousePan = false
end



---@param self HarvestScene
local function centerCamera(self)
    local world = g.getMainWorld()
    local cx = world.WIDTH / 2
    local cy = world.HEIGHT / 2
    self.camera:setPos(cx, cy)
    self:setCamera()
end



function harvest:draw()
    centerCamera(self)

    love.graphics.clear(0.3,0.7,0.25)
    love.graphics.setColor(1,1,1)

    local world = g.getMainWorld()

    local cx,cy = self.camera:toWorld(love.mouse.getPosition())
    world:_enableMouseHarvester(cx,cy)

    world:_draw()

    self:resetCamera()

    ui.startUI()
    self:renderNavbar()

    g.getHUD():draw(self.camera)
    ui.endUI()
end


function harvest:update(dt)
    self:updateCamera(dt)
    g.getHUD():update(dt)

    local sn = g.getSn()
    sn:_updateMainWorld(dt)
end



return harvest

