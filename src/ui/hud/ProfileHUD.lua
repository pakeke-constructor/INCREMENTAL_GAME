---@class g.hud.Profile: objects.Class
local Profile = objects.Class("h.hud:Profile")

---@class g.hud._TokenParticle
---@field package token string (also the image)
---@field package x number
---@field package y number
---@field package time number

local TOHUD_ANIMATION_DURATION = 0.4

function Profile:init()
    ---@type g.hud._TokenParticle[]
    self.particles = {}
    self.freeArea = Kirigami(0, 0, ui.getScaledUIDimensions())
    self.tokenQueuePos = {x = 0, y = 0}
end

if false then
    ---@return g.hud.Profile
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function Profile() end
end

---@param dt number
function Profile:update(dt)
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.time = p.time + dt

        if p.time >= TOHUD_ANIMATION_DURATION then
            table.remove(self.particles, i)
        end
    end
end

---@param camera Camera
---@param noDraw boolean?
function Profile:draw(camera, noDraw)
    local r = Kirigami(0,0,ui.getScaledUIDimensions())
    local leftR = r:splitHorizontal(1, 1, 1, 1, 1)
    local profileR = leftR:shrinkToAspectRatio(1, 1):attachToBottomOf(r):moveRatio(0, -1):padRatio(0.05)
    local stackTokenR = Kirigami(0, 0, 20, 20)
        :attachToRightOf(profileR)
        :attachToTopOf(profileR)
        :moveRatio(0, 1)
        :moveUnit(-8, 0)

    self.tokenQueuePos.x, self.tokenQueuePos.y = stackTokenR:getCenter()

    if not noDraw then
        -- Draw dummy profile picture
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", profileR:get())
        local x,y,w,h = profileR:get()
        love.graphics.setColor(1,1,1)
        local SCALE=4
        g.drawImage("happy_cat",x+w/2,y+h/2, 0, -SCALE,SCALE)
        love.graphics.setColor(1, 0, 0)
        local lw = love.graphics.getLineWidth()
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", profileR:get())
        love.graphics.setLineWidth(lw)

        love.graphics.setColor(1, 1, 1)

        -- Draw inflight token
        ---@type table<string, integer>
        local inflight = {}
        for _, p in ipairs(self.particles) do
            local t = p.time / TOHUD_ANIMATION_DURATION
            local et = helper.clamp(helper.EASINGS.sineInOut(t), 0, 1)
            -- p.x and p.y is in world-space
            local spx, spy = camera:toScreen(p.x, p.y) -- in screen-space
            local sspx, sspy = ui.getUIScalingTransform():inverseTransformPoint(spx, spy) -- in "scaled screen" space
            local px = helper.lerp(sspx, self.tokenQueuePos.x, et)
            local py = helper.lerp(sspy, self.tokenQueuePos.y, et)
            inflight[p.token] = (inflight[p.token] or 0) + 1
            g.drawImage(p.token, px, py)
        end

        -- Draw stacked token
        local font = g.getSmallFont(16)
        ---@type table<string, integer>
        local tokens = {}
        local countByToken = {}
        for _, tok in ipairs(g.getSn().tokenQueue) do
            if countByToken[tok] then
                countByToken[tok] = countByToken[tok] + 1
            elseif #tokens <= 5 then -- If you change the size of the stack token, change this too
                countByToken[tok] = 1
                tokens[#tokens+1] = tok
            end
        end

        local curtime = love.timer.getTime()
        for i, tok in ipairs(tokens) do
            local s = math.min(stackTokenR.w / 16, stackTokenR.h / 16)
            local bob = math.sin(curtime * 2 + i)
            local count = math.max(countByToken[tok] - (inflight[tok] or 0), 0)
            g.drawImageOffset(tok, stackTokenR.x, stackTokenR.y + bob, 0, s, s, 0, 0)
            richtext.printRich(
                "{w freq=0.5 amp=0.5 k=0}{o}"..count.."{/o}{/w}",
                font,
                stackTokenR.x + stackTokenR.w - 4,
                stackTokenR.y + stackTokenR.h - 12 + bob,
                100,
                "left"
            )
            stackTokenR = stackTokenR
                :moveRatio(0, 1)
                :moveUnit(0, 2)
        end
    end

    local maxX = math.max(profileR.x + profileR.w, stackTokenR.x + stackTokenR.w)
    self.freeArea = r:padUnit(maxX, 0, 0, 0)
end

function Profile:getSafeArea()
    return self.freeArea
end

---@param tok string
---@param x number
---@param y number
function Profile:spawnParticle(tok, x, y)
    self.particles[#self.particles+1] = {
        token = tok,
        x = x,
        y = y,
        time = 0
    }
end

function Profile:getStackTokenPos()
    return self.tokenQueuePos.x, self.tokenQueuePos.y
end

return Profile
