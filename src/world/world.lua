--[[

World

The world is a container for tokens and entities.

]]


local ParticleService = require(".particle.ParticleService")
local DataCollector = require(".data_collector")
local table_clear = require("table.clear")
local sceneManager = require("src.scenes.sceneManager")

---@class g.World.Decor
---@field x number
---@field y number
---@field image string
local Decor


---@class g.World: objects.Class
---@field entities objects.BufferedSet
---@field tokens objects.BufferedSet
---@field bossToken g.Token?
---@field tokensToHoverTime {[table]: number}
---@field tokenPartition objects.Partition
---@field mouseX number?
---@field mouseY number?
local World = objects.Class("g:World")

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
    self.orbitAngle = 0

    self.tokensToHoverTime = ({--[[
        [token] -> hover_time_accumulated
    ]]})

    self.bossToken = nil

    ---@type table<g.Entity, number?>
    self.entitiesToHitCooldown = setmetatable({}, {__mode = "k"})

    self.particles = ParticleService()
    self.timer = 0 -- For per second update
    self.seconds = 0 -- how many seconds have elapsed (perSecondUpdate)

    ---@type table<g.ResourceType, g.DataCollector>
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

    -- Create tile atlas
    self.tilemap = helper.splitTileImage("harvestarea_tilemap_0", consts.WORLD_TILE_SIZE)

    -- Player avatar. Cannot initialize it in here due to cyclic dependency with g.spawnEntity and this world.
    ---@type g.Entity|nil
    self.playerAvatar = nil

    ---@type table<string, number[]>
    self.tokenDestroyTime = {--[[
        tracks WHEN tokens were destroyed, in seconds
        [tokType] -> {12.3, 434.2, 38.1, 12.28, 111.07, 39.08}
    ]]}

    self.analyticsSendTime = 0

    -- decorations:
    self.lastSeenDimensions = {x=0,y=0,prestige=0}
    self.decorations = {}

    self.combo = 0
    self.comboTimeout = 0
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



---@param x number
---@param y number
function World:_enableMouseHarvester(x,y)
    self.mouseX = x
    self.mouseY = y
end

function World:_disableMouseHarvester()
    -- disables mouse harvester
    -- (e.g. if we are in upgrade-scene, or rewards open)
    self.mouseX = nil
    self.mouseY = nil
end


function World:_isPlayerCurrentlyHarvesting()
    -- when the player's mouse-harvester is off-screen,
    -- we say that the player isn't harvesting.
    -- (Eg when the player isnt in the scene, or when a popup is open,)
    return not not self.mouseX
end


local function getSwingTime()
    return g.getHitDuration() * 0.75
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

    if tok.flight then
        local vx,vy = tok.flight.vx, tok.flight.vy
        tok.x = tok.x + vx*dt
        tok.y = tok.y + vy*dt
    end

    if tok.update then
        tok:update(dt)
    end

    if tok.health <= 0 then
        g.destroyToken(tok)
        return
    end

    if tok.timeSinceHitStart >= getAxeSwingTime() and tok.timeSinceHitStart < tok.timeSinceHit then
        g.hitImmediately(tok)
    end

    local ww,wh = g.getWorldDimensions()
    local leeway = 0
    if tok.flight then
        leeway = 200
    end
    local outOfBounds = not helper.isInsideRect(tok.x,tok.y, 0,0,ww,wh, leeway)
    if outOfBounds then
        -- token is out of bounds; destroy.
        -- (prevents softlocks when world-dimensions decrease)
        g.deleteToken(tok)
    end
end



local function emulateLineRectangle(thickness, x, y, w, h)
    -- The anchor is on the center
    -- top
    g.drawImageOffset("1x1", x - thickness / 2, y - thickness / 2, 0, w + thickness, thickness, 0, 0)
    -- bottom
    g.drawImageOffset("1x1", x - thickness / 2, y + h - thickness / 2, 0, w + thickness, thickness, 0, 0)
    -- left
    g.drawImageOffset("1x1", x - thickness / 2, y - thickness / 2, 0, thickness, h + thickness, 0, 0)
    -- right
    g.drawImageOffset("1x1", x + w - thickness / 2, y - thickness / 2, 0, thickness, h + thickness, 0, 0)
end

