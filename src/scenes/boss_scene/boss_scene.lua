
local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")
local newLightWorld = require("src.modules.lighting.lighting")


---@class BossScene: FreeCameraScene
local boss = FreeCameraScene()

local STATUE_X, STATUE_Y = 536, 188
local DOOR_X, DOOR_Y = 90, 192

local lightDefs = {
    {x=120, y=300, size=400},
    {x=500, y=288, size=700},
    {x=300, y=300, size=400},
}

local AMBIENT_LIGHT = {0,0,0.1}


---@param self BossScene
local function refreshLights(self, scale)
    self.lightWorld:resize()
    self.lightWorld:clear()
    for _, def in ipairs(lightDefs) do
        self.lightWorld:addLight(def.x*scale, def.y*scale, def.size*scale)
    end
    local w,h = love.graphics.getDimensions()
    self.lightWorld:addLight(w*0.95, h*0.1, 700)
end


function boss:init()
    self.background = lg.newImage("src/scenes/boss_scene/challengeroom.png")
    self.statue = lg.newImage("src/scenes/boss_scene/challengeroom_statue.png")
    self.door = lg.newImage("src/scenes/boss_scene/challengeroom_hallway.png")

    self.button = lg.newImage("src/scenes/boss_scene/challengeroom_button.png")

    self.lightWorld = newLightWorld()
end

---@param dt number
function boss:update(dt)
end


local SUMMON_BOSS = loc("{o}{c r=1, g=0.5 b=0.3}Summon Boss?{/c}{/o}", {}, {
    context = "As in, voluntarily starting a boss-fight in a videogame"
})

local BOSS_INFO = loc("{o}{c r=1, g=0.5 b=0.3}(All upgrades will be reset!){/c}{/o}", {}, {
    context = "Information about what happens when you summon/beat the boss, saying that upgrades will be reset as part of a 'prestige' system."
})



local function drawBossButtonStuff(self)
    local uiw,uih = ui.getScaledUIDimensions()

    -- boss-button
    local bw,bh = self.button:getDimensions()
    local bob = math.floor(math.sin(love.timer.getTime() * 2) * 2)
    local r = Kirigami(uiw/2-bw/2, bob + uih*0.8-bh/2, bw,bh)
    if iml.isHovered(r:get()) then
        lg.setColor(0.8,0.8,0.9)
    else
        lg.setColor(1,1,1)
    end
    lg.draw(self.button, r.x, r.y)
    local prestige = g.getPrestige()
    local bossId = g.getBossIdForPrestige(prestige)
    if bossId and iml.wasJustClicked(r:get()) then
        g.gotoSceneViaMap("harvest_scene")
        g.summonBoss(bossId)
    end
end


---@param self BossScene
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
    refreshLights(self, scale)

    love.graphics.draw(self.background, x, y, 0, scale, scale)

    do
    local s = math.sin(love.timer.getTime()*3)/40
    local sc = 1 + s
    local dy = self.statue:getHeight() * (s) * scale
    love.graphics.draw(self.statue, x + STATUE_X * scale, y + STATUE_Y * scale - dy, 0, scale, scale*sc)
    end
    love.graphics.draw(self.door, x + DOOR_X * scale, y + DOOR_Y * scale, 0, scale, scale)

    ui.startUI()
    --g.getHUD():draw({profile = false, xpbar = false})
    drawBossButtonStuff(self)
    self:renderPause()
    self:renderMapButton()
    ui.endUI()

    self.lightWorld:render(AMBIENT_LIGHT)


end

function boss:wheelmoved(dx, dy)
end



function boss:keyreleased(k)
end

return boss
