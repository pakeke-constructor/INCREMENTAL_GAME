
--[[

World

The world is a container for harvestable tokens, and other stuff.  
Used by the harvest-scene

]]


---@class world
---@field partition objects.Partition
local world = {}


function world.init()
    world.tokens = objects.BufferedSet()
    world.entities = objects.BufferedSet()

    world.partition = objects.Partition()

    world.tokensBeingHit = setmetatable({--[[
        [token] -> duration_of_hit
    ]]}, {__mode="k"})
end



function world.addEntity(ent)
    assert(type(ent) == "table")
    assert(ent.update)
    assert(ent.type)
    assert(ent.draw)

    world.entities:addBuffered(ent)
end


function world.addToken(tok)
    assert(type(tok) == "table")
    assert(tok.x and tok.y)
    assert(tok.type)

    world.entities:addBuffered(tok)
end




function world.removeEntity(ent)
    world.entities:removeBuffered(ent)
end


function world.removeToken(tok)
    world.tokens:removeBuffered(tok)
end





function world.draw()
    -- drawGround()

    -- drawStuff()
end



function world.tokenExists(tok)
    return world.tokens:has(tok)
end

function world.tryHitToken(tok)
    local time = world.tokensBeingHit[tok]
    if not time then
        world.tokensBeingHit[tok] = 
    end
end



---@class TokenPopulater: objects.Class
local TokenList = objects.Class("world:TokenPopulater")

function TokenList:init()
    self.tokens = {}
end

---@param tokenId string
---@param amount number?
function TokenList:add(tokenId, amount)
    self.tokens[tokenId] = (self.tokens[tokenId] or 0) + (amount or 1)
end

---@param tokenId string
---@return number
function TokenList:get(tokenId)
    return self.tokens[tokenId] or 0
end





function world.update(dt)
    world.entities:flush()
    world.tokens:flush()

    -- update TokenList
    local tp = TokenList()
    g.call("populateTokens", tp)

    -- update partition
    world.partition:clear()
    for _, e in ipairs(world.entities) do
        world.partition:add(e, e.x,e.y)
    end

    for _, e in ipairs(world.entities) do
        e:update(dt)
    end

    world.tokens:flush()
end




return world

