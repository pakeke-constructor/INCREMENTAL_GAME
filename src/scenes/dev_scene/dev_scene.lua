local FreeCameraScene = require("src.scenes.FreeCameraScene")

---@class DevScene: FreeCameraScene
local dev = FreeCameraScene()

function dev:init()
end

function dev:draw()
    local COL = objects.Color("#FF00A2E8")
    love.graphics.clear(COL)

    self:setCamera()

    self:resetCamera()

    ui.startUI()
    self:renderNavbar()
    ui.endUI()
end

function dev:update(dt)
    self:updateCamera(dt)
end

return dev
