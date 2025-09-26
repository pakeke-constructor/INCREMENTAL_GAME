--[[

World

The world is a container for tokens and entities.

]]


---@class g.World
---@field entities objects.BufferedSet
---@field tokens objects.BufferedSet
---@field tokensToHoverTime {[table]: number}
---@field tokenPartition objects.Partition
---@field mouseX number?
---@field mouseY number?
local World = objects.Class("g:World")

-- Think of this as the "dimensions" of the harvest-area
World.WIDTH = 450
World.HEIGHT = 300

-- Minimum hover time before a token can be mined
-- (Prevents players flicking their mouse all over the screen)
local MIN_HOVER_TIME = 0.07


function World:init()
    self.tokens = objects.BufferedSet()
    self.entities = objects.BufferedSet()

    self.tokenPartition = objects.Partition(20)

    self.mouseX, self.mouseY = nil,nil

    self.tokensToHoverTime = ({--[[
        [token] -> hover_time_accumulated
    ]]})
end



local HARVEST_CIRCLE_INSIDE = {0.2,0.2,0.2,0.17}
local HARVEST_CIRCLE_BORDER = {.9,.9,.9}

---@param self g.World
local function drawHarvestCircle(self)
    local x,y = assert(self.mouseX), assert(self.mouseY)
    local rad = g.stats.HarvestArea
    love.graphics.setColor(HARVEST_CIRCLE_INSIDE)
    love.graphics.circle("fill", x,y, rad)
    local lw = love.graphics.getLineWidth()
    love.graphics.setLineWidth(math.floor(rad / 15))
    love.graphics.setColor(HARVEST_CIRCLE_BORDER)
    love.graphics.circle("line", x,y, rad)
    love.graphics.setLineWidth(lw)
end


local function updateHarvestCircle(self, dt)
    local x,y = assert(self.mouseX), assert(self.mouseY)

    local hoveredTokens = {}

    self.tokenPartition:query(x,y, function (tok)
        if math.distance(x-tok.x, y-tok.y) <= (g.stats.HarvestArea + consts.HARVEST_AREA_LEEWAY) then
            hoveredTokens[tok] = true

            self.tokensToHoverTime[tok] = (self.tokensToHoverTime[tok] or 0) + dt

            if self.tokensToHoverTime[tok] >= MIN_HOVER_TIME then
                g.tryHitToken(tok)
            end
        end
    end, g.stats.HarvestArea)

    for token, hoverTime in pairs(self.tokensToHoverTime) do
        if not hoveredTokens[token] then
            self.tokensToHoverTime[token] = nil
        end
    end
end


function World:_enableMouseHarvester(x,y)
    self.mouseX = x
    self.mouseY = y
end


local function getSwingTime()
    return g.stats.HitDuration * 0.75
end

local function getAxeSwingTime()
    return getSwingTime() / 2
end


---@param tok g.Token
---@param dt number
local function updateToken(tok,dt)
    tok.timeAlive = tok.timeAlive + dt
    tok.timeSinceDamaged = tok.timeSinceDamaged + dt
    tok.timeSinceHitStart = tok.timeSinceHitStart + dt
    tok.timeSinceHit = tok.timeSinceHit + dt

    if tok.timeSinceHitStart >= getAxeSwingTime() and tok.timeSinceHitStart < tok.timeSinceHit then
        -- Damage token
        local hitMult = g.ask("getTokenHitMultiplier", tok)
        tok.timeSinceHit = 0
        g.call("tokenHit", tok)
        g.damageToken(tok, hitMult * g.stats.HitDamage)
    end
end


local function drawTokenHealthBar(tok)
    local x,y = tok.x, tok.y
    love.graphics.setColor(1,0,0)
    local HP_BAR_W = 14
    local HP_BAR_H = 3
    local realW = HP_BAR_W * (tok.health / tok.maxHealth)
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle("fill", x-HP_BAR_W/2, y+8, HP_BAR_W, HP_BAR_H)
    love.graphics.setColor(1,0,0,1)
    love.graphics.rectangle("fill", x-HP_BAR_W/2, y+8, realW, HP_BAR_H)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("line", x-HP_BAR_W/2, y+8, HP_BAR_W, HP_BAR_H)
end




local TOKEN_SPAWN_ANIMATION_DURATION = 0.2
local TOKEN_SPAWN_ANIMATION_AMPLITUDE = 1.3

local TOKEN_HIT_ANIMATION_DURATION = 0.15
local TOKEN_HIT_JERK_AMPLITUDE = 1.3
local TOKEN_HIT_SQUASH_AMOUNT = 1


