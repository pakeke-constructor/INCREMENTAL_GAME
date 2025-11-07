

local FreeCameraScene = require("src.scenes.FreeCameraScene")
local vignette = require("src.modules.vignette.vignette")
local simulation = require("src.world.simulation")

---@class HarvestScene: FreeCameraScene
local harvest = FreeCameraScene()



function harvest:init()
    self.allowMousePan = false

    self.stackedTokenX = 0
    self.stackedTokenY = 0
    self.stackedTokenLerpTime = -1
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
    if bundle.logs then
        rhud:spawnParticles("logs", uiX, uiY, bundle.logs)
    end
    if bundle.rocks then
        rhud:spawnParticles("rocks", uiX, uiY, bundle.rocks)
    end
    if bundle.bones then
        rhud:spawnParticles("bones", uiX, uiY, bundle.bones)
    end
end


function harvest:draw()
    centerCamera(self)

    love.graphics.clear(0.3,0.7,0.25)
    love.graphics.setColor(1,1,1)

    local world = g.getMainWorld()

    if not simulation.isSimulating() then
        local cx,cy = self.camera:toWorld(love.mouse.getPosition())
        world:_enableMouseHarvester(cx,cy)
    end

    world:_draw()

    self:_drawTokenStackAnim()

    self:resetCamera()

    vignette.draw()

    ui.startUI()
    self:renderMapButton()
    g.getHUD():draw()
    self:_drawActiveEffects()
    ui.endUI()
end


function harvest:update(dt)
    self:updateCamera(dt)
    g.getHUD():update(dt)

    local worldW, worldH = g.getWorldDimensions()

    -- Move the camera such that harvest area is not obstructed by the HUD
    local safeArea = g.getHUD():getSafeArea()
    -- These are in "true" screen-space now (non-scaled)
    local uis = ui.getUIScaling()
    local sx, sy = safeArea.x * uis, safeArea.y * uis
    local sw, sh = safeArea.w * uis, safeArea.h * uis
    local scale = math.min(sw / worldW, sh / worldH)
    local zf = self:zoomFromScale(scale)
    -- Make sure it's in 0.2 increments
    zf = math.floor(zf / 0.2) * 0.2
    self:setZoom(zf)

    -- Now move the position
    scale = self:scaleFromZoom(zf)
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
        end
    end
end



return harvest

