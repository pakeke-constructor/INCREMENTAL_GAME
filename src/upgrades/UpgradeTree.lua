
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
- 

]]


---@class g.UpgradeTree.Upgrade
---@field upgradeId string
---@field level integer
---@field price integer
---@field x integer
---@field y integer
---@field isRoot boolean?
local Upgrade = {}


---@class g.UpgradeTree: objects.Class
---@field upgrades table<integer, g.UpgradeTree.Upgrade>
---@field connections [integer, integer][]
local UpgradeTree = objects.Class("g:UpgradeTree")


---@param fromJson string
function UpgradeTree:init(fromJson)
    self.upgrades = {--[[
        [(x,y)] -> Upgrade{x,y,upgradeId,level,price}
    ]]}
    self.connections = {--[[
        [(x,y)] -> true
    ]]}

    self.distances = {--[[
        [(x,y)] -> distanceFromRoot
    ]]}
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
    return self.upgrades[i]
end



---@param x integer
---@param y integer
---@param upgradeId string
function UpgradeTree:put(x,y, upgradeId)
    -- used when generating upgrade-tree
    local i = pair(x,y)
    self.upgrades[i] = {
        upgradeId = upgradeId,
        x=x,
        y=y,
        price=-1,
        level=0
    }
end


---@param upg g.UpgradeTree.Upgrade
---@param price number
function UpgradeTree:setPrice(upg, price)
    upg.price = price
end

---@param upg g.UpgradeTree.Upgrade
---@param level number
function UpgradeTree:setLevel(upg, level)
    upg.level = level
end


function UpgradeTree:setRoot()

end



local DIRECTIONS = {{1,0}, {-1,0}, {0,1}, {0,-1}}

---@param x number
---@param y number
---@return g.UpgradeTree.Upgrade[]
function UpgradeTree:getNeighbors(x,y)
    local neighbors = {}
    local visited = {}
    local queue = {}

    local function markVisited(px, py)
        visited[pair(px, py)] = true
    end

    local function isConnector(px, py)
        return self.connections[pair(px,py)]
    end

    local function isVisited(px, py)
        return visited[pair(px, py)]
    end

    local function enqueue(px, py)
        if not isVisited(px, py) then
            -- table.insert(queue, {x = px, y = py})
            table.insert(queue, pair(px,py))
            markVisited(px, py)
        end
    end

    markVisited(x, y)

    for _, dir in ipairs(DIRECTIONS) do
        local nx, ny = x + dir[1], y + dir[2]
        if self:get(nx, ny) then  -- Check if valid cell
            enqueue(nx, ny)
        end
    end

    -- BFS 
    while #queue > 0 do
        local current = table.remove(queue, 1)
        local cx, cy = unpair(current)

        local upg = self.upgrades[pair(cx, cy)]
        if upg then
            table.insert(neighbors, upg)
        elseif isConnector(cx, cy) then
            for _, dir in ipairs(DIRECTIONS) do
                local nx, ny = cx + dir[1], cy + dir[2]
                if self:get(nx, ny) and not isVisited(nx, ny) then
                    enqueue(nx, ny)
                end
            end
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




function UpgradeTree:getVisibleUpgrades()
    local buf = {}
end


function UpgradeTree:distanceFromRoot(x,y)
    -- gets the distance from the root upgrade
    -- (manhattan distance)

end


function UpgradeTree:iterateAllUpgrades()
    return pairs(self.upgrades)
end


function UpgradeTree:iterateAllConnections()
    local i = nil
    local val
    return function()
        i, val = next(self.connections, i)
        if not i then
            return nil
        end
        local x,y = unpair(i)
        return x,y, val
    end
end


return UpgradeTree