---@param tok g.Token
local function drawTokenHealthBar(tok)
    if tok.health >= tok.maxHealth then
        return -- dont draw
    end
    local x,y = tok.x, tok.y
    local HP_BAR_W = 14
    local HP_BAR_H = 3
    local realW = HP_BAR_W * (tok.health / tok.maxHealth)

    local hx = x-HP_BAR_W/2
    local hy = y+8

    -- Draw bar background
    love.graphics.setColor(0,0,0,0.5)
    g.drawImageOffset("1x1", hx, hy, 0, HP_BAR_W, HP_BAR_H, 0, 0)

    -- Draw lagged health
    local t = helper.clamp(tok.timeSinceDamaged / consts.LAGGED_HEALTHBAR_DURATION, 0, 1)
    t = helper.clamp(helper.EASINGS.easeInCubic(t), 0, 1)
    local laggedW = HP_BAR_W * helper.lerp(tok.laggedHealth, tok.health, t) / tok.maxHealth
    love.graphics.setColor(1,1,1,1)
    g.drawImageOffset("1x1", hx, hy, 0, laggedW, HP_BAR_H, 0, 0)
    -- Draw health
    if realW > 0 then
        if tok.starred then
            love.graphics.setColor(g.COLORS.MONEY)
        else
            love.graphics.setColor(0.1,0.9,0.1,1)
        end
        g.drawImageOffset("1x1", hx, hy, 0, realW, HP_BAR_H, 0, 0)
    end

    -- Draw border
    -- love.graphics.setColor(0,0,0,1)
    -- emulateLineRectangle(1, hx, hy, HP_BAR_W, HP_BAR_H)
end




local TOKEN_SPAWN_ANIMATION_DURATION = 0.2
local TOKEN_SPAWN_ANIMATION_AMPLITUDE = 1.6

local TOKEN_HIT_ANIMATION_DURATION = 0.15
local TOKEN_HIT_SQUASH_AMOUNT = 0.6

local TOKEN_BOB_SPEED = 4
local TOKEN_BOB_AMOUNT = 0.03


---@param tok g.Token
---@return number
---@return number
local function getTokBob(tok)
    local bobbing = math.sin(love.timer.getTime() * TOKEN_BOB_SPEED + tok.id * 894.12234) * TOKEN_BOB_AMOUNT
    local sy = 1 + bobbing
    local ww = 16
    if tok.image then
        local _
        --_,_,ww,_ = g.getImageQuad(tok.image):getViewport()
    end

    local oy = -bobbing * ww
    return sy,oy
end


---@param tok g.Token
---@return number sx, number sy
local function getTokScale(tok)
    local sx,sy = 1,1

    if tok.bossfight then
        return 1,1 -- boss-tokens dont scale.
    end

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

    if tok.bossfight then
        return 0 -- boss-tokens dont rotate.
    end

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
---@param scytheImg string
local function drawScythe(tok, scytheImg)
    love.graphics.setColor(1,1,1)
    local t = tok.timeSinceHitStart / getAxeSwingTime()
    -- For scythe, we need to "damage" at mid-swing. This means narrowing down the timing for `t`.
    local t2 = helper.EASINGS.sineInOut(helper.clamp(helper.remap(t, 0.4, 1.2, 0, 2), 0, 1))
    local flip = 2 * math.floor(tok.id % 2) - 1
    local rot = helper.lerp(0.7, 0.1, t2)
    g.drawImageOffset(scytheImg, tok.x + 3 * flip, tok.y + 22, rot * flip, flip, 1, 1, 1.5)
end


local function drawShadow(shadow, x,y)
    love.graphics.setColor(g.COLORS.SHADOW)
    shadow = shadow or "shadow_medium"
    local dy = 1
    if shadow == "shadow_big" then dy=3 end
    g.drawImage(shadow, x, y+dy, 0)
end


local EMPTY = {}

