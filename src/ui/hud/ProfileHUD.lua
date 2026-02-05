
local lg=love.graphics


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
    self.inflightTokens = {}
    self.freeArea = ui.getScreenRegion()
    self.tokenQueuePos = {x = 0, y = 0}
end

if false then
    ---@return g.hud.Profile
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function Profile() end
end

---@param dt number
function Profile:update(dt)
    for i = #self.inflightTokens, 1, -1 do
        local p = self.inflightTokens[i]
        p.time = p.time + dt

        if p.time >= TOHUD_ANIMATION_DURATION then
            table.remove(self.inflightTokens, i)
        end
    end
end





local MAX_NUMBER_OF_TOKEN_TYPES = 6
-- no more than X tokens stacked at a time; dont wanna overwhelm player


---@param sidebarWidth number
---@param noDraw boolean?
function Profile:draw(sidebarWidth, noDraw)
    local r = ui.getScreenRegion()
    local profileBaseR = Kirigami(0, 0, sidebarWidth, sidebarWidth)
        :attachToBottomOf(r)
        :attachToLeftOf(r)
        :moveRatio(1, -1)
    local profileR = profileBaseR:padUnit(4)
    local stackTokenR = Kirigami(0, 0, 20, 20)
        :attachToRightOf(profileR)
        :attachToTopOf(profileR)
        :moveRatio(0, 1)
        :moveUnit(-8, 0)

    self.tokenQueuePos.x, self.tokenQueuePos.y = stackTokenR:getCenter()

    if not noDraw then
        -- Draw avatar background location stencil
        lg.setColor(1, 1, 1)
        lg.setStencilMode("draw", 2)
        local x,y,w,h = profileR:get()
        lg.rectangle("fill", x, y, w, h)
        lg.setStencilMode("test", 2)

        -- Draw avatar
        local scale = helper.lerp(w, h, 0.5) / consts.AVATAR_SIZE
        g.drawPlayerAvatar(x + w / 2, y + h / 2, scale, true, true)
        lg.setStencilMode()

        -- -- Draw red border
        -- lg.setColor(0, 0, 0)
        -- local lw = lg.getLineWidth()
        -- lg.setLineWidth(3)
        -- lg.rectangle("line", profileR:get())
        -- lg.setLineWidth(lw)

        lg.setColor(1, 1, 1)

        -- Draw inflight token
        love.graphics.setColor(1,1,1)
        ---@type table<string, integer>
        local inflight = {}
        for _, p in ipairs(self.inflightTokens) do
            local t = p.time / TOHUD_ANIMATION_DURATION
            local et = helper.clamp(helper.EASINGS.sineInOut(t), 0, 1)
            -- p.x and p.y is in world-space
            local sspx, sspy = ui.getUIScalingTransform():inverseTransformPoint(p.x,p.y) -- in "scaled screen" space
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
        for _, tabl in ipairs(g.getSn().tokenQueue) do
            local tok = tabl.tokenId
            if countByToken[tok] then
                countByToken[tok] = countByToken[tok] + 1
            elseif #tokens < MAX_NUMBER_OF_TOKEN_TYPES then
                countByToken[tok] = 1
                tokens[#tokens+1] = tok
            end
        end

        local curtime = love.timer.getTime()
        for i, tok in ipairs(tokens) do
            local s = math.min(stackTokenR.w / 16, stackTokenR.h / 16)
            local bob = math.sin(curtime * 2 + i)
            local count = math.max((countByToken[tok] - (inflight[tok] or 0) - 1), 0)
            if count > 0 then
                g.drawImageOffset(tok, stackTokenR.x, stackTokenR.y + bob, 0, s, s, 0, 0)
                richtext.printRich(
                    "{w freq=0.5 amp=0.5 k=0}{o}"..count.."{/o}{/w}",
                    font,
                    stackTokenR.x + stackTokenR.w - 4,
                    stackTokenR.y + stackTokenR.h - 12 + bob,
                    100,
                    "left"
                )
            end
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
function Profile:spawnTokenVisual(tok, x, y)
    self.inflightTokens[#self.inflightTokens+1] = {
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
