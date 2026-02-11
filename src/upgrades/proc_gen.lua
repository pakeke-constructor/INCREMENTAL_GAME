

local procGen = {}

local Tree = require("src.upgrades.Tree")

--[[

## proc gen tree core ideas:
CORE IDEA: Make the player kinda OP; this ensures they dont get stuck ever
in a perfect world:
we would have the tree perfectly balanced.
But thats not possible
so if we had to choose between player being slightly OP, or slightly underpowered:
--> DEFINITELY choose OP; since its more exciting

## To accomplish this:
- Make sure there are lots of cheap crops early in the tree.

- **IMPORTANT**: Make sure there are LOTS of connections. Eg in normal tree, there are only horizontal connections. Proc gen tree should ALWAYS have diagonal connections
^^^ reason we do this, is so player doenst get stuck. And theres always options.


## implementation details:
- Generate tree structure FIRST
    - For now, just do a simple walk.
- Create a function randomUpgrade(tree, x,y) that returns a random upgrade id, based on procGen weight. (Favours token upgrades closer to root)
- Populate tree with random upgrades
- (Further away nodes = cost more)


## IMPORTANT AGENT INSTRUCTIONS:
Read and understand `src/upgrades/Tree.lua`.
You must understand upgrade-definitions; g.defineUpgrade
You must also understand `g.UpgradeInfo.procGen` table, and how it relates to upgrade-definitions
Read src/modules/objects/Grid.lua

]]


---@class g.UpgradeDefinition._ProcGen
---@field weight number The rarity-weight of upgrade
---@field distance [integer,integer] [min,max] distance from root node when generating. A root node has level > 0. E.g. if distance = {1,3}, that means it MUST be between 1 and 3 jumps to a root node.
---@field needs string? a dependency to another upgrade. Eg: "better_slime" upgrade requires "slime" upgrade as a pre-requisite.
--- this class tells the system: "Hey, this upgrade will be procedurally generated!"
local g_UpgradeDefinition_ProcGen




local MAX_PRICE = 500000