---@param tok g.Token
local function drawToken(tok)
    love.graphics.setColor(1,1,1,1)

    local sx,sy = getTokScale(tok)
    local rot = getTokRotation(tok)
    local kx,ky = getTokShear(tok)
    local ssy, oy = getTokBob(tok)

    sy = sy * ssy

    local stalkInfo = tok.growths and g.getStalkInfo(tok.growths.stalk)
    if stalkInfo and stalkInfo.dontFlip then
        -- dont flip non-symmetric stalks (it messes up berry placement)
        sx = math.abs(sx)
    end

    -- shadow:
    drawShadow(tok.shadow, tok.x, tok.y)

    love.graphics.setColor(1,1,1)
    if tok.drawBelow then
        tok:drawBelow()
    end

    if tok.flight then
        -- draw wings
        local flapSpeed = ((tok.id%6 + 8) / 8)
        local t = love.timer.getTime()*flapSpeed + tok.id*71.23324
        local cwings = tok.flightCustomWings or EMPTY
        lg.setColor(1,1,1)
        helper.drawWings(tok.x, tok.y, t, cwings.image, 1, cwings.distance)
    end

    love.graphics.setColor(1,1,1)
    local tinfo = g.getTokenInfo(tok.type)
    g.drawTokenImage(tinfo, tok.x, tok.y + oy, rot, sx, sy, kx,ky)

    love.graphics.setColor(1,1,1)
    if tok.drawToken then
        tok:drawToken(tok.x, tok.y + oy, rot, sx, sy, kx,ky)
    end

    if tok.slimed then
        local s = math.sin(love.timer.getTime()*4 + tok.id*7.343)
        g.drawImage("slimed_visual2", tok.x+6,tok.y-5+s, 0, 1,1)
    end
    if tok.starred then
        local s = math.sin(love.timer.getTime()*4 + tok.id*4.143)
        local sc = math.sin(love.timer.getTime()*8 + tok.id*4.143)
        g.drawImage("star_visual", tok.x-6,tok.y-5+s, 0, sc,1)
    end

    local scytheImg = g.getScytheInfo(g.getCurrentScythe()).image
    if tok.timeSinceHitStart < getSwingTime() then
        drawScythe(tok, scytheImg)
    end

    drawTokenHealthBar(tok)
end




---@param e g.Entity
local function drawEntity(e)
    if e.drawBelow then
        love.graphics.setColor(1, 1, 1)
        e:drawBelow()
    end

    if e.shadow ~= false then
        drawShadow(e.shadow, e.x, e.y)
    end

    local sx,sy = e.sx or 1, e.sy or 1
    if e.bulgeAnimation then
        local blg = assert(e.bulgeAnimation)
        local mag = 1 + (blg.time/blg.duration)*blg.magnitude
        sx = sx * mag
        sy = sy * mag
    end

    if e.image then
        -- We need this need blendmode boolean check.
        -- LOVE doesn't check the blending mode internally
        -- and will always break batching even if the specified
        -- blend mode in `setBlendMode` is same as `getBlendMode`.
        local needblendmode = e.blendmode or e.blendalphamode

        love.graphics.setColor(1, 1, 1, e.alpha or 1)

        if needblendmode then
            love.graphics.setBlendMode(e.blendmode or "alpha", e.blendalphamode or "alphamultiply")
        end

        g.drawImage(e.image, e.x+(e.ox or 0), e.y+(e.oy or 0), e.rot or 0, sx,sy)

        if needblendmode then
            love.graphics.setBlendMode("alpha", "alphamultiply")
        end
    end

    if e.draw then
        love.graphics.setColor(1, 1, 1)
        e:draw()
    end
end


---@param a g.Token|g.Entity
---@param b g.Token|g.Entity
local function sortOrder(a, b)
    local indexA = a.y + (a.drawOrder or 0)
    local indexB = b.y + (b.drawOrder or 0)
    return indexA < indexB
end


---@param x number
---@param y number
---@return number
local function hash(x, y)
    return (x + 499) * 499500 + (y + 499) * 500
end

