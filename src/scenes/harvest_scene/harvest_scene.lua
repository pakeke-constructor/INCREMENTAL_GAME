
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




function harvest:init()
    self.allowMousePan = false

    self.timeTakenThisLevel = 0
    self.xpRequirement = 1 -- set every frame.

    self.xpBarX, self.xpBarY = 1000,0 -- where should Xp particles move to?

    self.timeSinceXpPopupOpened = 0
    self.xpPopup = false
    self.xpRewards = {}

    self.timeSinceUpgradePopupOpened = 0
    self.upgradePopup = false

    self.stackedTokenX = 0
    self.stackedTokenY = 0
    self.stackedTokenLerpTime = -1

    -- This background is not part of the texture atlas so it needs to be loaded manually
    self.background = love.graphics.newImage("src/scenes/harvest_scene/background_harvest.png")
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
        DESC = objects.Color("#".."FFF4AEAB")
    },
    [false] = {
        BG = objects.Color("#".."FF1C4A1C"),
        FG = objects.Color("#".."FF75D963"),
        DESC = objects.Color("#".."FF79BBDF")
    },
}

function harvest:_drawActiveEffects()
    local r = Kirigami(0, 0, ui.getScaledUIDimensions())
    local effectIconR = Kirigami(0, 70, 24, 24)
        :attachToRightOf(r)
        :moveRatio(-1, 0)
        :moveUnit(-8, 0)

    local font = g.getSmallFont(16)
    for eff, duration in g.getMainWorld():_iterateActiveEffects() do
        local effInfo = g.getEffectInfo(eff)
        local bgcolor = EFFECT_COLORS[effInfo.isDebuff].BG
        local fgcolor = EFFECT_COLORS[effInfo.isDebuff].FG
        local desccolor = EFFECT_COLORS[effInfo.isDebuff].DESC

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
        richtext.printRich(
            string.format("{w amp=0.3}{o}%02d:%02d{/o}{/w}", minutes, seconds),
            font,
            effectIconR.x - 200,
            effectIconR.y + effectIconR.h - 16,
            200,
            "right"
        )

        if iml.isHovered(effectIconR:get()) then
            -- Calculate description info data for drawing
            local bigFont = g.getBigFont(16)
            local titleWidth = bigFont:getWidth(richtext.stripEffects(effInfo.name))
            local description = effInfo.description or ""
            local width, lines = font:getWrap(
                richtext.stripEffects(effInfo.description or ""),
                math.max(titleWidth, 200)
            )
            local height = bigFont:getHeight() + 8 + #lines * font:getHeight()

            -- Draw description
            local PADDING = 4
            local descWidth = 2 * PADDING + width
            local descHeight = 2 * PADDING + height
            local descX = effectIconR.x - descWidth - 4
            local descY = effectIconR.y + effectIconR.h
            love.graphics.setColor(helper.multiplyAlpha(bgcolor, 0.7))
            love.graphics.rectangle("fill", descX, descY, descWidth, descHeight)
            love.graphics.setColor(fgcolor)
            love.graphics.rectangle("line", descX, descY, descWidth, descHeight)

            local yoff = 0
            love.graphics.setColor(1, 1, 1)
            richtext.printRich(
                "{o}"..effInfo.name.."{/o}",
                bigFont,
                descX + PADDING,
                descY + PADDING,
                width,
                "right"
            )
            yoff = yoff + bigFont:getHeight()
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.line(
                descX + PADDING + 4,
                descY + PADDING + yoff + 4,
                descX + descWidth - PADDING - 4,
                descY + PADDING + yoff + 4
            )
            yoff = yoff + 8
            love.graphics.setColor(desccolor)
            richtext.printRich(
                "{o}"..description.."{/o}",
                font,
                descX + PADDING,
                descY + PADDING + yoff,
                width,
                "right"
            )
        end

        -- Next
        effectIconR = effectIconR:moveRatio(0, 1):moveUnit(0, 4)
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
local function getXPMultiplier(self)
    --[[
    every 1% the player is over the "target time" for XP harvesting, 
    gain +3% xp multiplier.

    e.g. if target-time is 50 seconds, and player has taken 100 seconds,
    then they are 100% over the "target-time".
    Therefore they should earn (3% * 100) = +300% more XP
    ]]
    local targTime = consts.TARGET_TIME_PER_LEVEL_UP
    local overtime = math.max(0, self.timeTakenThisLevel - targTime) / targTime
    local XP_MULTIPLIER_RATE = 3 -- 1% over ==> 3% XP increase
    return 1 + XP_MULTIPLIER_RATE*overtime
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
        local img
        if id%2==0 then
            img = "xp_packet_big_1"
        else
            img = "xp_packet_big_2"
        end
        img = "money"
        sx = math.sin(love.timer.getTime()*10 + id*1.77)
        g.drawImage(img, p.x,p.y, rot, sx,sy)
    end,
    getParticleDuration = function(p)
        return (4 + p.id % 4) / 2
    end
})



