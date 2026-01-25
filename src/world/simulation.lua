local rewards = require("src.rewards.rewards")

---@class _Simulation
local simulation = {}

local SIMULATION_FPS = 60
local SIMULATION_TIME_BUDGET = 0.01 -- 10ms time budget.
-- Frequency each second the simulation tree is serialized
local SIMULATION_TREE_FREQUENCY = 5
-- Frequency each second the simulation data graph is captured
local SIMULATION_GRAPH_FREQUENCY = 1

---@alias _Simulation.Graph<T> {x:number,y:T}

---@class _Simulation.GraphResult
---@field public purchasedUpgradesGraph _Simulation.Graph<integer>[]
---@field public resourceGraph {money:_Simulation.Graph<number>[]}
---@field public rpsGraph {money:_Simulation.Graph<number>[]}
---@field public newPurchasedUpgradesGraph _Simulation.Graph<integer>[]

---@class _Simulation.State: _Simulation.GraphResult
---@field public duration number
---@field public time number
---@field public buyStrategy "cheapest"|"random"
---@field public lastMouseHitTime number
---@field public mouse [number, number]
---@field public startResource g.Resources
---@field public xp number
---@field public lastExp number
---@field public treeSnapshots _Simulation.Graph<table>[]
---@field public treeSnapshotTime number
---@field public graphCaptureTime number

---@private
---@type _Simulation.State|nil
simulation.state = nil

---@class _Simulation.BasicResultInfo
---@field public resource g.Resources Resource earned
---@field public rps g.Resources Average RPS across whole duration
---@field public duration number Simulation duration
---@field public xp number XP earned
---@field public xpps number Average XP earned across whole duration

---@class _Simulation.Result
---@field public save table
---@field public finalData _Simulation.BasicResultInfo
---@field public treeSnapshots _Simulation.Graph<table>[]
---@field public graphs _Simulation.GraphResult

---@private
---@type _Simulation.Result|nil
simulation.result = nil


function simulation.isSimulating()
    return not not simulation.state
end



local function getBestMousePositionInWorld()
    local worldW, worldH = g.getWorldDimensions()

    local RESOLUTION_X = 30
    local RESOLUTION_Y = 20

    local bestX, bestY = 0,0
    local bestRank = 0

    for x=0, worldW, (worldW/RESOLUTION_X) do
        for y=0, worldH, (worldH/RESOLUTION_Y) do
            local rank = 0
            g.iterateTokensInArea(x,y, g.stats.HarvestArea, function (tok)
                local hp = (tok.health / tok.maxHealth)
                rank = rank + (1.5 - hp)
            end)

            love.graphics.setColor(1,0,0)
            love.graphics.circle("line", x,y,g.stats.HarvestArea)

            if rank > bestRank then
                bestX, bestY, bestRank = x,y,rank
            end
        end
    end

    return bestX, bestY
end