function World:_draw()
    prof_push("world:_draw")

    -- local w,h = g.getWorldDimensions()
    -- love.graphics.setColor(0,0,0)
    -- love.graphics.rectangle("line", 0,0, w,h)
    prof_push("draw_tiles")
    love.graphics.setColor(1, 1, 1)

    local wtz = consts.WORLD_TILE_SIZE
    local wtw, wth = g.getWorldTileDimensions()
    -- Lua loops are both inclusive. So subtract by 1.
    wtw, wth = wtw - 1, wth - 1
    local atlas = g.getAtlas()
    for y = 0, wth do
        for x = 0, wtw do
            local targetQuad = nil

            -- Border specializations
            if y == 0 then
                if x == 0 then
                    -- Top left
                    love.graphics.draw(atlas, self.tilemap[1][2], x * wtz, (y - 1) * wtz)
                    love.graphics.draw(atlas, self.tilemap[2][1], (x - 1) * wtz, y * wtz)
                    targetQuad = self.tilemap[2][2]
                elseif x == wtw then
                    -- Top right
                    love.graphics.draw(atlas, self.tilemap[1][4], x * wtz, (y - 1) * wtz)
                    love.graphics.draw(atlas, self.tilemap[2][5], (x + 1) * wtz, y * wtz)
                    targetQuad = self.tilemap[2][4]
                else
                    -- Top center
                    love.graphics.draw(atlas, self.tilemap[1][3], x * wtz, (y - 1) * wtz)
                    targetQuad = self.tilemap[2][3]
                end
            elseif y == wth then
                if x == 0 then
                    -- Bottom left
                    love.graphics.draw(atlas, self.tilemap[4][1], (x - 1) * wtz, y * wtz)
                    love.graphics.draw(atlas, self.tilemap[5][2], x * wtz, (y + 1) * wtz)
                    love.graphics.draw(atlas, self.tilemap[6][2], x * wtz, (y + 2) * wtz)
                    targetQuad = self.tilemap[4][2]
                elseif x == wtw then
                    -- Bottom right
                    love.graphics.draw(atlas, self.tilemap[4][5], (x + 1) * wtz, y * wtz)
                    love.graphics.draw(atlas, self.tilemap[5][4], x * wtz, (y + 1) * wtz)
                    love.graphics.draw(atlas, self.tilemap[6][4], x * wtz, (y + 2) * wtz)
                    targetQuad = self.tilemap[4][4]
                else
                    -- Bottom center
                    love.graphics.draw(atlas, self.tilemap[5][3], x * wtz, (y + 1) * wtz)
                    love.graphics.draw(atlas, self.tilemap[6][3], x * wtz, (y + 2) * wtz)
                    targetQuad = self.tilemap[4][3]
                end
            else
                if x == 0 then
                    -- Left center
                    love.graphics.draw(atlas, self.tilemap[3][1], (x - 1) * wtz, y * wtz)
                    targetQuad = self.tilemap[3][2]
                elseif x == wtw then
                    -- Right center
                    love.graphics.draw(atlas, self.tilemap[3][5], (x + 1) * wtz, y * wtz)
                    targetQuad = self.tilemap[3][4]
                else
                    -- Center
                    targetQuad = self.tilemap[3][3]
                end
            end

            -- Draw tile
            love.graphics.draw(atlas, targetQuad, x * wtz, y * wtz)
        end
    end
    prof_pop() -- prof_push("draw_tiles")

    prof_push("draw_world_decor")
    -- Draw decoration:
    -- Hashing to provide pseudorandom+deterministic decoration placement
    for _,decor in ipairs(self.decorations) do
        if decor.color then
            lg.setColor(decor.color)
        end
        g.drawImage(decor.image, decor.x, decor.y)
    end
    prof_pop()

    ---@type (g.Token|g.Entity)[]
    local objlist = {}

    -- drawGround()

    prof_push("token/entity sort")
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
    prof_pop() -- prof_push("token/entity sort")

    -- Draw everything.
    prof_push("token/entity draw")
    for _, t_or_e in ipairs(objlist) do
        if g.isToken(t_or_e) then
            ---@cast t_or_e g.Token
            drawToken(t_or_e)
        elseif g.isEntity(t_or_e) then
            ---@cast t_or_e g.Entity
            drawEntity(t_or_e)
        end
    end
    prof_pop() -- prof_push("token/entity draw")

    self:_drawDamageNumbers()

    love.graphics.setColor(1, 1, 1)
    self.particles:draw()

    if self.mouseX then
        worldutil.drawHarvestCircle(
            self.mouseX,
            self.mouseY,
            g.stats.HarvestArea,
            HARVEST_CIRCLE_INSIDE,
            HARVEST_CIRCLE_BORDER,
            (self.combo >= 3)
        )
    end

    prof_pop()
end



---@class g.TokenPool: objects.Class
local TokenPool = objects.Class("g:TokenPool")
function TokenPool:init()
    self.tokens = {}
end

if false then
    ---@return g.TokenPool
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function TokenPool() end
end

function TokenPool:add(tokenId, amount)
    self.tokens[tokenId] = (self.tokens[tokenId] or 0) + (amount or 1)
end

function TokenPool:subtract(tokenId, amount)
    amount = amount or (self.tokens[tokenId] or 0)
    self.tokens[tokenId] = math.max(0, (self.tokens[tokenId] or 0) - amount)
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
            self.dataCollectors[resId] = DataCollector(60, startValue)
        end
    end

    for resId, collector in pairs(self.dataCollectors) do
        local value = g.getResource(resId)
        if value < g.getResourceLimit(resId) or value ~= collector:getPrevious() then
            collector:setAndIncrementPointer(value)
        end
    end
end



