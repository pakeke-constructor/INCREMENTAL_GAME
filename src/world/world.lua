--[[

World

The world is a container for tokens and entities.

]]

local ParticleService = require(".particle.ParticleService")

---@class g.World: objects.Class
---@field entities objects.BufferedSet
---@field tokens objects.BufferedSet
---@field tokensToHoverTime {[table]: number}
---@field tokenPartition objects.Partition
---@field mouseX number?
---@field mouseY number?
local World = objects.Class("g:World")

-- Think of this as the "dimensions" of the harvest-area
World.WIDTH = 400
World.HEIGHT = 250

-- Minimum hover time before a token can be mined
-- (Prevents players flicking their mouse all over the screen)
local MIN_HOVER_TIME = 0.07


function World:init()
    self.tokens = objects.BufferedSet()
    self.entities = objects.BufferedSet()
    ---@type table<string, objects.BufferedSet<g.Entity>>
    self.upgradeEntities = {}

    self.tokenPartition = objects.Partition(20)

    self.mouseX, self.mouseY = nil,nil

    self.tokensToHoverTime = ({--[[
        [token] -> hover_time_accumulated
    ]]})

    self.particles = ParticleService()
    self.timer = 0 -- For per second update
end



local HARVEST_CIRCLE_INSIDE = {0.2,0.2,0.2,0.17}
local HARVEST_CIRCLE_BORDER = {.9,.9,.9}


---@param self g.World
---@param dt number
local function updateHarvestCircle(self, dt)
    local x,y = assert(self.mouseX), assert(self.mouseY)

    local hoveredTokens = {}

    g.iterateTokensInArea(x, y, g.stats.HarvestArea + consts.HARVEST_AREA_LEEWAY, function(tok)
        hoveredTokens[tok] = true
        self.tokensToHoverTime[tok] = (self.tokensToHoverTime[tok] or 0) + dt

        if self.tokensToHoverTime[tok] >= MIN_HOVER_TIME then
            g.tryHitToken(tok)
        end
    end)

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
        g.hitImmediately(tok)
    end
end


local function drawTokenHealthBar(tok)
    if tok.health >= tok.maxHealth then
        return -- dont draw
    end
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
local TOKEN_HIT_SQUASH_AMOUNT = 0.5


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
        local mag = ((TOKEN_HIT_ANIMATION_DURATION - tsd)/TOKEN_HIT_ANIMATION_DURATION)*TOKEN_HIT_SQUASH_AMOUNT
        --sx = sx * (1-mag)
        sy = sy * (1-mag)
    end

    if tok.id % 2 == 0 then
        -- some tokens are flipped
        sx=sx*-1
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

    -- shadow:
    love.graphics.setColor(g.COLORS.SHADOW)
    love.graphics.ellipse("fill",tok.x,tok.y+6,6,3)

    love.graphics.setColor(1,1,1)
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

    -- draw entities
    for _, e in ipairs(self.entities) do
        ---@cast e g.Entity

        if e.drawBelow then
            love.graphics.setColor(1, 1, 1)
            e:drawBelow()
        end

        if e.shadowRadius then
            love.graphics.setColor(g.COLORS.SHADOW)
            love.graphics.ellipse("fill",e.x,e.y+e.shadowRadius,e.shadowRadius,e.shadowRadius/2)
        end

        if e.image then
            love.graphics.setColor(1, 1, 1)
            love.graphics.setBlendMode(e.blendmode or "alpha", e.blendalphamode or "alphamultiply")
            g.drawImage(e.image, e.x+(e.ox or 0), e.y+(e.oy or 0), e.rot or 0, e.sx or 1, e.sy or 1)
            love.graphics.setBlendMode("alpha", "alphamultiply")
        end

        if e.draw then
            love.graphics.setColor(1, 1, 1)
            e:draw()
        end
    end

    love.graphics.setColor(1, 1, 1)
    self.particles:draw()

    if self.mouseX then
        worldutil.drawHarvestCircle(
            self.mouseX,
            self.mouseY,
            g.stats.HarvestArea,
            HARVEST_CIRCLE_INSIDE,
            HARVEST_CIRCLE_BORDER
        )
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



---@param upgradeId string
---@private
function World:_countEntityUpgrades(upgradeId)
    if self.upgradeEntities[upgradeId] then
        return self.upgradeEntities[upgradeId]:length()
    end
    return 0
end


function World:_update(dt)
    self.entities:flush()
    self.tokens:flush()

    -- update upgrade-entity association set
    for _, elist in pairs(self.upgradeEntities) do
        for _, e in ipairs(elist) do
            if not self.entities:has(e) then
                elist:removeBuffered(e) -- Needs to be buffered otherwise it disappoints ipairs.
            end
        end

        elist:flush()
    end

    -- update TokenPool
    local tp = TokenPool()
    g.call("populateTokenPool", tp)
    if g.getPrestige() == 0 then
        tp:add("grass_blades", 5)
    end
    self.tokenPool = tp


    self.tokenPartition:clear()
    for _, t in ipairs(self.tokens) do
        self.tokenPartition:add(t, t.x,t.y)
    end

    for _, tok in ipairs(self.tokens) do
        updateToken(tok,dt)
    end

    -- Spawn or delete upgrade entity if necessary
    for _, upgradeId in ipairs(g.UPGRADE_LIST) do
        local uinfo = g.getUpgradeInfo(upgradeId)
        local ulevel = g.getUpgradeLevel(uinfo)

        if ulevel > 0 and uinfo.spawnEntity then
            local ecount = 1
            if uinfo.getEntityCount then
                ecount = math.max(uinfo:getEntityCount(ulevel), 0)
            end
            local diff = self:_countEntityUpgrades(upgradeId) - ecount

            if diff ~= 0 then
                -- Ensure set exist
                if not self.upgradeEntities[upgradeId] then
                    self.upgradeEntities[upgradeId] = objects.BufferedSet()
                end

                if diff < 0 then
                    -- Spawn more entities
                    for _ = 1, -diff do
                        local ent = uinfo:spawnEntity()
                        self.upgradeEntities[upgradeId]:addBuffered(ent)
                    end
                else
                    -- Remove excess entities
                    for _, e in ipairs(self.upgradeEntities[upgradeId]) do
                        if diff == 0 then
                            break
                        end

                        self.upgradeEntities[upgradeId]:removeBuffered(e) -- do not disappoint ipairs
                        self.entities:removeBuffered(e)
                        diff = diff - 1 -- if it's 0, then this loop stops
                    end
                end

                self.upgradeEntities[upgradeId]:flush()
            end
        end
    end

    self.entities:flush() -- flush one more time in case entities are removed

    for _, e in ipairs(self.entities) do
        ---@cast e g.Entity
        if e.update then
            e:update(dt)
        end

        if e.lifetime then
            e.lifetime = e.lifetime - dt
            if e.lifetime <= 0 then
                self.entities:removeBuffered(e)
            end
        end
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
            if love.math.random() < (dt*5) then
                -- TODO: this randomness sucks! 
                -- Its random and it sometimes takes ages to respawn
                local x,y = g.getRandomPositionForToken()
                if x and y then
                    g.spawnToken(tokType, x,y)
                end
            end
        end
    end

    self.tokens:flush()

    self.particles:update(dt)

    -- Run per second update event bus on upgrades
    self.timer = self.timer + dt
    while self.timer >= 1 do
        g.call("perSecondUpdate")
        self.timer = self.timer - 1
    end
end





return World
