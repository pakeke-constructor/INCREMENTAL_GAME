local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")



---@class BossScene: FreeCameraScene
local boss = FreeCameraScene()


local STATUE_X, STATUE_Y = 536, 188
local DOOR_X, DOOR_Y = 90, 192

local lights = {
    {x=100, y=100, size=2},
    {x=200, y=300, size=3}
}


function boss:init()
    self.background = lg.newImage("src/scenes/boss_scene/challengeroom.png")
    self.statue = lg.newImage("src/scenes/boss_scene/challengeroom_statue.png")
    self.door = lg.newImage("src/scenes/boss_scene/challengeroom_hallway.png")
end




---@param dt number
function boss:update(dt)
    g.getHUD():update(dt)
end

function boss:draw()
    local w, h = love.graphics.getDimensions()
    local r = ui.getScreenRegion()

    vignette.draw()

    local iw, ih = self.background:getDimensions()
    local scaleX = w / iw
    local scaleY = h / ih
    local scale = math.max(scaleX, scaleY)
    local scaledW = iw * scale
    local scaledH = ih * scale
    local x = (w - scaledW) / 2
    local y = (h - scaledH) / 2

    love.graphics.draw(self.background, x, y, 0, scale, scale)
    
    love.graphics.draw(self.statue, x + STATUE_X * scale, y + STATUE_Y * scale, 0, scale, scale)
    love.graphics.draw(self.door, x + DOOR_X * scale, y + DOOR_Y * scale, 0, scale, scale)


    ui.startUI()
    --g.getHUD():draw({profile = false, xpbar = false})
    self:renderPause()
    self:renderMapButton()
    ui.endUI()
end



function boss:wheelmoved(dx, dy)
end


function boss:keyreleased(k)
end



return boss