---@param x number
---@param y number
---@param maxRadius number
---@param toks g.Token[]
local function selectNearestToken(x, y, maxRadius, toks)
    local currentDist = maxRadius + 0.001
    local index = 0

    for i, v in ipairs(toks) do
        local dist = helper.magnitude(v.x - x, v.y - y)

        if dist < currentDist then
            currentDist = dist
            index = i
        end
    end

    if index > 0 then
        return toks[index]
    end
    return nil
end



local function isInHarvestScene()
    return select(2, sceneManager.getCurrentScene()) == "harvest_scene"
end


---@return fun(table: table<string, integer>, index?: string):string
---@return integer
function World:iterateTokenPool()
    return pairs(self.tokenPool.tokens)
end


function World:_incrementCombo()
    -- (called when a crop is destroyed)
    if isInHarvestScene() and self:_isPlayerCurrentlyHarvesting() then
        self.combo = self.combo + 1
        local dur = self:_getComboDuration()
        self.comboTimeout = math.min(dur, self.comboTimeout + dur*consts.COMBO_HARVEST_INCREMENT_RATIO)
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


function World:_clearEffects()
    self.effectDurations = {}
    self.effects = {}
end



---@private
function World:_updateTokenCount()
    table_clear(self.tokenCounts)
    self.bossToken = nil
    for _, t in ipairs(self.tokens) do
        ---@cast t g.Token
        self.tokenCounts[t.type] = (self.tokenCounts[t.type] or 0) + 1
        if t.bossfight then
            self.bossToken = t
        end
    end
end


---@param tok_id string
---@return integer
function World:getTokenCount(tok_id)
    return self.tokenCounts[tok_id] or 0
end


function World:_getComboDuration()
    local t
    if self.combo < 10 then
        t = 4
    elseif self.combo < 50 then
        t = helper.remap(self.combo, 10, 50, 4, 1)
    elseif self.combo < 200 then
        t = helper.remap(self.combo, 50, 200, 1, 0.3)
    else
        local dur = helper.remap(self.combo, 200, 1000, 0.3, 0.05)
        t = helper.clamp(dur, 0.01, 1)
    end
    return t / consts.COMBO_HARVEST_INCREMENT_RATIO
end



local WORLD_TILESETS = {
    {
        tileset = "harvestarea_tilemap_0",
        dark = objects.Color("#" .. "FF20A362"),
        light =objects.Color("#" .. "FF35BA64") 
    },

    {
        tileset = "harvestarea_tilemap_2",
--"FFC9A531"
        dark = objects.Color("#" .. "FFE9A83F"),
        light =objects.Color("#" .."FFD59F31"),
    },

    {
        tileset = "harvestarea_tilemap_1",
        light = objects.Color("#" .. "FF31CFBF"),
        dark = objects.Color("#" .. "FF23B7A9"),
    },
}


---@param self g.World
local function tryUpdateDecorations(self)
    local tw,th = g.getWorldTileDimensions()
    tw,th = tw-1, th-1
    local pres = g.getPrestige()
    local ls = self.lastSeenDimensions
    if tw == ls.x and th == ls.y and ls.prestige == pres then
        return -- Nothing to generate; return early.
    end

    self.lastSeenDimensions = {x=tw, y=th, prestige=pres}
    self.decorations = {}

    local w,h = g.getWorldDimensions()

    local ts = WORLD_TILESETS[pres % 3 + 1]
    local darkcol = ts.dark
    local lightcol = ts.light

    -- Create new tile atlas
    self.tilemap = helper.splitTileImage(ts.tileset, consts.WORLD_TILE_SIZE)

    local SIZE_MULT = math.sqrt(g.stats.WorldTileSize / g.getStatBaseValue("WorldTileSize"))
    --====== add big-splotch decorations:  ======
    local BIGPAD=30
    for i=1,40*SIZE_MULT do
        table.insert(self.decorations, {
            x = math.floor(helper.lerp(BIGPAD, w-BIGPAD, love.math.random())),
            y = math.floor(helper.lerp(BIGPAD, h-BIGPAD, love.math.random())),
            image = "decor_big_" .. love.math.random(1,4),
            color = darkcol
        })
    end

    --====== add splotch decorations:  ======
    -- local originalCol = "#" .. "ff2bae62"
    -- local col = objects.Color("#" .. "FF1E954F")
    local PAD=12
    for i=1,60*SIZE_MULT do
        table.insert(self.decorations, {
            x = math.floor(helper.lerp(PAD, w-PAD*2, love.math.random())),
            y = math.floor(helper.lerp(PAD, h-PAD*2, love.math.random())),
            image = "decor_splotch_" .. love.math.random(1,5),
            color = darkcol
        })
    end

    local TPAD=30
    for i=1,30*SIZE_MULT do
        table.insert(self.decorations, {
            x = math.floor(helper.lerp(TPAD, w-TPAD*2, love.math.random())),
            y = math.floor(helper.lerp(TPAD, h-TPAD*2, love.math.random())),
            image = "decor_tex_" .. love.math.random(1,5),
            color = lightcol
        })
    end
