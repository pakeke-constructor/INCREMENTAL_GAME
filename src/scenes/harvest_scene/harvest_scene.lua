
local lg=love.graphics

local particles = require("src.modules.particles.particles")
local cloudService = require(".cloud_service")



local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")
local simulation = require("src.world.simulation")

---@class HarvestScene: FreeCameraScene
local harvest = FreeCameraScene()


local XP_POPUP_FADE_IN_TIME = 0.25
-- How many seconds it takes to fade in the popup



function harvest:init()
    self.allowMousePan = false

    self.timeTakenThisLevel = 0
    self.xpPopup = nil
    self.xpRequirement = 1 -- set every frame.

    self.xpBarX, self.xpBarY = 1000,0 -- where should Xp particles move to?

    self.timeSincePopupOpened = 0
    self.xpPopup = false

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
        --sx = math.sin(love.timer.getTime()*10 + id*1.77)
        g.drawImage(img, p.x,p.y, rot, sx,sy)
    end,
    getParticleDuration = function(p)
        return (4 + p.id % 4) / 2
    end
})


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



local function openPopup(self)
    -- BOOM! level up popup!
    self.xpPopup = true
    self.timeSincePopupOpened = 0
    self.timeTakenThisLevel = 0
    popupParticles:clear()
end



local function closePopup(self)
    self.xpPopup = false
    self.timeSincePopupOpened = 0
    self.timeTakenThisLevel = 0
    local sn = g.getSn()
    sn.xp = 0
    sn.level = sn.level + 1
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




local GRADIENT_IMG = love.graphics.newImage("src/scenes/harvest_scene/gradient_background.png")
local GOLD = objects.Color("#".."FFFAE06B")