---@param tok g.Token
---@return number sx, number sy
local function getTokScale(tok)
    local sx,sy = 1,1

    local ta = tok.timeAlive
    if ta < TOKEN_SPAWN_ANIMATION_DURATION then
        -- On spawn: Make it pop up
        local v = math.sin(ta*math.pi/TOKEN_SPAWN_ANIMATION_DURATION) * TOKEN_SPAWN_ANIMATION_AMPLITUDE
        if (ta > TOKEN_SPAWN_ANIMATION_DURATION/2) then
            v = math.max(v, 1)
        end
        sx = math.sqrt(v)
        sy = v*1.2
    end

    local tsd = tok.timeSinceDamaged
    if tsd < TOKEN_HIT_ANIMATION_DURATION then
        -- Make it look "squashed" down
        local mag = (TOKEN_HIT_ANIMATION_DURATION - tsd)*TOKEN_HIT_SQUASH_AMOUNT
        sx = sx * (1+mag)
        sy = sy * (1+mag)
    end

    return sx,sy
end


local TOKEN_DAMAGE_JERK_DURATION = 0.15
local TOKEN_DAMAGE_JERK_AMPLITUDE = 1.3


---@param tok g.Token
---@return number rot
local function getTokRotation(tok)
    local rot = 0

    local tsd = tok.timeSinceDamaged
    if tsd < TOKEN_DAMAGE_JERK_DURATION then
        rot = rot + (TOKEN_DAMAGE_JERK_DURATION - tsd) * TOKEN_DAMAGE_JERK_AMPLITUDE
    end

    if tok.id % 2 == 0 then
        return -rot
    end
    return rot
end

---@param tok g.Token
---@return number shearX, number shearY
local function getTokShear(tok)
    return 0,0
end



local function drawToken(tok)
    love.graphics.setColor(1,1,1,1)

    local sx,sy = getTokScale(tok)
    local rot = getTokRotation(tok)
    local kx,ky = getTokShear(tok)

    g.drawImage(tok.image, tok.x, tok.y, rot, sx, sy, kx,ky)
    drawTokenHealthBar(tok)
end





---@param tok g.Token
local function drawAxe(tok)
    love.graphics.setColor(1,1,1)
    local t = math.min(tok.timeSinceHitStart / getAxeSwingTime(), 1)
    local scale = 2 * math.floor(tok.id % 2) - 1
    g.drawImageOffset("iron_axe", tok.x - 14 * scale, tok.y + 4, scale * (t * t - 0.9), scale, 1, 0.1, 0.9)
end


function World:_draw()
    local w,h = self.WIDTH, self.HEIGHT
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", 0,0, w,h)

    -- drawGround()

    for _, tok in ipairs(self.tokens) do
        drawToken(tok)
    end

    -- draw pickaxes/axes:
    for _,tok in ipairs(self.tokens) do
        ---@cast tok g.Token
        if tok.timeSinceHitStart < getSwingTime() then
            drawAxe(tok)
        end
    end

    if self.mouseX then
        drawHarvestCircle(self)
    end
end



---@class g.TokenPool: objects.Class
local TokenPool = objects.Class("g:TokenPool")
function TokenPool:init()
    self.tokens = {}
end
function TokenPool:add(tokenId, amount)
    self.tokens[tokenId] = (self.tokens[tokenId] or 0) + (amount or 1)
end



function World:_update(dt)
    self.entities:flush()
    self.tokens:flush()

    -- update TokenPool
    local tp = TokenPool()
    g.call("populateTokenPool", tp)
    if g.getPrestige() == 0 then
        tp:add("basic_grass", 3)
    end
    self.tokenPool = tp


    self.tokenPartition:clear()
    for _, t in ipairs(self.tokens) do
        self.tokenPartition:add(t, t.x,t.y)
    end

    for _, tok in ipairs(self.tokens) do
        updateToken(tok,dt)
    end

    for _, e in ipairs(self.entities) do
        e:update(dt)
    end

    if self.mouseX then
        updateHarvestCircle(self, dt)
    end

    -- respawn tokens that died
    local tokenCounts = {}
    for _,t in ipairs(self.tokens)do
        tokenCounts[t.type] = (tokenCounts[t.type] or 0) + 1
    end
    for tokType, poolCount in pairs(self.tokenPool.tokens) do
        local ct = tokenCounts[tokType] or 0
        local toSpawn = poolCount - ct
        for _=1, toSpawn do
            if love.math.random() < (dt*3) then
                -- TODO: this randomness sucks! 
                -- Its random and it sometimes takes ages to respawn
                local x,y = g.getRandomPositionForToken()
                assert(x and y)
                g.spawnToken(tokType, x,y)
            end
        end
    end

    self.tokens:flush()
end





return World
