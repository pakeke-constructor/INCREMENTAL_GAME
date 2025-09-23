--[[

World

The world is a container for tokens and entities.

]]


---@class g.World
---@field entities objects.BufferedSet
---@field tokens objects.BufferedSet
---@field tokensBeingHit {[table]: number}
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
local MIN_HOVER_TIME = 0.2


function World:init()
    self.tokens = objects.BufferedSet()
    self.entities = objects.BufferedSet()

    self.tokenPartition = objects.Partition(20)

    self.mouseX, self.mouseY = nil,nil

    self.tokensBeingHit = ({--[[
        [token] -> duration_of_hit
    ]]})

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

local function drawToken(tok)
    love.graphics.setColor(1,1,1,1)
    -- TODO: add extra stuff here like scale, shear, etc.
    g.drawImage(tok.image, tok.x, tok.y)
    drawTokenHealthBar(tok)
end


function World:_draw()
    local w,h = self.WIDTH, self.HEIGHT
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", 0,0, w,h)

    -- drawGround()

    for _, tok in ipairs(self.tokens) do
        drawToken(tok)
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
    tp:add("basic_grass", 20) --  add grass by default.
    -- TODO: in future, only add default-grass if we are on prestige-1.
    self.tokenPool = tp


    self.tokenPartition:clear()
    for _, t in ipairs(self.tokens) do
        self.tokenPartition:add(t, t.x,t.y)
    end

    for token, time in pairs(self.tokensBeingHit) do
        time = time - dt
        if time <= 0 then
            -- hit has been completed!
            self.tokensBeingHit[token] = nil
        else
            self.tokensBeingHit[token] = time
        end
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
