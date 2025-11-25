
--[[

UpgradeTree structure:
===============================

upgrades = {
    {id="id", x=x,y=y, basePrice=3, level=5},
    {id="id2", x=x,y=y, basePrice=3, level=5},},
    {id="id3", x=x,y=y, basePrice=3, level=5},},
    {connector=true, x=x,y=y}, -- (UPGRADE-CONNECTOR)
    {id="id", x=x,y=y, basePrice=3, level=5},},
}


FEATURES WE NEED:
- iterate over neighbor-upgrades [DONE]
- Get distance to "root" upgrade
- connecting upgrades SIMPLY
- iterate over "frontier" upgrades

]]


---@class g.UpgradeTree.Upgrade
---@field id string
---@field level integer
---@field basePrice g.Bundle
---@field x integer
---@field y integer
---@field isRoot boolean?
local Upgrade = {}


---@class g.UpgradeTree: objects.Class
---@field upgrades table<integer, g.UpgradeTree.Upgrade>
---@field connections [integer, integer][]
---@field _connectionMap table<integer, table<integer, true>>
---@field _distances table<integer, integer>
local UpgradeTree = objects.Class("g:UpgradeTree")


local finalizeConnections

function UpgradeTree:init()
    self.upgrades = {--[[
        [(x,y)] -> Upgrade{x,y,id,level,basePrice}
    ]]}
    self.connections = {} -- List< (x,y), (x,y) >

    self._connectionMap = {--[[
        -- for efficient indexing:
        [(x,y)] -> List< (x,y) >
    ]]}
    self._distances = {--[[
        [(x,y)] -> distanceFromRoot
    ]]}
end


---@param data {upgrades:g.UpgradeTree.Upgrade[], connections:[integer,integer][]}
function UpgradeTree.deserialize(data)
    local self = UpgradeTree()
    self.upgrades = data.upgrades
    self.connections = data.connections
    finalizeConnections(self)
    self._distances = cal
end


function UpgradeTree:serialize()
    return {
        upgrades = self.upgrades,
        connections = self.connections
    }
end



local floor = math.floor

local function pair(x, y)
    local a = x >= 0 and 2 * x or -2 * x - 1
    local b = y >= 0 and 2 * y or -2 * y - 1
    return floor((a + b) * (a + b + 1) / 2) + b
end

local function unpair(num)
    local w = floor((math.sqrt(8 * num + 1) - 1) / 2)
    local t = floor((w * w + w) / 2)
    local b = num - t
    local a = w - b
    local x = a % 2 == 0 and floor(a / 2) or -floor((a + 1) / 2)
    local y = b % 2 == 0 and floor(b / 2) or -floor((b + 1) / 2)
    return x, y
end

--[[
TESTING CANTOR PAIRING:

local errors = 0
for x = -200, 200 do
    for y = -200, 200 do
        local num = pair(x, y)
        local x2, y2 = unpair(num)
        if x ~= x2 or y ~= y2 then
            error(string.format("ERROR: (%d, %d) -> %d -> (%d, %d)", x, y, num, x2, y2))
            errors = errors + 1
        end
    end
end
]]



---@param x integer
---@param y integer
---@return g.UpgradeTree.Upgrade upg
function UpgradeTree:get(x,y)
    local i = pair(x,y)
    return assert(self.upgrades[i])
end


---@param upg g.UpgradeTree.Upgrade
---@param basePrice g.Bundle
function UpgradeTree:setBasePrice(upg, basePrice)
    upg.basePrice = basePrice
end


---@param upg g.UpgradeTree.Upgrade
---@param level number
function UpgradeTree:setLevel(upg, level)
    upg.level = level
end



---@param self g.UpgradeTree
---@param i1 integer
---@param i2 integer
local function updateEdge(self, i1,i2)
    if not (self.upgrades[i1] and self.upgrades[i2]) then
        -- invalid upgrades!
        log.error("Invalid upgrade connection: ", i1,i2)
        return
    end
    local cmap = self._connectionMap
    cmap[i1] = cmap[i1] or {}
    cmap[i2] = cmap[i2] or {}
    cmap[i2][i1] = true
    cmap[i1][i2] = true
end