---@param self HarvestScene
function drawXpPopup(self)
    local r = Kirigami(0,0, ui.getScaledUIDimensions())

    -- number from 0 -> 1
    local progress = math.min(1, self.timeSincePopupOpened / XP_POPUP_FADE_IN_TIME)

    local top, mid, bot = r:splitVertical(1,8,1)
    local _,popup = mid:splitHorizontal(1,2,1)
    popup = popup:padRatio(0.1 + (1-progress))

    top = top:moveRatio(0,-(1-progress))
    bot = bot:moveRatio(0,(1-progress))

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
        local mag = 280 + math.random()*60
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

    local DIVISIONS = 120
    godrays.drawRays(cx,cy, love.timer.getTime()*1.3, {
        rayCount = 5,
        color = GOLD,
        --color = {0.3,1,0.7},
        startWidth = 15,
        divisions = DIVISIONS,
        growRate = 0.1,
        length = r.w * 0.7 * progress,
        fadeTo=0.3
    })

    godrays.drawRays(cx,cy, love.timer.getTime()*-1.2, {
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
    godrays.drawRays(cx,cy, love.timer.getTime()*spd, {
        rayCount = 3,
        color = {GOLD[1],GOLD[2],GOLD[3],0.5},
        -- color = {0.7,1,0.3},
        startWidth = 20,
        divisions = DIVISIONS,
        growRate = 0.3,
        length = r.w * 0.7 * progress,
        fadeTo=0.3
    })
    godrays.drawRays(cx,cy, love.timer.getTime()*spd, {
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

    godrays.drawRays(cx,cy, 2 + love.timer.getTime()*1.3, {
        rayCount = 4,
        color = GOLD,
        -- color = {0.7,1,0.3},
        startWidth = 9,
        divisions = DIVISIONS,
        growRate = 0.3,
        length = r.w * 0.7 * progress,
        fadeTo=0.3
    })

    godrays.drawRays(cx,cy, love.timer.getTime()*0.7, {
        rayCount = 2,
        color = GOLD,
        -- color = {0.1,0.1,0.9},
        startWidth = 8,
        divisions = DIVISIONS,
        growRate = 0.2,
        length = r.w * 0.9 * progress,
        fadeTo=0.4
    })

    -- TODO: im not sure if these black bars look very good...
    -- i think we need OOMPH, not a cinematic.
    --[[
    lg.setColor(0,0,0)
    lg.rectangle("fill", top:get())
    lg.rectangle("fill", bot:get())
    ]]
    --- yeah... idk, maybe remove this stuff ^^^^

    do
    love.graphics.setColor(1,1,1)
    local a,b,c = popup:splitVertical(1,1,1)
    local p = 0.2

    local function draw(rrr)
        rrr = rrr:padRatio(p)
        local col1 = objects.Color("#" .. "FF9F14F6")
        local col2 = objects.Color("#" .. "FF3B12A4")
        helper.gradientRect("horizontal", col1,col2, rrr:padUnit(4):get())
        ui.drawPanel(rrr:get())
        richtext.printRichContained("{c r=0 g=0 b=0}option-1", g.getSmallFont(16), rrr:get())
    end

    draw(a)
    draw(b)
    draw(c)
    end

    if iml.wasJustClicked(popup:get()) then
        closePopup(self)
    end
end


function updateXPPopup(self, dt)
    popupParticles:update(dt)
end



end


function harvest:tokenDestroyed(tok)
    if not self.xpPopup then
        local xp = tok.maxHealth
        local mult = getXPMultiplier(self)
        local sn = g.getSn()
        sn.xp = sn.xp + xp*mult
    end

    local x,y = self.camera:getTransform():transformPoint(tok.x,tok.y)
    local uiX,uiY = ui.getUIScalingTransform():inverseTransformPoint(x,y)
    local SPD = 600
    local vx,vy = love.math.random(-SPD,SPD), love.math.random(-SPD,SPD)
    xpParticles:spawnParticle(uiX,uiY, vx,vy)
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

    if self.xpPopup then
        world:_enableMouseHarvester(-500,-500)
    elseif (not simulation.isSimulating()) then
        local cx,cy = self.camera:toWorld(love.mouse.getPosition())
        world:_enableMouseHarvester(cx,cy)
    end

    -- Draw clouds
    cloudService.drawShadow()
    love.graphics.setColor(1, 1, 1, 0.67)
    cloudService.draw()

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
    end

    ui.endUI()
end




function harvest:update(dt)
    self:updateCamera(dt)
    g.getHUD():update(dt)

    if self.xpPopup then
        updateXPPopup(self, dt)
        self.timeSincePopupOpened = self.timeSincePopupOpened + dt
    else
        self.timeTakenThisLevel = self.timeTakenThisLevel + dt
    end
    xpParticles:update(dt)

    local sn = g.getSn()
    if (not self.xpPopup) and sn.xp > sn.xpRequirement then
        openPopup(self)
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
    local stkTok = g.peekStackedToken()
    if stkTok then
        -- If there's no token, prepare new one.
        if self.stackedTokenLerpTime == -1 then
            self:_resetStackTokenAnim()
        end

        self.stackedTokenLerpTime = self.stackedTokenLerpTime + dt
        local t = math.min(self.stackedTokenLerpTime / getStackLerpTime(), 1)

        if t >= 1 then
            assert(g.popStackedToken() == stkTok)
            g.spawnToken(stkTok, self.stackedTokenX, self.stackedTokenY)
            self:_resetStackTokenAnim()
        end
    else
        -- Just in case when the stack token was in progress
        -- then it's gone.
        self.stackedTokenLerpTime = -1
    end

    -- Update cloud
    cloudService.update(dt, self.camera)

    if simulation.isSimulating() then
        simulation.update(dt)
    end
end


harvest.wheelmoved = harvest.defaultWheelmoved
harvest.mousemoved = harvest.defaultMousemoved

function harvest:keyreleased(k)
    self:defaultKeyreleased(k)
    if consts.DEV_MODE then
        if k=="1" then
            worldutil.spawnLightning(100,100,10)
        elseif k=="2" then
            local tok = helper.choice(g.TOKEN_LIST)
            for _ = 1, love.math.random(1, 15) do
                g.stackToken(tok, 100, 100)
            end
        elseif k=="3" then
            local eff = helper.choice(g.EFFECT_LIST)
            g.grantEffect(eff, 10)
        elseif k=="4" then
            local sn=g.getSn()
            sn.xp = sn.xp + sn.xpRequirement
        end
    end
end



return harvest

