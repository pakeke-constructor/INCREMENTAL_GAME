
--[[

World

The world is a container for harvestable tokens, and other stuff.  
Used by the harvest-scene

]]


---@class world
---@field entities objects.BufferedSet
---@field tokens objects.BufferedSet
---@field tokensBeingHit {[table]: number}
---@field tokenPartition objects.Partition
---@field mouseX number?
---@field mouseY number?
local world = {}

-- Think of this as the "dimensions" of the harvest-area
world.WIDTH = 450
world.HEIGHT = 300


function world._init()
    world.tokens = objects.BufferedSet()
    world.entities = objects.BufferedSet()

    world.tokenPartition = objects.Partition(20)

    world.mouseX, world.mouseY = nil,nil

    world.tokensBeingHit = ({--[[
        [token] -> duration_of_hit
    ]]})
end



local HARVEST_CIRCLE_INSIDE = {0.2,0.2,0.2,0.17}
local HARVEST_CIRCLE_BORDER = {.8,.8,.8}

local function drawHarvestCircle()
    local x,y = assert(world.mouseX), assert(world.mouseY)
    local rad = g.stats.HarvestArea
    love.graphics.setColor(HARVEST_CIRCLE_INSIDE)
    love.graphics.circle("fill", x,y, rad)
    local lw = love.graphics.getLineWidth()
    love.graphics.setLineWidth(math.floor(rad / 15))
    love.graphics.setColor(HARVEST_CIRCLE_BORDER)
    love.graphics.circle("line", x,y, rad)
    love.graphics.setLineWidth(lw)
end


local function updateHarvestCircle()
    local x,y = assert(world.mouseX), assert(world.mouseY)
    world.tokenPartition:query(x,y, function (tok)
        if math.distance(x-tok.x, y-tok.y) <= (g.stats.HarvestArea + consts.HARVEST_AREA_LEEWAY) then
            g.tryHitToken(tok)
        end
    end, g.stats.HarvestArea)
end


function world._enableMouseHarvester(x,y)
    world.mouseX = x
    world.mouseY = y
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


function world._draw()
    local w,h = world.WIDTH, world.HEIGHT
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", 0,0, w,h)

    -- drawGround()

    for _, tok in ipairs(world.tokens) do
        drawToken(tok)
    end

    if world.mouseX then
        drawHarvestCircle()
    end
end


function world._update(dt)
    world.entities:flush()
    world.tokens:flush()

    world.tokenPartition:clear()
    for _, t in ipairs(world.tokens) do
        world.tokenPartition:add(t, t.x,t.y)
    end

    for token, time in pairs(world.tokensBeingHit) do
        time = time - dt
        if time <= 0 then
            -- hit has been completed!
            world.tokensBeingHit[token] = nil
        else
            world.tokensBeingHit[token] = time
        end
    end

    for _, e in ipairs(world.entities) do
        e:update(dt)
    end

    if world.mouseX then
        updateHarvestCircle()
    end

    -- respawn tokens that died
    local tokenCounts = {}
    for _,t in ipairs(world.tokens)do
        tokenCounts[t.type] = (tokenCounts[t.type] or 0) + 1
    end
    for tokType, poolCount in g.iterateTokenPool()do
        local ct = tokenCounts[tokType] or 0
        local toSpawn = poolCount - ct
        for _=1, toSpawn do
            g.spawnToken(tokType, g.getRandomPositionForToken())
        end
    end

    world.tokens:flush()
end




return world

