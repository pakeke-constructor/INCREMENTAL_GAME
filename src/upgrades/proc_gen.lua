

local procGen = {}

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
You must also understand `g.UpgradeInfo._procGen` table, and how it relates to upgrade-definitions
Read src/modules/objects/Grid.lua

]]


---@class g.UpgradeDefinition._ProcGen
---@field weight number The rarity-weight of upgrade
---@field distance [integer,integer] [min,max] distance from root node when generating. A root node has level > 0. E.g. if distance = {1,3}, that means it MUST be between 1 and 3 jumps to a root node.
---@field needs string? a dependency to another upgrade. Eg: "better_slime" upgrade requires "slime" upgrade as a pre-requisite.
--- this class tells the system: "Hey, this upgrade will be procedurally generated!"
local g_UpgradeDefinition_ProcGen




function procGen.generateTreeShape()
    local g = objects.Grid(100,100)
    for x=-50, 50 do
        for y=-50, 50 do
            g:set(x,y, false)
        end
    end

    local connections = {} -- {x1=int,y1=int, x2=int,y2=int}

    return g, connections
end



function procGen.placeUpgrades()
end



return procGen

