

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
    local header, body = Kirigami(0,0,love.graphics.getDimensions()):splitVertical(1,5)

    love.graphics.clear(0.3,0.7,0.25)
    love.graphics.setColor(1,1,1)

    local world = g.getMainWorld()

    local cx,cy = self.camera:toWorld(love.mouse.getPosition())
    world:_enableMouseHarvester(cx,cy)

    world:_draw()

    self:resetCamera()

    self:renderNavbar()

    self:renderResource()
end


function harvest:update(dt)
    self:updateCamera(dt)

    local sn = g.getSn()
    sn:_updateMainWorld(dt)

    local mx,my = love.mouse.getPosition()

end



return harvest

