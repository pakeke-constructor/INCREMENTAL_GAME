
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


local SUMMON_BOSS = "{o}{c r=1 g=0.5 b=0.3}"..loc("Summon Boss?", {}, {
    context = "As in, voluntarily starting a boss-fight in a videogame"
}).."{/c}{/o}"

local BOSS_INFO = "{o}{c r=0.8 g=0.9 b=0.8}"..loc("(All upgrades will be reset!)", {}, {
    context = "Information about what happens when you summon/beat the boss, saying that upgrades will be reset as part of a 'prestige' system."
}).."{/c}{/o}"

local BOSS_COST_MONEY = 800000


---@param self BossScene
---@param bob integer
local function drawBossButtonStuff(self, bob)
    local uiw,uih = ui.getScaledUIDimensions()

    -- boss-button
    local bw,bh = self.button:getDimensions()
    local r = Kirigami(uiw/2-bw/2, bob + uih*0.8-bh/2, bw,bh)

    lg.setColor(0,0,0)
    lg.draw(self.button, r.x-2, r.y-2)
    lg.draw(self.button, r.x+2, r.y+2)
    lg.draw(self.button, r.x-2, r.y+2)
    lg.draw(self.button, r.x+2, r.y-2)

    if iml.isHovered(r:get()) then
        lg.setColor(0.6,0.6,0.7)
    else
        lg.setColor(1,1,1)
    end
    lg.draw(self.button, r.x, r.y)

    local canAfford = g.canAfford({money = BOSS_COST_MONEY})
    local buttonText
    if canAfford then
        local temp = g.formatNumber(BOSS_COST_MONEY)
        buttonText = "{CAN_AFFORD}"..temp.."/"..temp.."{/CAN_AFFORD}"
    else
        buttonText = "{CANT_AFFORD}"..g.formatNumber(g.getResource("money")).."/"..g.formatNumber(BOSS_COST_MONEY).."{/CANT_AFFORD}"
    end
    richtext.printRichContainedNoWrap("{money scale=1.5} {o}"..buttonText.."{/o}", g.getSmallFont(32), r:padUnit(10):get())

    local prestige = g.getPrestige()
    local bossId = g.getBossIdForPrestige(prestige)
    if bossId and iml.wasJustClicked(r:get()) and g.canAfford({money = BOSS_COST_MONEY}) then
        g.subtractResources({money = BOSS_COST_MONEY})
        g.gotoSceneViaMap("harvest_scene")
        g.summonBoss(bossId)
    end
end

---@param r kirigami.Region
---@param tokInfo g.TokenInfo
local function drawBoss(r, tokInfo)
    local px, py = r:getCenter()
    g.drawImage(tokInfo.image, px, py, 0, 2, 2)

    if tokInfo.type == "giantcrab_boss" then
        local t = love.timer.getTime() / 3
        local rotleft = math.sin(t * 2 * math.pi) * 0.4
        local rotright = math.cos(t * 2 * math.pi) * 0.4
        g.drawImageOffset("giantcrab_claw", px + 64, py + 38, rotright, 2, 2, 0.6, 0.2)
        g.drawImageOffset("giantcrab_claw", px - 64, py + 38, rotleft, -2, 2, 0.6, 0.2)
    elseif tokInfo.type == "crystalcrab_boss" then
        local t = love.timer.getTime() / 3
        local rotleft = math.sin(t * 2 * math.pi) * 0.4
        local rotright = math.cos(t * 2 * math.pi) * 0.4
        g.drawImageOffset("crystalcrab_claw", px + 64, py + 38, rotright, 2, 2, 0.6, 0.2)
        g.drawImageOffset("crystalcrab_claw", px - 64, py + 38, rotleft, -2, 2, 0.6, 0.2)
    elseif tokInfo.type == "vacuum_boss" then
        local t = love.timer.getTime() / 2
        local sin1 = math.sin(t * math.pi * 2)
        local sin2 = math.sin(t * math.pi)
        local sin3 = sin1 * sin2
        local eyedir = sin3 > 0 and math.floor(sin3 + 0.5) or math.ceil(sin3 - 0.5)
        g.drawImage("vacuum_eye", px - 18 + eyedir * 10, py - 8, 0, 2, 2)
        g.drawImage("vacuum_eye", px + 18 + eyedir * 10, py - 8, 0, -2, 2)
    end
end

function boss:draw()
    local w, h = love.graphics.getDimensions()

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

    self.lightWorld:render(AMBIENT_LIGHT)

    ui.startUI()
    local bob = math.floor(math.sin(love.timer.getTime() * 2) * 2)
    drawBossButtonStuff(self, bob)

    do
    local f = g.getSmallFont(16)
    local r2 = ui.getFullScreenRegion()
        :padRatio(0.6,0,0.6,0)
        :moveUnit(0,bob)
    local pumpkin,a,b,_ = r2:splitVertical(3,1,1,2)
    local bossId = assert(g.getBossIdForPrestige(g.getPrestige()))
    love.graphics.setColor(1, 1, 1)
    drawBoss(pumpkin, g.getTokenInfo(bossId))
    richtext.printRichContained(SUMMON_BOSS, f, a:get())
    richtext.printRichContained(BOSS_INFO, f, b:get())
    end

    self:renderMapButton()
    self:renderPause()

    ui.endUI()
end

function boss:wheelmoved(dx, dy)
end



function boss:keyreleased(k)
    if k == "escape" and g.hasSession() then
        local s = g.getSn()
        s.paused = not s.paused
    end
end

return boss
