
--[[

Upgrade Tree structure:
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


---@class g.Tree.Upgrade
---@field id string
---@field level integer
---@field basePrice g.Bundle
---@field x integer
---@field y integer
---@field isRoot boolean?
---@field maxLevelOverride number?
---@field connections integer[] list of other upgrades this upgrade is connected to
---@field isUnbound boolean? "unbound" upgrades exist without a position; (ie relics and stuff)
local Upgrade = {}


---@class g.Tree: objects.Class
---@field upgrades table<integer, g.Tree.Upgrade>
---@field connections [integer, integer][]
---@field unboundUpgrades g.Tree.Upgrade[]
---@field _connectionMap table<integer, table<integer, true>>
---@field _distances table<integer, integer>
---@field _filename string?
local Tree = objects.Class("g:Tree")


if false then
    ---@return g.Tree
    function Tree() end ---@diagnostic disable-line: cast-local-type, missing-return
end


function Tree:init()
    self.upgrades = {--[[
        [(x,y)] -> Upgrade{x,y,id,level,basePrice}
    ]]}
    self.connections = {} -- List< (x,y), (x,y) >

    self.unboundUpgrades = {} -- g.Tree.Upgrade[]

    self._connectionMap = {--[[
        -- for efficient indexing:
        [(x,y)] -> List< (x,y) >
    ]]}
    self._distances = {--[[
        [(x,y)] -> distanceFromRoot
    ]]}

    self._questionCache = {--[[
        question -> {upg1, upg2, upg3 ...}
    ]]}
    self._eventCache = {--[[
        event -> {upg1, upg2, upg3 ...}
    ]]}
    self._filename = nil
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


function Tree:transpose(flipX, flipY)
    local data = self:serialize()
    local keyMap = {}
    local newUpgrades = {}
    for k, upg in pairs(data.upgrades) do
        local nx = flipX and -upg.x or upg.x
        local ny = flipY and -upg.y or upg.y
        upg.x, upg.y = nx, ny
        local newKey = pair(nx, ny)
        keyMap[tonumber(k)] = newKey
        newUpgrades[newKey] = upg
    end
    data.upgrades = newUpgrades
    for _, conn in ipairs(data.connections) do
        conn[1] = keyMap[conn[1]] or conn[1]
        conn[2] = keyMap[conn[2]] or conn[2]
    end
    return Tree.deserialize(data)
end


---@param x integer
---@param y integer
---@return g.Tree.Upgrade upg?
function Tree:get(x,y)
    local i = pair(x,y)
    return (self.upgrades[i])
end


---@param upg g.Tree.Upgrade
---@param basePrice g.Bundle
function Tree:setUpgradeBasePrice(upg, basePrice)
    upg.basePrice = basePrice
end


---@param upg g.Tree.Upgrade
---@param level number
function Tree:setUpgradeLevel(upg, level)
    upg.level = level
end



---@param self g.Tree
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


---@param self g.Tree
local function finalizeConnections(self)
    self._connectionMap = {}
    for i = #self.connections, 1, -1 do
        local tabl = self.connections[i]
        local i1, i2 = tabl[1], tabl[2]
        if (not self.upgrades[i1]) or (not self.upgrades[i2]) then
            -- One of the upgrades has been destroyed!!! remove connections
            table.remove(self.connections, i)
        else
            updateEdge(self, i1, i2)
        end
    end
end

---@param upg1 any
---@param upg2 any
function Tree:addConnection(upg1, upg2)
    local i1 = pair(upg1.x,upg1.y)
    local i2 = pair(upg2.x,upg2.y)
    if i1 == i2 then
        -- wtf lol, same upgrade.
        return
    end

    table.insert(self.connections, {i1, i2})
    updateEdge(self, i1, i2)
end


---@param upg1 g.Tree.Upgrade
---@param upg2 g.Tree.Upgrade
---@return boolean
function Tree:areConnected(upg1, upg2)
    local i1 = pair(upg1.x, upg1.y)
    local i2 = pair(upg2.x, upg2.y)
    return (self._connectionMap[i1] and self._connectionMap[i1][i2]) ~= nil
end


---@param upg1 g.Tree.Upgrade
---@param upg2 g.Tree.Upgrade
function Tree:removeConnection(upg1, upg2)
    local i1 = pair(upg1.x, upg1.y)
    local i2 = pair(upg2.x, upg2.y)
    local found = false
    for i = #self.connections, 1, -1 do
        local conn = self.connections[i]
        if (conn[1] == i1 and conn[2] == i2) or (conn[1] == i2 and conn[2] == i1) then
            table.remove(self.connections, i)
            found = true
        end
    end
    if found then
        self:finalize()
    end
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
    local mult = (uinfo.priceScaling or consts.DEFAULT_UPGRADE_PRICE_SCALING) ^ level
    local mult2 = g.ask("getUpgradePriceMultiplier", uinfo, level)
    val = floorSignificant(val*mult*mult2, 2)
    return val
end


---WARNING: This incurs a table allocation.
---@param upg g.Tree.Upgrade
---@param level integer? Optional; defaults to the current upgrade's level.
---@return g.Bundle
function Tree:getUpgradePrice(upg, level)
    local truePrice
    level = level or upg.level

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



---@param upg g.Tree.Upgrade
---@return integer
function Tree:getUpgradeMaxLevel(upg)
    if upg.maxLevelOverride then
        return upg.maxLevelOverride
    end
    local uinfo = g.getUpgradeInfo(upg.id)
    return uinfo.maxLevel
end



--- This is MUCH more efficient than 
---@param upg g.Tree.Upgrade
---@param level number? Optional; defaults to the current upg's level.
---@return boolean
function Tree:canAffordUpgrade(upg, level)
    local uinfo = g.getUpgradeInfo(upg.id)
    level = level or upg.level

    if uinfo.getPriceOverride then
        local price = uinfo:getPriceOverride(level)
        return g.canAfford(price)
    end

    for res,p in pairs(upg.basePrice) do
        local truePrice = modifyUpgradePrice(uinfo, p, level)
        if truePrice > g.getResource(res) then
            return false -- cant afford
        end
    end
    return true
end



---@param upg g.Tree.Upgrade
---@return boolean wasPurchased
function Tree:tryBuyUpgrade(upg)
    local uinfo = g.getUpgradeInfo(upg.id)
    local maxLevel = self:getUpgradeMaxLevel(upg)
    if upg.level >= maxLevel then
        return false -- already max level
    end
    if self:canAffordUpgrade(upg) then
        local price = self:getUpgradePrice(upg)
        achievements.emitUnlockUpgrade(upg.id, price)
        g.subtractResources(price)
        self:setUpgradeLevel(upg, upg.level + 1)
        return true
    end
    return false
end





local DIRECTIONS = {{1,0}, {-1,0}, {0,1}, {0,-1}}
local EMPTY = {}

---@param x number
---@param y number
---@return g.Tree.Upgrade[]
function Tree:getNeighbors(x,y)
    local neighbors = {}

    for _, dir in ipairs(DIRECTIONS) do
        local nx, ny = x + dir[1], y + dir[2]
        local upg = self:get(nx, ny)
        if upg then  -- Check if valid cell
            table.insert(neighbors, upg)
        end
    end

    local arr = self._connectionMap[pair(x,y)] or EMPTY
    for i in pairs(arr) do
        local upg = self.upgrades[i] -- HACK: using self.upgrades directly
        -- (more efficient tho)
        if upg then
            table.insert(neighbors, upg)
        end
    end

    return neighbors
end



---@param upg g.Tree.Upgrade
---@return g.Tree.Upgrade[]
function Tree:getConnectors(upg)
    local connectors = {}

    local arr = self._connectionMap[pair(upg.x,upg.y)] or EMPTY
    for i in pairs(arr) do
        local u = self.upgrades[i] -- HACK: using self.upgrades directly
        if u then
            table.insert(connectors, u)
        end
    end

    return connectors
end





---@param self g.Tree
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
            distances[pos] = 0xffffffffff -- dont use math.huge, coz that causes json error!
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




---@param self g.Tree
---@param upg g.Tree.Upgrade
local function finalizeBusCacheForUpgrade(self, upg)
    local uinfo = g.getUpgradeInfo(upg.id)

    for key, func in pairs(uinfo) do
        if type(func) == "function"  then
            if g.getQuestionInfo(key) then
                if not self._questionCache[key] then self._questionCache[key] = objects.Set() end
                self._questionCache[key]:add(upg)
            elseif g.isEvent(key) then
                if not self._eventCache[key] then self._eventCache[key] = objects.Set() end
                self._eventCache[key]:add(upg)
            end
        end
    end
end


---@param x integer
---@param y integer
---@param uinfo g.UpgradeInfo
---@param isRoot boolean?
---@return g.Tree.Upgrade
function Tree:put(x,y, uinfo, isRoot)
    -- used when generating upgrade-tree
    local i = pair(x,y)
    local id = uinfo.type
    helper.assert(not self.upgrades[i], "Upgrade already exists here!")
    assert(g.getUpgradeInfo(id), "Invalid upgrade id: " .. id)

    local upg = {
        id = id,
        x=x,
        y=y,
        basePrice={},
        level=0,
        isRoot = isRoot
    }
    self.upgrades[i] = upg

    finalizeBusCacheForUpgrade(self, upg)
    self._distances = calculateDistancesFromRoot(self)
    return self.upgrades[i]
end



---@param x number
---@param y number
function Tree:clear(x,y)
    local i = pair(x,y)
    local upg = self.upgrades[i]
    self.upgrades[i] = nil
    self._distances = calculateDistancesFromRoot(self)

    -- remove from ev/q caches:
    if upg then
        for k,arr in pairs(self._eventCache) do
            arr:remove(upg)
        end
        for k,arr in pairs(self._questionCache) do
            arr:remove(upg)
        end
    end

    self:finalize() -- this is expensive, but robust
    return upg
end



---@param upg g.Tree.Upgrade
---@param nx integer
---@param ny integer
---@return boolean success
function Tree:move(upg, nx, ny)
    local oldX, oldY = upg.x, upg.y
    local oldHash = pair(oldX, oldY)
    local newHash = pair(nx, ny)

    if self.upgrades[newHash] then
        return false
    end

    self.upgrades[oldHash] = nil
    upg.x, upg.y = nx, ny
    self.upgrades[newHash] = upg

    for i = 1, #self.connections do
        local conn = self.connections[i]
        if conn[1] == oldHash then
            conn[1] = newHash
        end
        if conn[2] == oldHash then
            conn[2] = newHash
        end
    end

    self:finalize()
    return true
end



---@param uinfo g.UpgradeInfo
function Tree:addOrUpgradeUnboundUpgrade(uinfo)
    assert(uinfo and uinfo.type)
    for _,upg in ipairs(self:getUnboundUpgrades()) do
        if upg.id == uinfo.type then
            -- there's already a unbound upgrade of this type:
            self:setUpgradeLevel(upg, upg.level + 1)
            return
        end
    end

    local upg = {
        id = uinfo.type,
        x=0,
        y=0,
        basePrice={},
        level=1,
        isUnbound=true
    }

    table.insert(self.unboundUpgrades, upg)
    finalizeBusCacheForUpgrade(self, upg)
end




---@param self g.Tree
---@param upg g.Tree.Upgrade
local function hasAnyFullyPurchasedNeighbors(self, upg)
    local neighs = self:getNeighbors(upg.x, upg.y)
    for _, u in ipairs(neighs) do
        local maxLevel = self:getUpgradeMaxLevel(u)
        if ((u.level >= maxLevel) and (maxLevel ~= 0)) or (u.isRoot) then
            return true
        end
    end
    return false
end

---@param upg g.Tree.Upgrade
function Tree:isUpgradeHidden(upg)
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

    local isHidden = not hasAnyFullyPurchasedNeighbors(self, upg)
    return isHidden
end


---@param upg g.Tree.Upgrade
function Tree:distanceFromRoot(upg)
    -- gets the distance from the root upgrade
    -- (manhattan distance)
    if upg.isRoot then
        return 0
    end
    local i = pair(upg.x,upg.y)
    return self._distances[i]
end


--- gets ALL upgrades, (even unbound ones)
---@return g.Tree.Upgrade[]
function Tree:getAllUpgrades()
    local buf = {}
    for _,upg in pairs(self.upgrades) do
        table.insert(buf,upg)
    end
    for _,upg in ipairs(self.unboundUpgrades) do
        table.insert(buf,upg)
    end
    return buf
end


--- gets upgrades on the tree
---@return g.Tree.Upgrade[]
function Tree:getUpgradesOnTree()
    local buf = {}
    for _,upg in pairs(self.upgrades) do
        table.insert(buf,upg)
    end
    return buf
end


--- gets upgrades that are unbound (ie not on the tree, but still active)
---@return g.Tree.Upgrade[]
function Tree:getUnboundUpgrades()
    local buf = {}
    for _,upg in ipairs(self.unboundUpgrades) do
        table.insert(buf,upg)
    end
    return buf
end






---@param question string
---@param ... unknown
---@return any
function Tree:askUpgrades(question, ...)
    local questionInfo = g.getQuestionInfo(question)
    local reducer = questionInfo.reducer
    local defaultValue = questionInfo.defaultValue

    local result = defaultValue

    ---@type g.Tree.Upgrade[]
    local upgs = self._questionCache[question]
    if not upgs then return defaultValue end

    for _, upg in ipairs(upgs) do
        local level = upg.level
        if level and level > 0 then
            local uinfo = g.getUpgradeInfo(upg.id)
            local answerFunc = uinfo[question]
            if answerFunc then
                local answer = answerFunc(uinfo, level, ...) or defaultValue
                result = reducer(answer, result)
            end
        end
    end

    return result
end



---@param event string
---@param ... unknown
---@return nil
function Tree:callUpgrades(event, ...)
    ---@type g.Tree.Upgrade[]
    local upgs = self._eventCache[event]
    if not upgs then return end

    for _, upg in ipairs(upgs) do
        local level = upg.level
        if level and level > 0 then
            local uinfo = g.getUpgradeInfo(upg.id)
            local eventFunc = uinfo[event]
            if eventFunc then
                eventFunc(uinfo, level, ...)
            end
        end
    end
end




function Tree:finalize()
    self._distances = calculateDistancesFromRoot(self)
    finalizeConnections(self)
    for _,upg in ipairs(self:getAllUpgrades()) do
        finalizeBusCacheForUpgrade(self, upg)
    end
end


local function keysToNumber(t)
    local new = {}
    for k, v in pairs(t) do
        new[tonumber(k)] = v
    end
    return new
end

local function keysToString(t)
    local new = {}
    for k, v in pairs(t) do
        new[tostring(k)] = v
    end
    return new
end


---@param data {upgrades:g.Tree.Upgrade[], connections:[integer,integer][], unboundUpgrades:g.Tree.Upgrade[]}
function Tree.deserialize(data)
    local self = Tree()

    self.upgrades = keysToNumber(data.upgrades or {})
    for hash,upg in pairs(self.upgrades) do
        if not g.isValidUpgrade(upg.id) then
            log.error("UHOH!!! Unknown upgrade, deleting: ", upg.id)
            self.upgrades[hash] = nil
        end
    end

    for i = #data.unboundUpgrades, 1, -1 do
        local upg = data.unboundUpgrades[i]
        if not g.isValidUpgrade(upg.id) then
            log.error("UHOH!!! Unknown UNBOUND upgrade, deleting: ", upg.id)
            table.remove(data.unboundUpgrades, i)
        end
    end

    self.unboundUpgrades = data.unboundUpgrades or {}
    self.connections = data.connections or {}
    self:finalize()
    return self
end


function Tree:serialize()
    return {
        upgrades = keysToString(self.upgrades),
        connections = self.connections,
        unboundUpgrades = self.unboundUpgrades
    }
end




return Tree