end



---@param tok g.Token
---@param isPlayerCurrentlyHarvesting boolean
local function shouldIncludeToken(tok, isPlayerCurrentlyHarvesting)
    return isPlayerCurrentlyHarvesting or (not tok.flight)
end

---@param dt number
function World:_update(dt)
    tryUpdateDecorations(self)

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

    -- Player avatar
    if not self.playerAvatar or not self.entities:has(self.playerAvatar) then
        local wx, wy = g.getWorldDimensions()
        self.playerAvatar = g.spawnEntity("avatar", wx / 2, wy / 2)
    end

    self.resourcesPerSecond = {}
    for resId, collector in pairs(self.dataCollectors or {}) do
        self.resourcesPerSecond[resId] = collector:avgdiff()
    end

    -- update TokenPool
    local tp = TokenPool()
    g.call("populateTokenPool", tp)
    g.call("depopulateTokenPool", tp)
    self.tokenPool = tp

    local isPlayerCurrentlyHarvesting = self:_isPlayerCurrentlyHarvesting()

    self.tokenPartition:clear()
    for _, t in ipairs(self.tokens) do
        -- dont include flying tokens when player isnt there.
        if shouldIncludeToken(t, isPlayerCurrentlyHarvesting) then
            self.tokenPartition:add(t, t.x,t.y)
        end
    end
    self:_updateTokenCount()

    -- Effects should only tick down when player is harvesting.
    -- (Or else it will tick down when player is in another scene!)
    if self:_isPlayerCurrentlyHarvesting() then
        -- Update effect durations (iterate backward)
        for i = #self.effects, 1, -1 do
            local eff = self.effects[i]
            self.effectDurations[eff] = self.effectDurations[eff] - dt

            if self.effectDurations[eff] <= 0 then
                table.remove(self.effects, i)
                self.effectDurations[eff] = nil
            end
        end
    end

    -- Update token
    for _, tok in ipairs(self.tokens) do
        if shouldIncludeToken(tok, isPlayerCurrentlyHarvesting) then
            updateToken(tok, dt)
        end
    end

    -- Update effects
    for _, effct in ipairs(self.effects) do
        local einfo = g.getEffectInfo(effct)
        if einfo and einfo.update then
            local dur = self.effectDurations[effct]
            einfo.update(dur, dt)
        end
    end

    local tree = g.getUpgTree()

    local spawnEntityCounts = {--[[
        [upgradeId] -> how many entities should exist
    ]]}
    for _, upg in ipairs(tree:getAllUpgrades()) do
        local upgId = upg.id
        local ulevel = upg.level
        local uinfo = g.getUpgradeInfo(upgId)

        if uinfo.spawnEntity then
            local ecount = 0
            if ulevel > 0 then
                if uinfo.getEntityCount then
                    ecount = math.max(uinfo:getEntityCount(ulevel), 0)
                else
                    ecount = 1
                end
            end
            spawnEntityCounts[upgId] = (spawnEntityCounts[upgId] or 0) + ecount
        end
    end

    for upgradeId, ecount in pairs(spawnEntityCounts) do
        local uinfo = g.getUpgradeInfo(upgradeId)
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

    self.entities:flush() -- flush one more time in case entities are removed

    -- These entity table and function is for singular token collision
    -- Define the function on outer loop for optimization reasons.
    ---@type g.Token[]
    local collidedTokens = {}
    ---@param tok g.Token
    local function collectCollidedTokens(tok)
        if not tok.___destroyed then
            collidedTokens[#collidedTokens+1] = tok
        end
        return false
    end

    ---@type table<integer, table<string, g.Entity[]>>
    local orbitRingStack = {}
    for _, e in ipairs(self.entities) do
        ---@cast e g.Entity
        if e.update then
            e:update(dt)
        end

        if e.bulgeAnimation then
            local blg = assert(e.bulgeAnimation)
            blg.time = math.max(0, blg.time - dt)
        end

        if e.hitToken then
            local entCooldown = e.hitToken.cooldown or 0.4
            local cd0 = math.min(self.entitiesToHitCooldown[e] or 0, entCooldown)
            local cooldown = math.max(cd0 - dt, 0)
            self.entitiesToHitCooldown[e] = cooldown

            if cooldown <= 0 then
                self.tokenPartition:query(e.x, e.y, collectCollidedTokens, e.hitToken.radius)

                if #collidedTokens > 0 then
                    local tok = selectNearestToken(e.x, e.y, e.hitToken.radius, collidedTokens)

                    if tok then
                        e.hitToken.collision(e, tok)
                        self.entitiesToHitCooldown[e] = entCooldown
                    end

                    table.clear(collidedTokens)
                end
            end
        end

        -- For orbit rings, we'll update their position
        -- but we need to do it in multiple passes.
        -- Also only add to list if mouse harvester is enabled.
        if self.mouseX and e.orbitRing then
            local ringIndex = math.floor(e.orbitRing)
            local ring = orbitRingStack[ringIndex]
            if not ring then
                ring = {}
                orbitRingStack[ringIndex] = ring
            end

            local ents = ring[e.type]
            if not ents then
                ents = {}
                ring[e.type] = ents
            end

            ents[#ents+1] = e
        end

        if e.lifetime then
            e.lifetime = e.lifetime - dt
            if e.lifetime <= 0 then
                self.entities:removeBuffered(e)
            end
        end
    end

    -- Update orbit ring positions (this has multiple pass for each ring)
    self.orbitAngle = (self.orbitAngle + g.stats.OrbitSpeed * dt) % (2 * math.pi)
    for ringIndex, ring in pairs(orbitRingStack) do
        ---@type string[]
        local etypes = {}
        local count = 0

        -- Pass 1: Get etypes and total entities
        for k, v in pairs(ring) do
            etypes[#etypes+1] = k
            count = count + #v
        end

        ---@type g.Entity[]
        local entsToBeUpdated = {}
        -- Pass 2: Pop each type in round-robin fashion
        repeat
            local noMorePops = true
            for _, etype in ipairs(etypes) do
                -- Ideally we want to pop etype from etypes if it's 0 but
                -- that feels like an unnecessary optimization.
                if #ring[etype] > 0 then
                    noMorePops = false
                    entsToBeUpdated[#entsToBeUpdated+1] = table.remove(ring[etype])
                end
            end
        until noMorePops

        -- Pass 3: Update the entity positions
        for i, e in ipairs(entsToBeUpdated) do
            -- Note: This always has non-nil `self.mouseX` and `self.mouseY`
            -- because entities are queued to orbitRingStack only if mouse
            -- harvester is enabled in the first place.
            local mx = assert(self.mouseX)
            local my = assert(self.mouseY)
            local dir = (ringIndex % 2) * 2 - 1
            local rot = self.orbitAngle + i * 2 * math.pi / #entsToBeUpdated
            local dist = g.stats.HarvestArea/2 + (ringIndex - 0.5) * consts.ORBIT_RING_DISTANCE
            e.x = mx + math.sin(rot * dir) * dist
            e.y = my + math.cos(rot * dir) * dist
        end
    end

    if self.mouseX then
        updateHarvestCircle(self, dt)
    end

    self.tokens:flush() -- flush once again in case there are some destroyed tokens
    self:_updateTokenCount()

    -- respawn tokens that died
    local curTime = g.getWorldTime()
    for tokType, poolCount in pairs(self.tokenPool.tokens) do
        local ct = self.tokenCounts[tokType] or 0
        local toSpawn = poolCount - ct
        self.tokenDestroyTime[tokType] = self.tokenDestroyTime[tokType] or {}
        local buf = self.tokenDestroyTime[tokType]

        local cooldownTime = g.stats.TokenRespawnTime * math.abs(g.ask("getPerTokenRespawnTimeMultiplier", tokType))

        if #buf < toSpawn then
            -- #destroyTime + tokenCount is less than tokenPool. Spawn more
            for i = 1, toSpawn - #buf do
                buf[#buf+1] = curTime + 0.1 * i - cooldownTime
            end
        end

        if #buf > math.max(toSpawn, 0) then
            -- Too many tokens! truncate table.
            -- (this can happen if there are tokens queued for respawn, 
            --  but then another system, eg green-mushroom, spawns new stuff immediately)
            table.sort(buf)
            while #buf > math.max(toSpawn, 0) do
                table.remove(buf)
            end
        end

        for i = #buf, 1, -1 do
            if curTime >= (buf[i] + cooldownTime) then
                local x,y = g.getRandomPositionForToken()
                if x and y then
                    local tok = g.spawnToken(tokType, x,y)
                    tok.wasSpawnedViaTokenPool = true
                    table.remove(buf, i)
                end
            end
        end
    end

    -- Update combo
    do
        -- Only count down timer if player is actively harvesting
        if isInHarvestScene() and self:_isPlayerCurrentlyHarvesting() then
            self.comboTimeout = math.max(self.comboTimeout - dt, 0)
        end
        if self.comboTimeout <= 0 then
            self.combo = 0
        end
    end

    -- Run per second update event bus on upgrades
    self.timer = self.timer + dt
    while self.timer >= 1 do
        self.seconds = self.seconds + 1

        achievements.emitPerSecondUpdate()

        for _, ent in ipairs(self.entities) do
            if ent.perSecondUpdate then
                ent:perSecondUpdate(self.seconds)
            end
        end

        for _, tok in ipairs(self.tokens) do
            if tok.perSecondUpdate then
                if shouldIncludeToken(tok, isPlayerCurrentlyHarvesting) then
                    tok:perSecondUpdate(self.seconds)
                end
            end
        end

        g.call("perSecondUpdate", self.seconds)
        updateResourceDataCollection(self)
        self.timer = self.timer - 1

        self.analyticsSendTime = self.analyticsSendTime + 1
        if self.analyticsSendTime >= consts.ANALYTICS_UPDATE_INTERVAL then
            analytics.send("update")
            self.analyticsSendTime = 0
        end
    end

    self.tokens:flush()

    self.particles:update(dt)
    self:_updateDamageNumbers(dt)
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
local DAMAGE_NUMBER_SPARKLE_TIME = 0.03
-- If the indices (computed using above variable) is out-of-range, remove the damage numbers.
local DAMAGE_NUMBER_SPARKLE_ASSETS = {"damage_number_sparkle_1", "damage_number_sparkle_2"}

---@param num number
---@param x number
---@param y number
---@param col objects.Color
function World:_spawnDamageNumber(num, x, y, col)
    -- Limit to 100 damage numbers at a time
    if #self.damageNumbers >= 100 then return end

    self.damageNumbers[#self.damageNumbers+1] = {
        color = col,
        number = num,
        x = x + helper.lerp(-3, 3, love.math.random()),
        y = y + helper.lerp(-5, 1, love.math.random()),
        lifetime = DAMAGE_NUMBER_LIFETIME,
    }
end

---@param dt number
---@private
function World:_updateDamageNumbers(dt)
    for i = #self.damageNumbers, 1, -1 do
        local dn = self.damageNumbers[i]
        dn.lifetime = dn.lifetime - dt

        if dn.lifetime < 0 then
            local sparkidx = math.ceil(-dn.lifetime / DAMAGE_NUMBER_SPARKLE_TIME)
            if not DAMAGE_NUMBER_SPARKLE_ASSETS[sparkidx] then
                table.remove(self.damageNumbers, i)
            end
        end
    end

    table.sort(self.damageNumbers, sortOrder)
end

---@private
function World:_drawDamageNumbers()
    prof_push("World:_drawDamageNumbers")

    local smallFont = g.getSmallFont(16)
    local fontHeight = smallFont:getHeight()
    prof_push("draw numbers")
    for _, dn in ipairs(self.damageNumbers) do
        if dn.lifetime >= 0 then
            love.graphics.setColor(dn.color)
            local tspawn = helper.clamp((DAMAGE_NUMBER_LIFETIME - dn.lifetime) / DAMAGE_NUMBER_POPUP_TIME, 0, 1)
            local scale = math.max(helper.EASINGS.easeOutBack(tspawn) ^ 3, 0)
            local text = g.formatNumber(dn.number)
            local width = smallFont:getWidth(text)
            helper.printTextOutlineSimple(text, smallFont, 1, dn.x, dn.y, 0, scale, scale, width / 2, fontHeight / 2)
        end
    end
    prof_pop() -- prof_push("draw numbers")

    prof_push("draw sparks")
    for _, dn in ipairs(self.damageNumbers) do
        if dn.lifetime < 0 then
            love.graphics.setColor(dn.color)
            local sparkidx = math.ceil(-dn.lifetime / DAMAGE_NUMBER_SPARKLE_TIME)
            g.drawImage(DAMAGE_NUMBER_SPARKLE_ASSETS[sparkidx], dn.x, dn.y)
        end
    end
    prof_pop() -- prof_push("draw sparks")

    prof_pop() -- prof_push("World:_drawDamageNumbers")
end



return World
