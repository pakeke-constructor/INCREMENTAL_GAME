

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")

---@class FishingScene: FreeCameraScene
local fishing = FreeCameraScene()

function fishing:init()
    self.allowMousePan = false
end

---@param dt number
function fishing:update(dt)
end

function fishing:draw()
    love.graphics.clear(0, 0.64, 0.91, 1)
    love.graphics.setColor(1,1,1)

    vignette.draw()
end

fishing.keyreleased = fishing.defaultKeyreleased

return fishing
