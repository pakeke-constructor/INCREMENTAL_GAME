local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")


---@class CustomizationScene: FreeCameraScene
local custom = FreeCameraScene()


function custom:init()
    self.allowMousePan = false
    self.background = helper.newGradientMesh(
        "vertical",
        objects.Color("#".."FF750058"),
        objects.Color("#".."FF174A98")
    )
end

---@param dt number
function custom:update(dt)
    g.getHUD():update(dt)
end

function custom:draw()
    local w, h = love.graphics.getDimensions()

    -- Draw background
    love.graphics.draw(self.background, 0, 0, 0, w, h)

    -- Draw vignette
    vignette.draw()

    -- Draw UI
    ui.startUI()
    self:renderMapButton()
    g.getHUD():draw({profile = false, xpbar = false})
    ui.endUI()
end

return custom