---@param self g.UpgradeTree
function finalizeConnections(self)
    for tabl in ipairs(self.connections) do
        local i1, i2 = tabl[1],tabl[2]
        updateEdge(self, i1,i2)
    end
end



---@param upg1 any
---@param upg2 any
function UpgradeTree:addConnection(upg1, upg2)
    local i1 = pair(upg1.x,upg1.y)
    local i2 = pair(upg2.x,upg2.y)

    table.insert(self.connections, {i1, i2})
    updateEdge(self, i1, i2)
end





--- Floors a number, removing insignificant digits.
--- Useful for adjusting prices to look a bit "nicer"
---
--- g.floorSignificant(12345, 1) -> 10000
--- g.floorSignificant(12345, 2) -> 12000
--- g.floorSignificant(12345, 3) -> 12300
--- g.floorSignificant(12345, 4) -> 12340
--- g.floorSignificant(12345, 5) -> 12345
---@param value number
---@param nsig integer
---@return integer
local function floorSignificant(value, nsig)
	local zeros = math.floor(math.log10(math.max(math.abs(value), 1)))
	local mulby = 10 ^ (1+math.max(zeros-nsig, -1))
	return math.floor(math.floor(value / mulby) * mulby)
end

local function modifyUpgradePrice(uinfo, val, level)
    level = level or g.getUpgradeLevel(uinfo)
    local mult = (uinfo.priceScaling or consts.DEFAULT_UPGRADE_PRICE_SCALING) ^ level
    local mult2 = g.ask("getUpgradePriceMultiplier", uinfo, level)
    val = floorSignificant(val*mult*mult2, 2)
    return val
end


---WARNING: This incurs a table allocation.
---@param upg g.UpgradeTree.Upgrade
---@param level integer? Optional; defaults to the current upgrade's level.
---@return g.Bundle
function UpgradeTree:getUpgradePrice(upg, level)
    local truePrice
    level = level or self:getUpgradeLevel(upg)

    local uinfo = g.getUpgradeInfo(upg.id)
    if uinfo.getPriceOverride then
        truePrice = uinfo:getPriceOverride(level)
    else
        truePrice = {}
        for resId,val in pairs(upg.basePrice)do
            truePrice[resId] = val
        end
        for _,res in ipairs(g.RESOURCE_LIST)do
            truePrice[res] = modifyUpgradePrice(uinfo, truePrice[res] or 0, level)
        end
    end

    return truePrice
end


--[[
---@param uinfo g.UpgradeInfo
---@param level number? Optional; defaults to the current upgrade's level.
---@return boolean
function g.canAffordUpgrade(uinfo, level)
    level = level or g.getUpgradeLevel(uinfo)
    for res,p in pairs(uinfo.price) do
        local truePrice = modifyUpgradePrice(uinfo, p, level)
        if truePrice > g.getResource(res) then
            return false -- cant afford
        end
    end
    return true
end



---@param uinfo g.UpgradeInfo
---@return boolean wasPurchased
function g.tryBuyUpgrade(uinfo)
    local session = g.getSn()
    local typ = uinfo.type
    if g.getUpgradeLevel(uinfo) >= uinfo.maxLevel then
        return false -- already max level
    end
    if g.canAffordUpgrade(uinfo) then
        local price = g.getUpgradePrice(uinfo)
        g.subtractResources(price)
        session.upgradeLevels[typ] = (session.upgradeLevels[typ] or 0) + 1
        return true
    end
    return false
end

]]




local DIRECTIONS = {{1,0}, {-1,0}, {0,1}, {0,-1}}
local EMPTY = {}

---@param x number
---@param y number
---@return g.UpgradeTree.Upgrade[]
function UpgradeTree:getNeighbors(x,y)
    local neighbors = {}

    for _, dir in ipairs(DIRECTIONS) do
        local nx, ny = x + dir[1], y + dir[2]
        local upg = self:get(nx, ny)
        if upg then  -- Check if valid cell
            table.insert(neighbors, upg)
        end
    end

    local arr = self._connectionMap[pair(x,y)] or EMPTY
    for _, i in ipairs(arr) do
        local upg = self.upgrades[i] -- HACK: using self.upgrades directly
        -- (more efficient tho)
        if upg then
            table.insert(neighbors, upg)
        end
    end

    return neighbors
end



