
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


]]


---@class g.UpgradeTree.Upgrade
---@field uinfo g.UpgradeInfo
---@field level integer
---@field price integer
---@field x integer
---@field y integer
local Upgrade = {}


---@class g.UpgradeTree: objects.Class
---@field upgrades table<integer, g.UpgradeTree.Upgrade>
---@field connections table<integer, {x:integer,y:integer}>
local UpgradeTree = objects.Class("g:UpgradeTree")


---@param fromJson string
function UpgradeTree:init(fromJson)
    self.upgrades = {}
    self.connections = {}
    self.prices = {}

    self.levels = {}
end


function UpgradeTree:serialize()

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
---@param uinfo g.UpgradeInfo
function UpgradeTree:put(x,y, uinfo)
    -- used when generating upgrade-tree
    local i = pair(x,y)
    self.upgrades[i] = {
        uinfo = uinfo,
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



---@param x number
---@param y number
---@return table
function UpgradeTree:getNeighbors(x,y)
    local neighbors = {}
    local visited = {}
    local queue = {}
    
    -- Helper to mark as visited
    local function markVisited(px, py)
        visited[pair(px, py)] = true
    end

    local function isVisited(px, py)
        return visited[pair(px, py)]
    end

    local function enqueue(px, py)
        if not isVisited(px, py) then
            table.insert(queue, {x = px, y = py})
            markVisited(px, py)
        end
    end

    markVisited(x, y)


    local directions = {{1,0}, {-1,0}, {0,1}, {0,-1}}
    for _, dir in ipairs(directions) do
        local nx, ny = x + dir[1], y + dir[2]
        if self:get(nx, ny) then  -- Check if valid cell
            enqueue(nx, ny)
        end
    end

    -- bfs:
    while #queue > 0 do
        local current = table.remove(queue, 1)
        local cx, cy = current.x, current.y


        local upg = self.upgrades[pair(cx, cy)]
        if upg then
            table.insert(neighbors, upg)
        elseif isConnector(self, cx, cy) then
            for _, dir in ipairs(directions) do
                local nx, ny = cx + dir[1], cy + dir[2]
                if self:get(nx, ny) and not isVisited(nx, ny) then
                    enqueue(nx, ny)
                end
            end
        end
    end

    return neighbors
end



function UpgradeTree:iterateVisibleUpgrades()

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
