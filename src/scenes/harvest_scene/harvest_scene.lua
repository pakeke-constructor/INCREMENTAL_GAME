

local FreeCameraScene = require("src.scenes.FreeCameraScene")

---@class HarvestScene: FreeCameraScene
local harvest = FreeCameraScene()



function harvest:init()
    self.camera:setPos(100,100)
    -- TODO: do this properly
end



function harvest:draw()
    self:setCamera()
    local header, body = Kirigami(0,0,love.graphics.getDimensions()):splitVertical(1,5)

    love.graphics.clear(0.3,0.7,0.25)
    love.graphics.setColor(1,1,1)

    local world = g.getMainWorld()

    local cx,cy = self.camera:toWorld(love.mouse.getPosition())
    world:_enableMouseHarvester(cx,cy)

    world:_draw()

    self:resetCamera()

    self:renderNavbar()
end


function harvest:update(dt)
    self:updateCamera(dt)

    local sn = g.getSn()
    sn:_updateMainWorld(dt)

    local mx,my = love.mouse.getPosition()

end


return harvest