---@param tree g.Tree
---@param strategy "cheapest"|"random"
local function tryBuyUpgrade(tree, strategy)
    ---@type g.Tree.Upgrade[]
    local affordableUpgrades = {}

    for _, upg in ipairs(tree:getUpgradesOnTree()) do
        local maxLv = tree:getUpgradeMaxLevel(upg)
        if (not tree:isUpgradeHidden(upg)) and tree:canAffordUpgrade(upg) and (upg.level < maxLv) then
            affordableUpgrades[#affordableUpgrades+1] = upg
        end
    end

    if #affordableUpgrades > 0 then
        if strategy == "cheapest" then
            table.sort(affordableUpgrades, function(a, b)
                -- If we need to sort by multiple currencies, modify this
                return tree:getUpgradePrice(a).money < tree:getUpgradePrice(b).money
            end)
            return tree:tryBuyUpgrade(affordableUpgrades[1])
        elseif strategy == "random" then
            return tree:tryBuyUpgrade(helper.randomChoice(affordableUpgrades))
        end
    end

    return false
end


---@class _Simulation.Options
---@field public duration number
---@field public buyStrategy "cheapest"|"random"

---@param opts _Simulation.Options
function simulation.start(opts)
    assert(not simulation.state, "simulation is in progress")
    assert(opts.buyStrategy == "cheapest" or opts.buyStrategy == "random", "invalid buy strategy")

    local res = g.getResources()
    simulation.state = {
        duration = opts.duration,
        time = 0,
        buyStrategy = opts.buyStrategy,
        lastMouseHitTime = 0,
        mouse = {0, 0},
        startResource = {
            -- Need to copy because `g.getResources()` doesn't return a copy
            money = res.money,
            fabric = res.fabric,
            juice = res.juice,
            bread = res.bread,
            fish = res.fish
        },
        xp = 0,
        lastExp = g.getSn().xp,
        treeSnapshots = {},
        purchasedUpgradesGraph = {},
        resourceGraph = {money = {}},
        rpsGraph = {money = {}},
        newPurchasedUpgradesGraph = {},
        treeSnapshotTime = 0,
        graphCaptureTime = 0
    }
end



---@return boolean @Is simulation completed?
function simulation.update()
    if not simulation.state then
        return true
    end

    local st = assert(simulation.state)
    local world = g.getMainWorld()
    local startTime = love.timer.getTime()
    local dt = 1/SIMULATION_FPS

    while true do
        local sn = g.getSn()
        -- Updat session
        sn:_update(dt)

        -- Pop stacking token
        local stkTok,onSpawn = g.peekStackedToken()
        if stkTok then
            -- Just spawn token immediately. It's _accurate_ enough.
            assert(g.popStackedToken() == stkTok)
            local ww, wh = g.getWorldDimensions()
            local x = helper.lerp(8, ww - 8, love.math.random())
            local y = helper.lerp(8, wh - 8, love.math.random())
            local tok = g.spawnToken(stkTok, x, y)
            if onSpawn then onSpawn(tok) end
        end

        -- Harvest area may reset the XP on level up, so have this to reduce
        -- the inaccuracies of the result
        local dxp = sn.xp < st.lastExp and sn.xp or (sn.xp - st.lastExp)
        st.xp = st.xp + dxp
        st.lastExp = sn.xp
        st.time = st.time + dt
        st.treeSnapshotTime = st.treeSnapshotTime + dt
        st.graphCaptureTime = st.graphCaptureTime + dt

        if sn.xp >= sn.xpRequirement then
            -- Pick reward:
            local r = rewards.generateRandomRewards()
            for i,rew in ipairs(r) do
                if rew.type == "permanent" then
                    -- always choose perm rewards.
                    rewards.selectReward(rew)
                    break
                elseif i == #r then
                    -- final reward; pick it
                    rewards.selectReward(rew)
                    break
                end
            end
            -- Pick upgrade based on strategy
            tryBuyUpgrade(sn.tree, st.buyStrategy)
            sn:levelUp()
        end

        -- Also buy upgrades if any resource is full.
        local anyResourceFull = nil
        for _,resId in ipairs(g.RESOURCE_LIST) do
            local res = g.getResource(resId)
            local reslim = g.getResourceLimit(resId)
            if res >= reslim then
                anyResourceFull = true
                break
            end
        end
        if anyResourceFull then
            tryBuyUpgrade(sn.tree, st.buyStrategy)
        end

        if st.treeSnapshotTime >= SIMULATION_TREE_FREQUENCY then
            st.treeSnapshotTime = st.treeSnapshotTime - SIMULATION_TREE_FREQUENCY
            st.treeSnapshots[#st.treeSnapshots+1] = {x = sn.worldTime, y = sn.tree:serialize()}
        end

        if st.graphCaptureTime >= SIMULATION_GRAPH_FREQUENCY then
            st.graphCaptureTime = st.graphCaptureTime - SIMULATION_GRAPH_FREQUENCY
            local upgrades = 0
            local newUpgrades = 0

            for _, upg in ipairs(sn.tree:getAllUpgrades()) do
                upgrades = upgrades + upg.level
                newUpgrades = newUpgrades + math.min(upg.level, 1)
            end

            st.purchasedUpgradesGraph[#st.purchasedUpgradesGraph+1] = {x = sn.worldTime, y = upgrades}
            st.newPurchasedUpgradesGraph[#st.newPurchasedUpgradesGraph+1] = {x = sn.worldTime, y = newUpgrades}
            table.insert(st.resourceGraph.money, {x = sn.worldTime, y = sn.resources.money})
            table.insert(st.rpsGraph.money, {x = sn.worldTime, y = sn.mainWorld.resourcesPerSecond.money or 0})
        end

        if st.time >= st.duration then
            local currentResource = g.getResources()
            local earnedResource = {
                money = currentResource.money - st.startResource.money,
                fabric = currentResource.fabric - st.startResource.fabric,
                bread = currentResource.bread - st.startResource.bread,
                juice = currentResource.juice - st.startResource.juice,
                fish = currentResource.fish - st.startResource.fish,
            }

            -- Done
            simulation.result = {
                save = sn:serialize(),
                finalData = {
                    resource = earnedResource,
                    rps = {
                        money = earnedResource.money / st.time,
                        fabric = earnedResource.fabric / st.time,
                        bread = earnedResource.bread / st.time,
                        juice = earnedResource.juice / st.time,
                        fish = earnedResource.fish / st.time,
                    },
                    duration = st.time,
                    xp = st.xp,
                    xpps = st.xp / st.time
                },
                treeSnapshots = st.treeSnapshots,
                graphs = {
                    purchasedUpgradesGraph = st.purchasedUpgradesGraph,
                    resourceGraph = st.resourceGraph,
                    rpsGraph = st.rpsGraph,
                    newPurchasedUpgradesGraph = st.newPurchasedUpgradesGraph,
                }
            }
            simulation.state = nil
            return true
        end

        if st.time - st.lastMouseHitTime > 0.3 then
            st.lastMouseHitTime = st.time
            st.mouse[1], st.mouse[2] = getBestMousePositionInWorld()
        end

        world:_enableMouseHarvester(st.mouse[1], st.mouse[2])

        if (love.timer.getTime() - startTime) >= SIMULATION_TIME_BUDGET then
            -- Simulation incomplete
            return false
        end
    end
end



---@return _Simulation.Result
function simulation.getResult()
    assert(simulation.result, "simulation is in progress or not run yet")
    return simulation.result
end


function simulation.getProgress()
    if not simulation.state then
        return 1
    end
    return simulation.state.time / simulation.state.duration
end



return simulation
