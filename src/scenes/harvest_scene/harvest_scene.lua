

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local world = require("src.world.world")

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

    local cx,cy = self.camera:toWorld(love.mouse.getPosition())
    world.setMouseHarvester(cx,cy)

    world.draw()

    self:resetCamera()

    self:renderNavbar()
end


function harvest:update(dt)
    self:updateCamera(dt)

    local mx,my = love.mouse.getPosition()

end


return harvest