local GRADIENT_IMG = love.graphics.newImage("src/scenes/harvest_scene/gradient_background.png")
local GOLD = objects.Color("#".."FFFAE06B")

---@param progress number
local function drawFancyBackgroundShit(progress)
    local r = Kirigami(0,0,ui.getScaledUIDimensions())
    local cx,cy = r:getCenter()

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
    local r = Kirigami(0,0, ui.getScaledUIDimensions())
    local cx,cy = r:getCenter()

    -- number from 0 -> 1
    local progress = math.min(1, self.timeSinceUpgradePopupOpened / UPGRADE_POPUP_FADE_IN_TIME)

    local popup = r:padRatio(0.1 + (1-progress))

    drawFancyBackgroundShit(progress)

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
        local ACCELLERATION = 400
        local TARG_VEL = 400
        local w,h = ui.getScaledUIDimensions()
        local hud = g.getHUD()
        local targX,targY = hud.profileHUD:getXPBarStartPos()
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
        if i<3 then
            img = "xp_packet_small_2"
        elseif i<6 then
            img = "xp_packet_small_1"
        elseif i==6 then
            img = "xp_packet_big_1"
        elseif i==7 then
            img = "xp_packet_big_2"
        end
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
    popupParticles:clear()
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
    sn.xp = 0
    sn.level = sn.level + 1
    if canAffordAnyUpgrades() then
        openUpgradePopup(self)
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
    local r = Kirigami(0,0, ui.getScaledUIDimensions())

    -- number from 0 -> 1
    local progress = math.min(1, self.timeSinceXpPopupOpened / XP_POPUP_FADE_IN_TIME)

    local _, mid, _ = r:splitVertical(1,8,1)
    local _,popup = mid:splitHorizontal(1,2,1)
    popup = popup:padRatio(0.1 + (1-progress))

    drawFancyBackgroundShit(progress)

    do
    love.graphics.setColor(1,1,1)
    local regions = {popup:splitVertical(1,1,1)}
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
        helper.gradientRect("horizontal", col1,col2, rrr:padUnit(4):get())
        ui.drawPanel(rrr:get())
        rewards.drawRewardDescription(rew, rrr)
        if iml.wasJustClicked(rrr:get()) and (not rewardClaimed) then
            rewardClaimed = true
            rewards.selectReward(rew)
        end
    end

    for i=1, 3 do
        drawReward(i)
    end

    if rewardClaimed then
        closeXpPopup(self)
    end

    end
end


end


function harvest:tokenDestroyed(tok)
    if not (self.xpPopup or self.upgradePopup) then
        local xp = tok.maxHealth
        local mult = getXPMultiplier(self)
        local sn = g.getSn()
        sn.xp = sn.xp + xp*mult
    end

    if not g.isBeingSimulated() then
        local x,y = self.camera:getTransform():transformPoint(tok.x,tok.y)
        local uiX,uiY = ui.getUIScalingTransform():inverseTransformPoint(x,y)
        local SPD = 600
        local vx,vy = love.math.random(-SPD,SPD), love.math.random(-SPD,SPD)
        xpParticles:spawnParticle(uiX,uiY, vx,vy)
    end
end


---@param self HarvestScene
local function isAnyPopupOpen(self)
    return self.xpPopup or self.upgradePopup
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
        world:_enableMouseHarvester(-500,-500)
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

    love.graphics.setColor(1, 1, 1)
    self:_drawTokenStackAnim()

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    self:renderMapButton()
    lg.setColor(1,1,1)
    xpParticles:draw()
    g.getHUD():draw({
        xpbar=true
    })
    self:_drawActiveEffects()
    if self.xpPopup then
        drawXpPopup(self)
    elseif self.upgradePopup then
        drawUpgradePopup(self)
    end

    ui.endUI()
end



function harvest:update(dt)
    self:updateCamera(dt)
    g.getHUD():update(dt)

    if self.xpPopup then
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
    if k == "tab" then
        g.gotoSceneViaMap("upgrade_scene")
    elseif consts.DEV_MODE then
        if k=="1" then
            worldutil.spawnLightning(100,100,10)
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
        end
    end
end



function harvest:leave(k)
    closeUpgradePopup(self)
end




return harvest

