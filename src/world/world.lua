
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
---@field _internal table
local world = {}

-- Think of this as the "dimensions" of the harvest-area
world.WIDTH = 800
world.HEIGHT = 600


function world.init()
    world.tokens = objects.BufferedSet()
    world.entities = objects.BufferedSet()

    world.tokenPartition = objects.Partition(20)

    world.mouseX, world.mouseY = nil,nil

    world.tokensBeingHit = setmetatable({--[[
        [token] -> duration_of_hit
    ]]}, {__mode="k"})
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
        g.tryHitToken(tok)
    end, g.stats.HarvestArea)
end


function world._internal.enableMouseHarvester(x,y)
    world.mouseX = x
    world.mouseY = y
end



function world._internal.draw()
    local w,h = world.WIDTH, world.HEIGHT
    love.graphics.setColor(0,0,0)
    love.graphics.rectangle("line", 0,0, w,h)

    -- drawGround()

    -- drawStuff()

    if world.mouseX then
        drawHarvestCircle()
    end
end


function world._internal.update(dt)
    world.entities:flush()
    world.tokens:flush()

    world.tokenPartition:clear()
    for _, t in ipairs(world.tokens) do
        world.tokenPartition:add(t, t.x,t.y)
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
    for tokenType, poolCount in g.iterateTokenPool()do
        local ct = tokenCounts[tokenType] or 0
        if poolCount > ct then
            -- spawn new
        end
    end

    world.tokens:flush()
end




return world

