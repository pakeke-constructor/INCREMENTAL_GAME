

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




local GRID_SIZE = 100
local OFFSET = 50 -- grid coords offset; world (0,0) = grid (50,50)

local DIRS = {
    {1,0}, {-1,0}, {0,1}, {0,-1},
    {1,1}, {1,-1}, {-1,1}, {-1,-1}
}

function procGen.generateTreeShape(numNodes)
    numNodes = numNodes or 80

    local grid = objects.Grid(GRID_SIZE, GRID_SIZE) -- true = node exists
    local connections = {} -- {x1=int,y1=int, x2=int,y2=int}[]
    local count = 0

    grid:set(OFFSET, OFFSET, true) -- root at origin
    count = count + 1

    -- Grow tree: random walk from random occupied cells
    while count < numNodes do
        local gx, gy = love.math.random(0, GRID_SIZE-1), love.math.random(0, GRID_SIZE-1)
        if grid:get(gx, gy) then
            local d = DIRS[love.math.random(#DIRS)]
            local nx, ny = gx + d[1], gy + d[2]
            if grid:contains(nx, ny) and not grid:get(nx, ny) then
                grid:set(nx, ny, true)
                count = count + 1
                if d[1] ~= 0 and d[2] ~= 0 then
                    table.insert(connections, {x1=gx-OFFSET, y1=gy-OFFSET, x2=nx-OFFSET, y2=ny-OFFSET})
                end
            end
        end
    end

    -- Sprinkle extra diagonal connections for reachability
    grid:foreach(function(val, gx, gy)
        if not val then return end
        for _, d in ipairs(DIRS) do
            if d[1] ~= 0 and d[2] ~= 0 then -- diagonal only
                local nx, ny = gx + d[1], gy + d[2]
                if grid:contains(nx, ny) and grid:get(nx, ny) and love.math.random() < 0.15 then
                    table.insert(connections, {x1=gx-OFFSET, y1=gy-OFFSET, x2=nx-OFFSET, y2=ny-OFFSET})
                end
            end
        end
    end)

    return grid, connections
end



function procGen.placeUpgrades()
end


function procGen.generateTestTree()
    local grid, connections = procGen.generateTreeShape()
    local tree = Tree()
    local uinfo = g.getUpgradeInfo("flat_2_more_damage")

    -- Place upgrades on every occupied cell
    grid:foreach(function(val, gx, gy)
        if not val then return end
        local x, y = gx - OFFSET, gy - OFFSET
        local isRoot = (x == 0 and y == 0)
        local upg = tree:put(x, y, uinfo, isRoot)
        upg.basePrice = {money = 10}
    end)

    -- Add connections
    for _, c in ipairs(connections) do
        local u1 = tree:get(c.x1, c.y1)
        local u2 = tree:get(c.x2, c.y2)
        if u1 and u2 then
            tree:addConnection(u1, u2)
        end
    end

    tree:finalize()
    return tree
end



return procGen

