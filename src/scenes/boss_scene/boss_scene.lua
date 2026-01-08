

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")



---@class BossScene: FreeCameraScene
local boss = FreeCameraScene()


function boss:init()
    self.background = lg.newImage("src/scenes/boss_scene/boss_cave.png")
end




---@param dt number
function boss:update(dt)
    g.getHUD():update(dt)
end

function boss:draw()
    local w, h = love.graphics.getDimensions()
    local r = ui.getScreenRegion()

    -- Draw vignette
    vignette.draw()

    -- Draw UI
    ui.startUI()

    -- Draw cave background
    local iw,ih = self.background:getDimensions()
    local sc = math.min(r.w/iw, r.h/ih)
    love.graphics.draw(self.background, 40, 0, 0, sc,sc)

    local mapButtonR = self:renderMapButton()

    g.getHUD():draw({profile = false, xpbar = false})
    self:renderPause()
    ui.endUI()
end



function boss:wheelmoved(dx, dy)
end


function boss:keyreleased(k)
end



return boss

