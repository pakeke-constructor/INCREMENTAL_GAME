--[[

World

The world is a container for tokens and entities.

]]

local ParticleService = require(".particle.ParticleService")
local DataCollection = require(".data_collection")
local table_clear = require("table.clear")

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
    ---@type table<string, integer>
    self.tokenCounts = {}
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

    ---@type table<g.ResourceType, g.DataCollection>
    self.dataCollectors = nil
    -- We can't create the collectors yet because session isnt loaded.

    -- Holds all active effects
    ---@type string[]
    self.effects = {}
    -- Holds all effect durations
    ---@type table<string, number>
    self.effectDurations = {}

    ---@type {color:objects.Color,number:number,x:number,y:number,lifetime:number}[]
    self.damageNumbers = {}
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


---@param tok g.Token
local function drawAxe(tok)
    love.graphics.setColor(1,1,1)
    local t = math.min(tok.timeSinceHitStart / getAxeSwingTime(), 1)
    local scale = 2 * math.floor(tok.id % 2) - 1
    g.drawImageOffset("iron_axe", tok.x - 14 * scale, tok.y + 4, scale * (t * t - 0.9), scale, 1, 0.1, 0.9)
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

    if tok.timeSinceHitStart < getSwingTime() then
        drawAxe(tok)
    end

    drawTokenHealthBar(tok)
end




---@param e g.Entity
local function drawEntity(e)
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


---@param a g.Token|g.Entity
---@param b g.Token|g.Entity
local function sortOrder(a, b)
    return a.y < b.y
end


function World:_draw()
    local w,h = self.WIDTH, self.HEIGHT
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", 0,0, w,h)

    ---@type (g.Token|g.Entity)[]
    local objlist = {}

    -- drawGround()

    -- Add token to be drawn
    for _, tok in ipairs(self.tokens) do
        objlist[#objlist+1] = tok
    end

    -- Add entitiy to be drawn
    for _, e in ipairs(self.entities) do
        objlist[#objlist+1] = e
    end

    -- Sort by Y bottom first
    table.sort(objlist, sortOrder)

    -- Draw everything.
    for _, t_or_e in ipairs(objlist) do
        if g.isToken(t_or_e) then
            ---@cast t_or_e g.Token
            drawToken(t_or_e)
        elseif g.isEntity(t_or_e) then
            ---@cast t_or_e g.Entity
            drawEntity(t_or_e)
        end
    end

    self:_drawSparkle()

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




---@param self g.World
local function updateResourceDataCollection(self)
    if not self.dataCollectors then
        self.dataCollectors = {}

        for _, resId in ipairs(g.RESOURCE_LIST) do
            local startValue = g.getResource(resId)
            self.dataCollectors[resId] = DataCollection(60, startValue)
        end
    end

    for resId, collector in pairs(self.dataCollectors) do
        local value = g.getResource(resId)
        if value < g.getResourceLimit(resId) or value ~= collector:getPrevious() then
            collector:setAndIncrementPointer(value)
        end
    end
end



---@param id string
---@param dur number
function World:_grantEffect(id, dur)
    if self.effectDurations[id] then
        self.effectDurations[id] = self.effectDurations[id] + dur
    else
        self.effectDurations[id] = dur
        self.effects[#self.effects+1] = id
    end
end


---@param dt number
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
    table_clear(self.tokenCounts)

    self.tokenPartition:clear()
    for _, t in ipairs(self.tokens) do
        ---@cast t g.Token
        self.tokenPartition:add(t, t.x,t.y)
        self.tokenCounts[t.type] = (self.tokenCounts[t.type] or 0) + 1
    end

    -- Update effect durations (iterate backward)
    for i = #self.effects, 1, -1 do
        local eff = self.effects[i]
        self.effectDurations[eff] = self.effectDurations[eff] - dt

        if self.effectDurations[eff] <= 0 then
            table.remove(self.effects, i)
            self.effectDurations[eff] = nil
        end
    end

    -- Update token
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

    -- Run per second update event bus on upgrades
    self.timer = self.timer + dt
    while self.timer >= 1 do
        for _, ent in ipairs(self.entities) do
            if ent.perSecondUpdate then
                ent:perSecondUpdate()
            end
        end

        for _, tok in ipairs(self.tokens) do
            if tok.perSecondUpdate then
                tok:perSecondUpdate()
            end
        end

        g.call("perSecondUpdate")
        updateResourceDataCollection(self)
        self.timer = self.timer - 1
    end

    self.tokens:flush()

    self.particles:update(dt)
    self:_updateSparkle(dt)
end




---@return table<g.ResourceType, number>
function World:_getResourcesPerSecond()
    local result = {}

    for resId, collector in pairs(self.dataCollectors) do
        result[resId] = collector:avgdiff()
    end

    return result
end



---@return fun():(string,number)
function World:_iterateActiveEffects()
    return coroutine.wrap(function()
        for _, eff in ipairs(self.effects) do
            local dur = self.effectDurations[eff] or 0
            if dur > 0 then
                coroutine.yield(eff, dur)
            end
        end
    end)
end




-- Initial lifetime of the damage numbers
local DAMAGE_NUMBER_LIFETIME = 0.5
-- After lifetime, show popup with bouncy easing.
local DAMAGE_NUMBER_POPUP_TIME = 0.2
-- For every 0.1 seconds below lifetime, draw sparkles.
local DAMANGE_NUMBER_SPARKLE = 0.1
-- If the indices (computed using above variable) is out-of-range, remove the damage numbers.
local DAMAGE_NUMBER_SPARKLE_ASSETS = {"damage_number_sparkle_1", "damage_number_sparkle_2"}

---@param num number
---@param x number
---@param y number
---@param col objects.Color
function World:_spawnDamageNumber(num, x, y, col)
    self.damageNumbers[#self.damageNumbers+1] = {
        color = col,
        number = num,
        x = x + helper.lerp(-5, 5, love.math.random()),
        y = y + helper.lerp(-5, 1, love.math.random()),
        lifetime = DAMAGE_NUMBER_LIFETIME,
    }
end

---@param dt number
---@private
function World:_updateSparkle(dt)
    for i = #self.damageNumbers, 1, -1 do
        local dn = self.damageNumbers[i]
        dn.lifetime = dn.lifetime - dt

        if dn.lifetime < 0 then
            local sparkidx = math.ceil(-dn.lifetime / DAMANGE_NUMBER_SPARKLE)
            if not DAMAGE_NUMBER_SPARKLE_ASSETS[sparkidx] then
                table.remove(self.damageNumbers, i)
            end
        end
    end

    table.sort(self.damageNumbers, sortOrder)
end

---@private
function World:_drawSparkle()
    local smallFont = g.getSmallFont(16)
    local fontHeight = smallFont:getHeight()
    for _, dn in ipairs(self.damageNumbers) do
        love.graphics.setColor(dn.color)

        if dn.lifetime < 0 then
            local sparkidx = math.ceil(-dn.lifetime / DAMANGE_NUMBER_SPARKLE)
            g.drawImage(DAMAGE_NUMBER_SPARKLE_ASSETS[sparkidx], dn.x, dn.y)
        else
            local tspawn = helper.clamp((DAMAGE_NUMBER_LIFETIME - dn.lifetime) / DAMAGE_NUMBER_POPUP_TIME, 0, 1)
            local scale = math.max(helper.EASINGS.easeOutBack(tspawn) ^ 3, 0)
            local text = tostring(dn.number)
            local width = smallFont:getWidth(text)
            helper.printTextOutlineSimple(text, smallFont, dn.x, dn.y, 0, scale, scale, width / 2, fontHeight / 2)
        end
    end
end



return World
