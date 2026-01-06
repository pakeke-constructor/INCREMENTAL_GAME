
local lg=love.graphics

local particles = require("src.modules.particles.particles")
local cloudService = require(".cloud_service")

local rewards = require("src.rewards.rewards")


local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")

---@class HarvestScene: FreeCameraScene
local harvest = FreeCameraScene()


local XP_POPUP_FADE_IN_TIME = 0.25
-- How many seconds it takes to fade into the popup

local UPGRADE_POPUP_FADE_IN_TIME = 0.25
-- How many seconds it takes to fade into the popup


local CLOSE = loc("{o}CLOSE{/o}",{}, {
    context = "As in a back/close button in UI, going back to what the player was doing just before this popup"
})

local GOTO_UPGRADES = loc("{o}{rainbow}GO TO UPGRADES!{/rainbow}{/o}",{}, {
    context = "Going to the 'upgrades' screen to buy new upgrades. Meant to be exciting, concise, and clear. Pressing this button will cause the player to move to new upgrades."
})

--local NEW_UPGRADES_AVAILABLE = loc("{wavy freq=0.5}{rainbow}{outline}New Upgrades Available!{/outline}{/rainbow}{/wavy}",{}, {
local NEW_UPGRADES_AVAILABLE = loc("{outline}New Upgrades Available!{/outline}",{}, {
    context = "Going to the 'upgrades' screen to buy new upgrades. Meant to be exciting, concise, and clear. Pressing this button will cause the player to move to new upgrades."
})

local TUTORIAL_HARVEST = "{w}{o thickness=2}"..loc("Hover your mouse over {c r=1 g=0 b=0}crops{/c} to harvest them!").."{/o}{/w}"


local STORAGE_FULL_TEXT = loc("Your storage is full!", {}, {
    context = "For example, the player can only store 1000 gold, or 500 logs maximum, and they have reached that limit"
})

local STORAGE_GOTO_UPGRADES = loc("Go to upgrades ->", {}, {
    context = "Button that is prompting the player to go to the upgrade-tree"
})





function harvest:init()
    self.allowMousePan = false

    self.timeTakenThisLevel = 0
    self.xpRequirement = 1 -- set every frame.

    self.timeSinceXpPopupOpened = 0
    self.xpPopup = false
    self.xpRewards = {}

    self.timeSinceBossPopupOpened = 0
    self.bossPopup = false

    self.timeSinceUpgradePopupOpened = 0
    self.upgradePopup = false

    self.stackedTokenX = 0
    self.stackedTokenY = 0
    self.stackedTokenLerpTime = -1

    -- This background is not part of the texture atlas so it needs to be loaded manually
    self.background = love.graphics.newImage("src/scenes/harvest_scene/background_harvest.png")

    self.worldScale = 1
end



---@param self HarvestScene
local function centerCamera(self)
    local worldW, worldH = g.getWorldDimensions()
    local cx = worldW / 2
    local cy = worldH / 2
    self.camera:setPos(cx, cy)
    self:setCamera()
end


local function getStackLerpTime()
    local count = math.max(#g.getSn().tokenQueue, 1)
    return math.max(0.7 / math.sqrt(count), 0.07) -- minimum 70ms
end

function harvest:_resetStackTokenAnim()
    self.stackedTokenLerpTime = 0

    local x, y = g.getRandomPositionForToken()
    if not (x and y) then
        -- Just fallback to any random pos
        local worldW, worldH = g.getWorldDimensions()
        x = helper.lerp(8, worldW - 8, love.math.random())
        y = helper.lerp(8, worldH - 8, love.math.random())
    end
    self.stackedTokenX = x
    self.stackedTokenY = y
end

function harvest:_drawTokenStackAnim()
    local stkTok = g.peekStackedToken()
    if stkTok then
        local tqx, tqy = g.getHUD().profileHUD:getStackTokenPos() -- in "scaled screen" space
        local tqsx, tqsy = ui.getUIScalingTransform():transformPoint(tqx, tqy) -- in screen space (actual window)
        local tqwx, tqwy = self.camera:toWorld(tqsx, tqsy) -- in world space (token pos)
        local t = math.min(self.stackedTokenLerpTime / getStackLerpTime(), 1)
        local et = helper.EASINGS.sineInOut(t)
        local x = helper.lerp(tqwx, self.stackedTokenX, et)
        local y = helper.lerp(tqwy, self.stackedTokenY, et)

        g.drawImage(stkTok, x, y)
    end
end


local EFFECT_COLORS = {
    -- boolean is for isDebuff
    [true] = {
        BG = objects.Color("#".."FF592404"),
        FG = objects.Color("#".."FFcF280E"),
    },
    [false] = {
        BG = objects.Color("#".."FF1C4A1C"),
        FG = objects.Color("#".."FF75D963"),
    },
}

function harvest:_drawActiveEffects()
    local r = ui.getScreenRegion()
    local effectIconR = Kirigami(0, 96, 24, 24)
        :attachToRightOf(r)
        :moveRatio(-1, 0)
        :moveUnit(-8, 0)

    local font = g.getSmallFont(16)
    local tooltipDrawn = nil
    for eff, duration in g.getMainWorld():_iterateActiveEffects() do
        local effInfo = g.getEffectInfo(eff)
        local bgcolor = EFFECT_COLORS[effInfo.isDebuff].BG
        local fgcolor = EFFECT_COLORS[effInfo.isDebuff].FG

        -- Draw icon
        local x, y = effectIconR:getCenter()
        local radius = (effectIconR.w + effectIconR.h) / 4
        love.graphics.setColor(bgcolor)
        love.graphics.circle("fill", x, y, radius)
        love.graphics.setColor(fgcolor)
        love.graphics.circle("line", x, y, radius)
        love.graphics.setColor(1, 1, 1)
        local s = math.min(effectIconR.w / 16, effectIconR.h / 16) / 1.5
        g.drawImage(effInfo.image, x, y, 0, s)

        -- Draw remaining time
        local time = math.floor(duration)
        local seconds = time % 60
        local minutes = math.floor(time / 60)
        if time < 5 then
            love.graphics.setColor(1, 0, 0)
        else
            love.graphics.setColor(1, 1, 1)
        end
        richtext.printRich(
            string.format("{w amp=0.3}{o}%02d:%02d{/o}{/w}", minutes, seconds),
            font,
            effectIconR.x - 200,
            effectIconR.y + effectIconR.h - 16,
            200,
            "right"
        )

        if iml.isHovered(effectIconR:get()) then
            local description = effInfo.description or ""
            if #description > 0 then
                tooltipDrawn = {description = description, x = effectIconR.x, y = effectIconR.y + effectIconR.h}
            end
        end

        -- Next
        effectIconR = effectIconR:moveRatio(0, 1):moveUnit(0, 4)
    end

    if tooltipDrawn then
        helper.tooltip(tooltipDrawn.description, tooltipDrawn.x, tooltipDrawn.y, 1, 0)
    end
end



---@param tok g.Token
---@param bundle g.Bundle
function harvest:tokenEarnedResources(tok, bundle)
    if g.isBeingSimulated() then
        return
    end

    local normX, normY = self.camera:getTransform():transformPoint(tok.x, tok.y)
    local uiX,uiY = ui.getUIScalingTransform():inverseTransformPoint(normX,normY)
    local rhud = g.getHUD().resourceHUD

    if bundle.money then
        rhud:spawnParticles("money", uiX, uiY, bundle.money)
    end
    if bundle.fish then
        rhud:spawnParticles("fish", uiX, uiY, bundle.fish)
    end
    if bundle.fabric then
        rhud:spawnParticles("fabric", uiX, uiY, bundle.fabric)
    end
    if bundle.bread then
        rhud:spawnParticles("bread", uiX, uiY, bundle.bread)
    end
    if bundle.juice then
        rhud:spawnParticles("juice", uiX, uiY, bundle.juice)
    end
end






---@param self HarvestScene
local function getXpMultiplier(self)
    --[[
    every 1% the player is over the "target time" for XP harvesting, 
    gain +3% xp multiplier.

    e.g. if target-time is 50 seconds, and player has taken 100 seconds,
    then they are 100% over the "target-time".
    Therefore they should earn (3% * 100) = +300% more XP
    ]]
    local targTime = consts.TARGET_TIME_PER_LEVEL_UP
    local overtime = math.max(0, self.timeTakenThisLevel - targTime) / targTime
    local statMult = g.stats.XpMultiplier
    local XP_MULTIPLIER_RATE = 3 -- 1% over ==> 3% XP increase
    return statMult * (1 + (XP_MULTIPLIER_RATE*overtime))
end





local popupParticles = particles.newParticlesWorld({
    gravity = 100,
    extraFields = {
        "dx","dy"
    },
    drawParticle = function(p)
        local id = p.id
        local sx,sy = 1,1
        local rot = 0
        local img = "money"
        local STEPS=4
        sx = math.floor(STEPS*math.sin(love.timer.getTime()*10 + id*1.77)+0.5)/STEPS
        g.drawImage(img, p.x,p.y, rot, sx,sy)
    end,
    getParticleDuration = function(p)
        return (4 + p.id % 4) / 2
    end
})



local GRADIENT_IMG = love.graphics.newImage("src/scenes/harvest_scene/gradient_background.png")
local GOLD = objects.Color("#".."FFFAE06B")

---@param progress number
---@param cx number
---@param cy number
local function drawFancyBackgroundShit(progress, cx, cy)
    local r = ui.getScreenRegion()

    do
    local x,y,w,h = r:get()
    local iw,ih = GRADIENT_IMG:getDimensions()
    local sx = w/iw
    local sy = h/ih
    lg.setColor(1,1,1,progress*0.3)
    lg.draw(GRADIENT_IMG, x, y, 0, sx, sy, 0, 0)
    end

    love.graphics.setColor(1,1,1)
    popupParticles:draw()
    if popupParticles:getParticleCount() < 340 then
        local a = love.timer.getTime()*3-- math.random()*2*math.pi
        if love.math.random()<0.5 then
            a = a+math.pi
        end
        local mag = 180 + math.random()*30
        local vx = math.cos(a) * mag
        local vy = math.sin(a) * mag
        popupParticles:spawnParticle(cx,cy, vx,vy)
    end

    do
    local t = (love.timer.getTime()*1) % 1
    local R = (r.w/5) * progress
    local r1 = R*t
    local r2 = R + R*t
    local r3 = R*2 + R*t
    lg.setLineWidth(10)
    local lw=lg.getLineWidth()
    lg.setColor(GOLD[1],GOLD[2],GOLD[3],0.7)
    lg.circle("line", cx,cy, r1)
    lg.setColor(GOLD[1],GOLD[2],GOLD[3],0.6)
    lg.circle("line", cx,cy, r2)
    lg.setColor(GOLD[1],GOLD[2],GOLD[3],0.5)
    lg.circle("line", cx,cy, r3)
    lg.setLineWidth(lw)
    end

    local time = love.timer.getTime()/2
    local DIVISIONS = 120
    godrays.drawRays(cx,cy, time*1.3, {
        rayCount = 5,
        color = GOLD,
        --color = {0.3,1,0.7},
        startWidth = 15,
        divisions = DIVISIONS,
        growRate = 0.1,
        length = r.w * 0.7 * progress,
        fadeTo=0.3
    })

    godrays.drawRays(cx,cy, time*-1.2, {
        rayCount = 3,
        color = GOLD,
        startWidth = 7,
        divisions = DIVISIONS,
        growRate = 0.15,
        length = r.w * 0.5 * progress,
        fadeTo=0.0
    })

    do
    local spd=-0.7
    godrays.drawRays(cx,cy, time*spd, {
        rayCount = 3,
        color = {GOLD[1],GOLD[2],GOLD[3],0.5},
        -- color = {0.7,1,0.3},
        startWidth = 20,
        divisions = DIVISIONS,
        growRate = 0.3,
        length = r.w * 0.7 * progress,
        fadeTo=0.3
    })
    godrays.drawRays(cx,cy, time*spd, {
        rayCount = 3,
        color = GOLD,
        -- color = {0.7,1,0.3},
        startWidth = 12,
        divisions = DIVISIONS,
        growRate = 0.3,
        length = r.w * 0.7 * progress,
        fadeTo=0.3
    })
    end

    godrays.drawRays(cx,cy, 2 + time*1.3, {
        rayCount = 4,
        color = GOLD,
        -- color = {0.7,1,0.3},
        startWidth = 9,
        divisions = DIVISIONS,
        growRate = 0.3,
        length = r.w * 0.7 * progress,
        fadeTo=0.3
    })

    godrays.drawRays(cx,cy, time*0.7, {
        rayCount = 2,
        color = GOLD,
        -- color = {0.1,0.1,0.9},
        startWidth = 8,
        divisions = DIVISIONS,
        growRate = 0.2,
        length = r.w * 0.9 * progress,
        fadeTo=0.4
    })
end



---@param self HarvestScene
local function openUpgradePopup(self)
    if not self.upgradePopup then
        popupParticles:clear()
        self.upgradePopup=true
        self.timeSinceUpgradePopupOpened = 0
    end
end


---@param self HarvestScene
local function closeUpgradePopup(self)
    if self.upgradePopup then
        self.upgradePopup=false
        self.timeSinceUpgradePopupOpened = 0
    end
end



local function drawUpgradePopup(self)
    local r = ui.getScreenRegion()
    local cx,cy = r:getCenter()

    -- number from 0 -> 1
    local progress = math.min(1, self.timeSinceUpgradePopupOpened / UPGRADE_POPUP_FADE_IN_TIME)

    local popup = r:padRatio(0.1 + (1-progress))

    drawFancyBackgroundShit(progress, cx, cy)

    local _,_
    local r2 = popup:padRatio(0.3)
    local title, gotoUpgrades, stayHarvest = r2:splitVertical(1,1,1)
    _,gotoUpgrades,_ = gotoUpgrades:splitHorizontal(1,3,1)
    _,stayHarvest,_ = stayHarvest:splitHorizontal(1,3,1)

    local col1 = objects.Color("#" .. "FF9F14F6")
    local col2 = objects.Color("#" .. "FF3B12A4")

    local red1 = objects.Color("#" .. "FFE61414")
    local red2 = objects.Color("#" .. "FF910B54")

    local function button(rrr, txt, c1,c2)
        if iml.isHovered(rrr:get()) then
            helper.gradientRect("horizontal", c1,c1, rrr:padUnit(4):get())
        else
            helper.gradientRect("horizontal", c1,c2, rrr:padUnit(4):get())
        end
        ui.drawPanel(rrr:get())
        richtext.printRichContained(txt, g.getSmallFont(16), rrr:padRatio(0.4,0.2):get())
        return iml.wasJustClicked(rrr:get())
    end

    lg.setColor(1,1,1)
    richtext.printRichContained(
        NEW_UPGRADES_AVAILABLE,
        g.getSmallFont(16),
        title:padRatio(0.5):padRatio(0,0.2,0,0.2):get()
    )

    -- draw GOTO UPGRADES
    if button(gotoUpgrades:padRatio(0.1), GOTO_UPGRADES, col1,col2) then
        g.gotoSceneViaMap("upgrade_scene")
    end

    -- draw silli cats
    do
    local cat1 = Kirigami(0,0,64,64):center(gotoUpgrades):attachToLeftOf(gotoUpgrades)
    local x1,y1 = cat1:getCenter()
    local sc = progress * 4
    local dy = 20*math.sin(love.timer.getTime()*3)
    g.drawImage("happy_cat", x1,y1+dy, 0, sc,sc)
    local cat2 = Kirigami(0,0,64,64):centerY(gotoUpgrades):attachToRightOf(gotoUpgrades)
    local x2,y2 = cat2:getCenter()
    g.drawImage("happy_cat", x2,y2+dy, 0, sc*-1,sc)
    end

    -- draw GOTO UPGRADES
    if button(stayHarvest:padRatio(0.6,0.5,0.6,0.5), CLOSE, red1,red2) then
        closeUpgradePopup(self)
    end
end



local xpParticles = particles.newParticlesWorld({
    gravity = 0,
    updateParticle = function (p, dt)
        local ACCELLERATION = 300
        local TARG_VEL = 300
        local hud = g.getHUD()
        local targX,targY = hud:getXPBarStartPos()
        local vx,vy = p.vx,p.vy
        local dx, dy = (targX-p.x), (targY-p.y)
        local mag = ((dx*dx + dy*dy) ^ 0.5)
        local lifetime = p.lifetime
        if mag > 0 then
            local targVel = TARG_VEL * (1+lifetime)
            local tvx = (dx/mag)*targVel
            local tvy = (dy/mag)*targVel
            p.vx = (0.96 * vx + (dx/mag)*ACCELLERATION*dt) + 0.04*tvx
            p.vy = (0.96 * vy + (dy/mag)*ACCELLERATION*dt) + 0.04*tvy
        end
    end,
    drawParticle = function(p)
        local id = p.id
        local sx,sy = 1,1
        local i = id%8
        local img
        -- if i<3 then
        --     img = "xp_packet_small_2"
        -- elseif i<6 then
        --     img = "xp_packet_small_1"
        -- elseif i==6 then
        --     img = "xp_packet_big_1"
        -- elseif i==7 then
        --     img = "xp_packet_big_2"
        -- end
        if i%2 == 0 then
            img = "XPgem_small"
        else
            img = "XPgem_large"
        end
        img = "XPgem_small"
        local rot = 0--love.timer.getTime()*10 + id*1.77
        local x,y = p.x,p.y
        g.drawImage(img, x,y, rot, sx,sy)
    end,
    getParticleDuration = function(p)
        return 1.8
    end
})




local function openXpPopup(self)
    -- BOOM! level up popup!
    self.xpPopup = true
    self.timeSinceXpPopupOpened = 0
    self.timeTakenThisLevel = 0
    self.xpRewards = rewards.generateRandomRewards()
    -- g.playUISound("xp_level_up", 1, 1)
    -- g.playUISound("xp_goto_upgrades", 0.5, 1)
    g.playUISound("xp_level_up2", 1, 1)
    popupParticles:clear()
end




local function openBossPopup(self)
    -- call this when a boss is killed.
    self.bossPopup = true
    self.timeSinceBossPopupOpened = 0
end






---@return boolean
local function canAffordAnyUpgrades()
    local tree = g.getUpgTree()
    for _, upg in ipairs(tree:getUpgradesOnTree()) do
        if tree:canAffordUpgrade(upg) then
            return true
        end
    end
    return false
end


local function closeXpPopup(self)
    self.xpPopup = false
    self.timeSinceXpPopupOpened = 0
    self.timeTakenThisLevel = 0
    local sn = g.getSn()
    sn:levelUp()
    if canAffordAnyUpgrades() then
        openUpgradePopup(self)
    end
end


local function getResourceMultiplierFromCombo()
    return 1 + g.getMainWorld().combo * consts.COMBO_MULTIPLIER
end



local drawBossPopup
do

local BOSS_SLAIN = loc("{wavy}{o}Boss has been slain!")
local PRESTIGE_COMPLETE_N = interp("{o}{c r=0.2 g=0.9 b=0.6}Prestige {n} completed.")
local PROGRESS_RESET = loc("{o}By progressing, ALL upgrades are reset.")
local OK_TEXT = loc("{o}Prestige!",nil,{
    context="As in, a button that progresses to the next level/prestige."
})

local BOSS_POPUP_FADE_IN_TIME = 0.7


---@param self HarvestScene
function drawBossPopup(self)
    local r = ui.getScreenRegion()
    iml.panel(r:get()) -- dont let mouse go below this point

    -- number from 0 -> 1
    local progress = math.min(1, self.timeSinceBossPopupOpened / BOSS_POPUP_FADE_IN_TIME)

    local _, mid, _ = r:splitVertical(1,8,1)
    local _,popup = mid:splitHorizontal(1,8,1)
    popup = popup:padRatio(0.1 + (1-progress))

    drawFancyBackgroundShit(progress, mid:getCenter())

    local panelArea, buttonArea = popup:splitVertical(3, 1)
    panelArea = panelArea:padRatio(0.2)
    buttonArea = buttonArea:padRatio(0.5, 0.3, 0.5, 0.3)

    lg.setColor(1,1,1)
    local col1 = objects.Color("#".."FF1F0252")
    local col2 = objects.Color("#".."FF08012C")
    helper.gradientRect("horizontal", col1, col2, panelArea:get())
    ui.drawPanel(panelArea:get())

    local bossSlainTxt, prestigeCompleteTxt, progressResetTxt = panelArea
        :padRatio(0.2)
        :splitVertical(1,1,1)

    love.graphics.setColor(1, 1, 1)
    local prestige = g.getPrestige()
    local f = g.getSmallFont(16)
    richtext.printRichContained(BOSS_SLAIN, f, bossSlainTxt:get())
    richtext.printRichContained(PRESTIGE_COMPLETE_N({n=prestige}), f, prestigeCompleteTxt:get())
    richtext.printRichContained(PROGRESS_RESET, f, progressResetTxt:get())

    if iml.wasJustHovered(buttonArea:get()) then
        g.playUISound("ui_tick", 1.6, 0.65, 0, 0)
    end

    local buttonCol1 = objects.Color("#FF9F14F6")
    local buttonCol2 = objects.Color("#FF3B12A4")
    if iml.isHovered(buttonArea:get()) then
        buttonCol2 = buttonCol1
    end

    helper.gradientRect("horizontal", buttonCol1, buttonCol2, buttonArea:padUnit(4):get())
    ui.drawPanel(buttonArea:get())

    love.graphics.setColor(1, 1, 1)
    richtext.printRichContained(OK_TEXT, f, buttonArea:get())

    if iml.wasJustClicked(buttonArea:get()) then
        g.playUISound("ui_click_basic", 1.4, 0.8)
        g.prestigeSession()
    end
end

end




local drawXpPopup, updateXPPopup
do

local COLS = {
    "#11E0D1",
    "#27D1D9",
    "#3FBEDC",
    "#5CA8DF",
    "#7991E0",
    "#9482DE",
    "#AD7BD9",
    "#C178D3",
    "#D77BCC",
    "#EE7FC4"
}
---@cast COLS table[]
for i=1, #COLS do
    local c = objects.Color(COLS[i])
    c.a = 1
    COLS[i] = c
end
for i=#COLS-1,2,-1 do
    -- make it reflective
    table.insert(COLS, COLS[i])
end


local RAINBOW = {}
local NUM = 10
for i=0, NUM do
    local c = objects.Color(objects.Color.HSVtoRGB((i*360) / NUM, 0.8, 0.8))
    table.insert(RAINBOW, c)
end


local RAINBOW_SCROLL_SPEED = 1

---@param barR kirigami.Region
---@param cols table[]
local function drawRainbowBar(barR, cols)
    local regions = barR:grid(#cols,1)
    for i,r in ipairs(regions) do
        local col_i = (i % #cols) + 1
        lg.setColor(cols[col_i])
        lg.rectangle("fill", r:get())
    end
end




---@param self HarvestScene
function drawXpPopup(self)
    local r = ui.getScreenRegion()
    local hud = g.getHUD()
    iml.panel(r:get()) -- dont let mouse go below this point

    -- number from 0 -> 1
    local progress = math.min(1, self.timeSinceXpPopupOpened / XP_POPUP_FADE_IN_TIME)

    local _, mid, _ = r:padUnit(0, 0, hud.statsWidth, 0):splitVertical(1,8,1)
    local _,popup = mid:splitHorizontal(1,8,1)
    popup = popup:padRatio(0.1 + (1-progress))

    drawFancyBackgroundShit(progress, mid:getCenter())

    do
    love.graphics.setColor(1,1,1)
    local regions
    if #self.xpRewards == 1 then
        local _,rr1,_ = popup:splitVertical(1,1,1)
        regions = {rr1}
    else
        regions = popup:grid(1,#self.xpRewards)
    end
    local p = 0.2
    local rewardClaimed = false

    local function drawReward(i)
        local rrr = regions[i]
        local rew = self.xpRewards[i]
        rrr = rrr:padRatio(p)
        local col1 = objects.Color("#" .. "FF9F14F6")
        local col2 = objects.Color("#" .. "FF3B12A4")
        if iml.isHovered(rrr:get()) then
            col2 = col1
        end
        if iml.wasJustHovered(rrr:get()) then
    		g.playUISound("ui_tick", 1.6,0.65, 0,0)
        end
        helper.gradientRect("horizontal", col1,col2, rrr:padUnit(4):get())
        ui.drawPanel(rrr:get())
        rewards.drawRewardDescription(rew, rrr)
        if iml.wasJustClicked(rrr:get()) and (not rewardClaimed) then
		    g.playUISound("ui_click_basic", 1.4,0.8)
            rewardClaimed = true
            rewards.selectReward(rew)
        end
    end

    for i=1, #self.xpRewards do
        drawReward(i)
    end

    hud:drawStatsAndTokenPool()

    if rewardClaimed then
        g.playUISound("xp_level_up2", 1.2, 1)
        closeXpPopup(self)
    end

    end
end


end


---@param self HarvestScene
local function isAnyPopupOpen(self)
    return self.xpPopup or self.upgradePopup or self.bossPopup
end


---@type table<integer, boolean>
local COMBO_POPUP_MAP = setmetatable({
    [5] = true,
    [10] = true,
    [20] = true,
    [50] = true,
    [100] = true,
    -- If you need to change the multiplier, change it here.
    -- By defualt it's "for every multiple of 100 combo"
}, {__index = function(_, k) return k > 0 and k % 100 == 0 end})
local COMBO_POPUP_TEXT = interp(
    "COMBO: x%{mul} Resources!",
    {context = "Text popup shown when destroying many crops in short amount of time"}
)


---@param tok g.Token
function harvest:tokenDestroyed(tok)
    if not tok.wasSpawnedViaTokenPool then
        -- We dont want to give XP if it isnt from token-pool;
        -- (or else its way too OP; trust me)
        return
    end

    if not isAnyPopupOpen(self) then
        local xp = tok.maxHealth
        local mult = getXpMultiplier(self)
        local sn = g.getSn()
        sn.xp = sn.xp + xp*mult
    end

    if not g.isBeingSimulated() then
        local x,y = self.camera:getTransform():transformPoint(tok.x,tok.y)
        local uiX,uiY = ui.getUIScalingTransform():inverseTransformPoint(x,y)
        local SPD = 600
        local vx,vy = love.math.random(-SPD,SPD), love.math.random(-SPD,SPD)
        xpParticles:spawnParticle(uiX,uiY, vx,vy)

        g.getSn().showTutorials.harvest = false
    end

    local world = g.getMainWorld()
    if COMBO_POPUP_MAP[world.combo] then
        local x = world.mouseX or 0
        local y = world.mouseY or 0
        local mul = math.floor(getResourceMultiplierFromCombo() * 100 + 0.5) / 100
        local r, g, b = objects.Color.HSVtoRGB((world.combo / 49 * 360) % 360, 1, 1)
        local text = string.format("{c r=%.14g g=%.14g b=%.14g}{o}%s{/o}{/c}", r, g, b, COMBO_POPUP_TEXT({mul = mul}))
        worldutil.spawnText(text, x, y, 1.4, 10)
    end
end


---@param self HarvestScene
local function drawComboVisual(self)
    local world = g.getMainWorld()
    local mx, my = self.camera:toWorld(love.mouse.getPosition())

    local mul = "x"..tostring(math.floor(getResourceMultiplierFromCombo() * 100 + 0.5) / 100)
    local font = g.getSmallFont(16)
    local width = font:getWidth(mul)
    local combodur = world:_getComboDuration()
    local ratio = world.comboTimeout / combodur
    local ratioScale = math.min(1, helper.remap(ratio, 1,0, 2,0.3))
    local joltScale = math.max(helper.remap(world.comboTimeout, combodur, combodur - 0.2, 1.4, 1), 1)
    local scale = ratioScale*joltScale

    -- Draw progress bar
    local ha = g.stats.HarvestArea

    local mulTxt = "{o}"..mul.."{/o}"
    local w = richtext.getWidth("x1.11", font)
    local h = font:getHeight()/2

    -- Calculate bar dimensions
    local barWidth = w * scale
    local barHeight = 4
    local barX = mx - barWidth / 2
    local barY = my - ha - h * scale - barHeight - 6

    -- Draw progress bar background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

    -- Draw progress bar fill
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.rectangle("fill", barX, barY, barWidth * ratio, barHeight)

    -- Draw text
    love.graphics.setColor(1, 1, 1)
    richtext.printRich(
        mulTxt, font,
        mx, my-ha,
        width, "center", 0,
        scale, scale,
        width / 2, font:getHeight()
    )
end


function harvest:draw()
    love.graphics.clear(0.3,0.7,0.25)
    love.graphics.setColor(1,1,1)

    -- Draw background
    do
        local w, h = love.graphics.getDimensions()
        local iw, ih = self.background:getDimensions()
        local scale = math.max(w / iw, h / ih)
        love.graphics.draw(self.background, w / 2, h / 2, 0, scale, scale, iw / 2, ih / 2)
    end

    centerCamera(self) -- has implicit self:setCamera()

    local world = g.getMainWorld()

    if isAnyPopupOpen(self) then
        world:_disableMouseHarvester()
    elseif not g.isBeingSimulated() then
        local cx,cy = self.camera:toWorld(love.mouse.getPosition())
        world:_enableMouseHarvester(cx,cy)
    end

    -- Draw clouds
    if not g.isBeingSimulated() then
        --cloudService.drawShadow()
        love.graphics.setColor(1, 1, 1, 1)
        cloudService.draw()
    end

    world:_draw()

    if world.combo > 2 and not isAnyPopupOpen(self) then
        drawComboVisual(self)
    end

    local sess = g.getSn()

    if not g.isBeingSimulated() then
        if sess.showTutorials.harvest and (not consts.DEV_MODE) then
            local lw = love.graphics.getLineWidth()
            love.graphics.setLineWidth(3)
            love.graphics.setColor(objects.Color.RED)

            for _, tok in ipairs(g.getMainWorld().tokens) do
                helper.circleHighlight(tok.x, tok.y, 10)
            end

            love.graphics.setLineWidth(lw)
        end
    end

    love.graphics.setColor(1, 1, 1)
    self:_drawTokenStackAnim()

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    if not (g.isBeingSimulated() or sess.showTutorials.harvest) then
        self:renderMapButton()
    end
    lg.setColor(1,1,1)
    xpParticles:draw()
    local hud = g.getHUD()
    hud:draw({
        xpbar=true
    })

    if not g.isBeingSimulated() and sess.showTutorials.harvest then
        local safeArea = g.getHUD():getSafeArea()
        local tutTextR = safeArea:padRatio(0.1)
        richtext.printRich(TUTORIAL_HARVEST, g.getBigFont(32), tutTextR.x, tutTextR.y, tutTextR.w, "center")
    end

    self:_drawActiveEffects()
    if self.bossPopup then
        drawBossPopup(self)
    elseif self.xpPopup then
        drawXpPopup(self)
    elseif self.upgradePopup then
        drawUpgradePopup(self)
    end

    -- show stats in dev-mode
    if consts.DEV_MODE then
        prof_push("debug stats")

        love.graphics.setColor(1, 1, 1)
        local r = ui.getScreenRegion()
        local _,right = r:splitHorizontal(6,1)
        local N=20
        local regions = right:grid(1,N)

        local i = N
        local font = g.getSmallFont(16)

        richtext.printRichContained("{o}{c r=1 g=1 b=0}LEVEL: "..g.formatNumber(g.getSn().level), font, regions[i]:get())
        i = i - 1
        for _,k in ipairs({"HitDamage", "HitSpeed", "HarvestArea"}) do
            local val = g.stats[k]
            local reg = regions[i]
            richtext.printRichContained("{o}"..k.. ": "..g.formatNumber(val), font, reg:get())
            i = i - 1
        end

        prof_pop() -- prof_push("debug stats")
    end

    self:renderPause()

    --- Storage is Full text:
    do
    local fullResource = nil
    for _,resId in ipairs(g.RESOURCE_LIST) do
        local res = g.getResource(resId)
        local reslim = g.getResourceLimit(resId)
        if res >= reslim then
            fullResource = resId
            break
        end
    end
    if fullResource and (not isAnyPopupOpen(self)) then
        local rr = ui.getScreenRegion():splitVertical(1,5)
            :padRatio(0.4,0.2,0.3,0.2)
            :moveRatio(0,0.5)
        local img1, rr2, img2 = rr:splitHorizontal(1,7,1)
        lg.setColor(1,1,1)
        richtext.printRichContained(
            "{wavy}{c r=0.8 g=0.1 b=0.05}{o}" .. STORAGE_FULL_TEXT,
            g.getSmallFont(16), rr2:get()
        )
        -- lg.rectangle("line", rr2:get())
        -- lg.rectangle("line", img1:get())
        -- lg.rectangle("line", img2:get())
        local t = love.timer.getTime()
        local dy = math.sin(t*3)/4
        g.drawImageContained(fullResource, img1:moveRatio(0, dy):get())
        g.drawImageContained(fullResource, img2:moveRatio(0, dy):get())

        local r = rr2:padRatio(0.6, 0.5, 0.6, 0.0):attachToBottomOf(rr2):moveUnit(0,8)
        if ui.Button(STORAGE_GOTO_UPGRADES, objects.Color.CRIMSON, objects.Color.DARK_RED, r) then
            g.gotoSceneViaMap("upgrade_scene")
        end
    end
    end

    ui.endUI()
end



function harvest:update(dt)
    self:updateCamera(dt)
    g.getHUD():update(dt)

    if self.bossPopup then
        self.timeSinceBossPopupOpened = self.timeSinceBossPopupOpened + dt
    elseif self.xpPopup then
        popupParticles:update(dt)
        self.timeSinceXpPopupOpened = self.timeSinceXpPopupOpened + dt
    elseif self.upgradePopup then
        popupParticles:update(dt)
        self.timeSinceUpgradePopupOpened = self.timeSinceUpgradePopupOpened + dt
    else
        self.timeTakenThisLevel = self.timeTakenThisLevel + dt
    end
    xpParticles:update(dt)

    local sn = g.getSn()
    if (not self.xpPopup) and sn.xp >= sn.xpRequirement and not g.isBeingSimulated() then
        openXpPopup(self)
    end

    local worldW, worldH = g.getWorldDimensions()

    -- Move the camera such that harvest area is not obstructed by the HUD
    local safeArea = g.getHUD():getSafeArea()
    -- These are in "true" screen-space now (non-scaled)
    local uis = ui.getUIScaling()
    local sx, sy = safeArea.x * uis, safeArea.y * uis
    local sw, sh = safeArea.w * uis, safeArea.h * uis
    local scale = math.min(sw / worldW, sh / worldH)
    -- Only do integer scaling
    scale = math.floor(math.max(scale, 1))
    self.worldScale = scale
    local zf = self:zoomFromScale(scale)
    self:setZoom(zf)

    -- Now move the position
    local w, h = love.graphics.getDimensions()
    self.camera:setViewport(0, 0, w, h, (sx + sw / 2) / w, (sy + sh / 2) / h)
    self.camera:setPos(worldW / 2, worldH / 2)

    -- Pull stack token
    local stkTok,onSpawn = g.peekStackedToken()
    if stkTok and (not isAnyPopupOpen(self)) then
        -- dont pull tokens when popups are open.
        if self.stackedTokenLerpTime == -1 then
            -- If there's no token, prepare new one.
            self:_resetStackTokenAnim()
        end

        self.stackedTokenLerpTime = self.stackedTokenLerpTime + dt
        local t = math.min(self.stackedTokenLerpTime / getStackLerpTime(), 1)

        if t >= 1 then
            assert(g.popStackedToken() == stkTok)
            local tok = g.spawnToken(stkTok, self.stackedTokenX, self.stackedTokenY)
            if tok and onSpawn then
                onSpawn(tok)
            end
            worldutil.spawnShockwave(tok.x,tok.y, 0.2, 13)
            self:_resetStackTokenAnim()
        end
    else
        -- Just in case when the stack token was in progress
        self.stackedTokenLerpTime = -1
    end

    -- Update cloud
    if not g.isBeingSimulated() then
        cloudService.update(dt, self.camera)
    end
end


harvest.wheelmoved = harvest.defaultWheelmoved
harvest.mousemoved = harvest.defaultMousemoved

function harvest:keyreleased(k)
    self:defaultKeyreleased(k)
    if k == "tab" and not (g.isBeingSimulated() or g.getSn().showTutorials.harvest) then
        g.gotoSceneViaMap("upgrade_scene")
    elseif k == "escape" then
        local s = g.getSn()
        s.paused = not s.paused
    elseif consts.DEV_MODE then
        if k=="1" then
            openBossPopup(self)
            -- g.summonBoss("pumpkin_boss")
        elseif k=="2" then
            local tok = helper.randomChoice(g.TOKEN_LIST)
            for _ = 1, love.math.random(1, 15) do
                g.stackToken(tok, 100, 100)
            end
        elseif k=="3" then
            local eff = helper.randomChoice(g.EFFECT_LIST)
            g.grantEffect(eff, 10)
        elseif k=="4" then
            local sn=g.getSn()
            sn.xp = sn.xp + sn.xpRequirement
        elseif k=="5" then
            local sn=g.getSn()
            local next = g.getNextScythe()
            if next then
                sn.scythe = next
            end
        elseif k=="8" then
            g.grantEffect("knife_swarm", 15)
        end
    end
end



function harvest:leave(k)
    closeUpgradePopup(self)
    local w = g.getMainWorld()
    w:_disableMouseHarvester()
end


function harvest:getHarvestAreaModifier()
    local scythe = g.getScytheInfo(g.getCurrentScythe())
    return scythe.harvestArea
end


function harvest:getTokenResourceMultiplier()
    return isAnyPopupOpen(self) and 1 or getResourceMultiplierFromCombo()
end


function harvest:bossSlain()
    openBossPopup(self)
end



return harvest

