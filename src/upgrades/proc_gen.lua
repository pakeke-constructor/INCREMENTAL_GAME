

local procGen = {}


local Tree = require("src.upgrades.Tree")


---@param upgradePaths objects.Set<string>
---@param distanceToRoot integer
local function getUpgradeCandidates(upgradePaths, distanceToRoot)
    -- 
end


---@async
---@param seedlo integer
---@param seedhi integer?
local function newRandomTree(seedlo, seedhi)
    local rng = love.math.newRandomGenerator(seedlo, seedhi or 0)
    local tree = Tree()
    coroutine.yield(tree)

    local bfs = {
        {x = 0, y = 0, distance = 0}
    }

    while #bfs > 0 do
        local node = table.remove(bfs, 1)
        coroutine.yield(false)
    end

    return true
end


---You need to call the returned function repeatedly every frame until it returns `true`
---@param seedlo integer
---@param seedhi integer?
---@return g.Tree,(fun():boolean)
local function procgenTree(seedlo, seedhi)
    local f =  coroutine.wrap(newRandomTree)
    local tree = f(seedlo, seedhi) --[[@as g.Tree]]
    return tree, f
end




local tree, nextFunc = procgenTree(seedlo, seedhi)

-- Fro debugging in separate scenes
local hasDone = false
function draw()
    if not hasDone then
        hasDone = nextFunc()
    end

    -- Draw tree
end

-- Or when generating in ahrvest scene:
function generatePrestige()
    local tree, nextFunc = procgenTree(seedlo, seedhi)
    local t = love.timer.getTime()
    while (love.timer.getTime() - t) <= timeBudget do
        if nextFunc() then
            return true, tree
        end
    end
    return false, tree, nextFunc
end



return procGen

