
--[[

UpgradeTree structure:
===============================

upgrades = {
    {upgradeId="id", x=x,y=y, price=3, level=5},
    {upgradeId="id2", x=x,y=y, price=3, level=5},},
    {upgradeId="id3", x=x,y=y, price=3, level=5},},
    {connector=true, x=x,y=y}, -- (UPGRADE-CONNECTOR)
    {upgradeId="id", x=x,y=y, price=3, level=5},},
}


FEATURES WE NEED:
- iterate over neighbor-upgrades [DONE]
- Get distance to "root" upgrade
- connecting upgrades SIMPLY
- iterate over "frontier" upgrades

]]


---@class g.UpgradeTree.Upgrade
---@field upgradeId string
---@field level integer
---@field price g.Bundle
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
        [(x,y)] -> Upgrade{x,y,upgradeId,level,price}
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
---@param price g.Bundle
function UpgradeTree:setPrice(upg, price)
    upg.price = price
end


---@param upg g.UpgradeTree.Upgrade
---@param level number
function UpgradeTree:setLevel(upg, level)
    upg.level = level
end


---@param upg g.UpgradeTree.Upgrade
function UpgradeTree:markAsRoot(upg)
    upg.isRoot = true
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


---@param self g.UpgradeTree
---@param x1 number
---@param y1 number
---@return table<integer,integer>
local function updateWithDijkstra(self, x1, y1)
    assert(self.upgrades[pair(x1, y1)])

    local distances = {}
    local visited = {}
    local pqueue = {} -- Priority queue: array of {x, y, dist}

    for pos, _ in pairs(self.upgrades) do
        distances[pos] = math.huge
    end

    local startPair = pair(x1, y1)
    distances[startPair] = 0
    table.insert(pqueue, {x = x1, y = y1, dist = 0})

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



---@param x integer
---@param y integer
---@param upgradeId string
---@return g.UpgradeTree.Upgrade
function UpgradeTree:put(x,y, upgradeId)
    -- used when generating upgrade-tree
    local i = pair(x,y)
    helper.assert(not self.upgrades[i], "Upgrade already exists here!")
    self.upgrades[i] = {
        upgradeId = upgradeId,
        x=x,
        y=y,
        price={},
        level=0
    }

    updateWithDijkstra(self, x,y)
    return self.upgrades[i]
end




function UpgradeTree:getVisibleUpgrades()
    local buf = {}
    -- TODO.
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


function UpgradeTree:iterateAllUpgrades()
    return pairs(self.upgrades)
end


function UpgradeTree:iterateAllConnections()
    -- (untested)
    local i = 1
    return function()
        local t = self.connections[i]
        if not t then
            return nil
        end
        local i1,i2 = t[1],t[2]
        local upg1 = self.upgrades[i1]
        local upg2 = self.upgrades[i2]
        i = i + 1
        return upg1, upg2
    end
end


return UpgradeTree