---@param upg g.Tree.Upgrade
---@param dist number
---@param resources g.ResourceType[]
---@return table
local function getPrice(upg, dist, resources)
    local rand = love.math.random
    local uinfo = g.getUpgradeInfo(upg.id)
    local mult = 0.9+(rand()/5)
    local isToken = uinfo.kind == "TOKEN"
    if isToken then
        mult = mult / 2 -- token upgrades are half the cost!
    end
    local moneyVal = math.min(MAX_PRICE, math.floor(mult * 10 * (4.5 ^ (dist + rand()/10))))
    local price = {money = moneyVal}
    if isToken and rand() < 0.3 and #resources > 0 then
        local res = resources[rand(#resources)]
        price[res] = math.floor(moneyVal * 0.1)
    end
    return price
end


local GRID_SIZE = 100
local OFFSET = 50 -- grid coords offset; world (0,0) = grid (50,50)

local DIRS = {
    {1,0}, {-1,0}, {0,1}, {0,-1},
    {1,1}, {1,-1}, {-1,1}, {-1,-1}
}

local BLOCK_RADIUS_SQ = 0.4 * 0.4

local function hasBlockingNode(grid, gx1, gy1, gx2, gy2)
    local dx, dy = gx2 - gx1, gy2 - gy1
    local len2 = dx*dx + dy*dy
    local minx, maxx = math.min(gx1, gx2) - 1, math.max(gx1, gx2) + 1
    local miny, maxy = math.min(gy1, gy2) - 1, math.max(gy1, gy2) + 1
    for x = minx, maxx do
        for y = miny, maxy do
            if not (x == gx1 and y == gy1) and not (x == gx2 and y == gy2)
               and grid:contains(x, y) and grid:get(x, y) then
                local px, py = x - gx1, y - gy1
                local t = (px*dx + py*dy) / len2
                if t > 0 and t < 1 then
                    local ex, ey = gx1 + t*dx - x, gy1 + t*dy - y
                    if ex*ex + ey*ey < BLOCK_RADIUS_SQ then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- {dx, dy, probability} — "forward" offsets only (dx>0, or dx==0 and dy>0) to avoid dupes
local CONNECT_OFFSETS = {
    {1,1, 0.9}, {1,-1, 0.9},                       -- diagonal adjacent
    {2,0, 0.5}, {0,2, 0.5},                         -- dist 2 cardinal
    {2,1, 0.4}, {2,-1, 0.4}, {1,2, 0.4}, {1,-2, 0.4}, -- dist ~2.2
    {2,2, 0.25}, {2,-2, 0.25},                      -- dist ~2.8
    {3,0, 0.2}, {0,3, 0.2},                         -- dist 3
    {3,1, 0.15}, {3,-1, 0.15}, {1,3, 0.15}, {1,-3, 0.15}, -- dist ~3.2
}

function procGen.generateTreeShape(numNodes)
    numNodes = numNodes or 80

    local grid = objects.Grid(GRID_SIZE, GRID_SIZE) -- true = node exists
    local connections = {} -- {x1=int,y1=int, x2=int,y2=int}[]
    local cells = {} -- flat list: {gx1,gy1, gx2,gy2, ...}

    grid:set(OFFSET, OFFSET, true)
    cells[1], cells[2] = OFFSET, OFFSET

    -- Grow tree from random existing cells (generate extra to account for holes)
    local totalNodes = numNodes + math.floor(numNodes * 0.3)
    while #cells < totalNodes * 2 do
        local i = love.math.random(#cells / 2) * 2 - 1
        local gx, gy = cells[i], cells[i+1]
        local d = DIRS[love.math.random(#DIRS)]
        local nx, ny = gx + d[1], gy + d[2]
        if grid:contains(nx, ny) and not grid:get(nx, ny) then
            grid:set(nx, ny, true)
            cells[#cells+1] = nx
            cells[#cells+1] = ny
            -- cardinal connections added implicitly by getNeighbors
        end
    end

    -- Punch random holes to break up clumps
    local HOLE_CHANCE = 0.3
    for i = 1, #cells-1 do
        local gx, gy = cells[i], cells[i+1]
        if not (gx == OFFSET and gy == OFFSET) and love.math.random() < HOLE_CHANCE then
            grid:set(gx, gy, false)
        end
    end

    -- Add line-of-sight connections
    grid:foreach(function(val, gx, gy)
        if not val then return end
        for _, off in ipairs(CONNECT_OFFSETS) do
            local nx, ny = gx + off[1], gy + off[2]
            if grid:contains(nx, ny) and grid:get(nx, ny)
               and not hasBlockingNode(grid, gx, gy, nx, ny)
               and love.math.random() < off[3] then
                table.insert(connections, {x1=gx-OFFSET, y1=gy-OFFSET, x2=nx-OFFSET, y2=ny-OFFSET})
            end
        end
    end)

    return grid, connections
end



local function weightedPick(list)
    local total = 0
    for _, e in ipairs(list) do total = total + e.weight end
    local r = love.math.random() * total
    for _, e in ipairs(list) do
        r = r - e.weight
        if r <= 0 then return e end
    end
    return list[#list]
end

local function upgradeMatchesResources(id, resourceSet)
    local uinfo = g.getUpgradeInfo(id)
    if uinfo.procGen.resource and not resourceSet[uinfo.procGen.resource] then
        return false
    end
    if uinfo.kind == "TOKEN" then
        local tinfo = g.getTokenInfo(uinfo.tokenType)
        for resId, val in pairs(tinfo.resources) do
            if val > 0 and not resourceSet[resId] then return false end
        end
    end
    return true
end

local function getProcGenUpgrades()
    local out = {}
    for _, id in ipairs(g.UPGRADE_LIST) do
        local uinfo = g.getUpgradeInfo(id)
        if uinfo.procGen then
            local pg = uinfo.procGen
            out[#out+1] = {id = id, weight = pg.weight, dist = pg.distance, needs = pg.needs, resource = pg.resource}
        end
    end
    return out
end

function procGen.placeUpgrades(grid, connections)
    local tree = Tree()
    local placeholder = g.getUpgradeInfo("grass_1")

    -- Pick 2-3 resources (money + 1-2 random)
    local resources = {"money"}
    local num = love.math.random(2, 3)
    while #resources < num do
        local r = g.RESOURCE_LIST[love.math.random(#g.RESOURCE_LIST)]
        local found = false
        for _, v in ipairs(resources) do if v == r then found = true; break end end
        if not found then resources[#resources+1] = r end
    end
    local resourceSet = {}
    for _, r in ipairs(resources) do resourceSet[r] = true end

    -- initialize tree wth placeholder nodes
    grid:foreach(function(val, gx, gy)
        if not val then return end
        local x, y = gx - OFFSET, gy - OFFSET
        local isRoot = (x == 0 and y == 0)
        tree:put(x, y, placeholder, isRoot)
    end)
    for _, c in ipairs(connections) do
        local u1 = tree:get(c.x1, c.y1)
        local u2 = tree:get(c.x2, c.y2)
        if u1 and u2 then tree:addConnection(u1, u2) end
    end
    tree:finalize()

    -- assign real upgrades based on tree distance
    local allPG = getProcGenUpgrades()
    local placedIds = {}
    local upgrades = tree:getUpgradesOnTree()
    table.sort(upgrades, function(a, b)
        return tree:distanceFromRoot(a) < tree:distanceFromRoot(b)
    end)

    for _, upg in ipairs(upgrades) do
        local d = tree:distanceFromRoot(upg)
        local eligible = {}
        for _, pg in ipairs(allPG) do
            if d >= pg.dist[1] and d <= pg.dist[2]
               and (not pg.needs or placedIds[pg.needs])
               and upgradeMatchesResources(pg.id, resourceSet) then
                local w = pg.weight
                if g.getUpgradeInfo(pg.id).kind == "TOKEN" and d <= 2 then w = w * 3 end
                eligible[#eligible+1] = {id=pg.id, weight=w, dist=pg.dist, needs=pg.needs, resource=pg.resource}
            end
        end
        local pick = #eligible > 0 and weightedPick(eligible) or allPG[1]
        upg.id = pick.id
        upg.basePrice = getPrice(upg, d, resources)
        upg.maxLevelOverride = love.math.random(2, 5)
        placedIds[pick.id] = true
    end

    tree:finalize()
    return tree
end


function procGen.generateTestTree()
    local grid, connections = procGen.generateTreeShape(110)
    return procGen.placeUpgrades(grid, connections)
end



return procGen