---@param upg g.UpgradeTree.Upgrade
---@return g.UpgradeTree.Upgrade[]
function UpgradeTree:getConnectors(upg)
    local connectors = {}

    local arr = self._connectionMap[pair(upg.x,upg.y)] or EMPTY
    for _, i in ipairs(arr) do
        local u = self.upgrades[i] -- HACK: using self.upgrades directly
        if u then
            table.insert(u)
        end
    end

    return connectors
end







---@param self g.UpgradeTree
---@return table<integer,integer>
local function calculateDistancesFromRoot(self)
    --[[
    updates the distances from root for upgrades
    ]]
    local distances = {}
    local visited = {}
    local pqueue = {} -- Priority queue: array of {x, y, dist}

    for pos, upg in pairs(self.upgrades) do
        if upg.isRoot then
            table.insert(pqueue, {x=upg.x, y=upg.y, dist=0})
            distances[pos] = 0
        else
            distances[pos] = math.huge
        end
    end

    local function pqInsert(x, y, dist)
        local node = {x = x, y = y, dist = dist}
        local inserted = false
        for i = 1, #pqueue do
            if dist < pqueue[i].dist then
                table.insert(pqueue, i, node)
                inserted = true
                break
            end
        end
        if not inserted then
            table.insert(pqueue, node)
        end
    end

    -- Dijkstra's main loop
    while #pqueue > 0 do
        -- Get node with minimum distance
        local current = table.remove(pqueue, 1)
        local cx, cy, cdist = current.x, current.y, current.dist
        local cpair = pair(cx, cy)

        if not visited[cpair] then
            visited[cpair] = true

            local neighbors = self:getNeighbors(cx, cy)

            for _, neighUpg in ipairs(neighbors) do
                local nx, ny = neighUpg.x, neighUpg.y
                local npair = pair(nx, ny)

                if not visited[npair] then
                    local newDist = cdist + 1 -- edge has weight 1

                    if newDist < distances[npair] then
                        distances[npair] = newDist
                        pqInsert(nx, ny, newDist)
                    end
                end
            end
        end
    end

    return distances
end


---@param upg g.UpgradeTree.Upgrade
function UpgradeTree:markAsRoot(upg)
    upg.isRoot = true
    self._distances = calculateDistancesFromRoot(self)
end


---@param x integer
---@param y integer
---@param id string
---@return g.UpgradeTree.Upgrade
function UpgradeTree:put(x,y, id)
    -- used when generating upgrade-tree
    local i = pair(x,y)
    helper.assert(not self.upgrades[i], "Upgrade already exists here!")
    assert(g.getUpgradeInfo(id), "Invalid upgrade id: " .. id)
    self.upgrades[i] = {
        id = id,
        x=x,
        y=y,
        basePrice={},
        level=0
    }

    self._distances = calculateDistancesFromRoot(self)
    return self.upgrades[i]
end


---@param self g.UpgradeTree
---@param upg g.UpgradeTree.Upgrade
local function hasAnyPurchasedNeighbors(self, upg)
    local neighs = self:getNeighbors(upg.x, upg.y)
    for _, u in ipairs(neighs) do
        if (u.level > 0) or (u.isRoot) then
            return true
        end
    end
    return false
end

---@param upg g.UpgradeTree.Upgrade
function UpgradeTree:isUpgradeHidden(upg)
    if upg.level > 0 then
        return false -- cant be hidden if level>0
    end
    if upg.isRoot then
        -- "root" upgrades are always visible
        return false
    end

    local uinfo = g.getUpgradeInfo(upg.id)
    if uinfo.isHidden and uinfo:isHidden() then
        return true
    end

    local isHidden = not hasAnyPurchasedNeighbors(self, upg)
    return isHidden
end


---@param upg g.UpgradeTree.Upgrade
function UpgradeTree:distanceFromRoot(upg)
    -- gets the distance from the root upgrade
    -- (manhattan distance)
    if upg.isRoot then
        return 0
    end
    local i = pair(upg.x,upg.y)
    return self._distances[i]
end


---@return g.UpgradeTree.Upgrade[]
function UpgradeTree:getUpgrades()
    local buf = {}
    for _,upg in pairs(self.upgrades) do
        table.insert(buf,upg)
    end
    return buf
end


return UpgradeTree
