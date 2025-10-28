local simulation = {}

local table_new = require("table.new")

-- Target upgrade ID to be used as baseline
-- If this is nil, simulation is not used.
---@type string|nil
simulation.targetUpgrade = nil
simulation.duration = 0

simulation.lastMouseHitTime = 0
simulation.mouseX = 0
simulation.mouseY = 0


function simulation.isSimulating()
    return not not simulation.targetUpgrade
end



local function getBestMousePositionInWorld()
    local world = g.getMainWorld()

    local RESOLUTION_X = 30
    local RESOLUTION_Y = 20

    local bestX, bestY = 0,0
    local bestRank = 0

    for x=0, world.WIDTH, (world.WIDTH/RESOLUTION_X) do
        for y=0, world.HEIGHT, (world.HEIGHT/RESOLUTION_Y) do
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

    -- for i, toks in ipairs(grid) do
    --     local hp = 0

    --     for _, tok in ipairs(toks) do
    --         hp = hp + tok.health / tok.maxHealth
    --     end

    --     local avgHealth = 0
    --     if #toks > 0 then
    --         avgHealth = hp / #toks
    --     end

    --     local ranking = (2 - (avgHealth / #toks)) * #toks
    --     if ranking > best then
    --         best = ranking
    --         targetGI = i
    --     end
    -- end

    -- if targetGI == 0 then
    --     return 0, 0
    -- end
end


---Buys all upgrades BELOW the target upgrade.
--- Emulates how the players will typically play 
---@param upgId string
---@param prestige integer
local function buyAffordableUpgrades(upgId, prestige)
    local session = g.getSn()

    local targLevel = 1
    local targPrice = g.getUpgradePrice(g.getUpgradeInfo(upgId), targLevel)

    -- we use a while-loop because there are some upgrades 
    -- that reduce the price of other upgrades.
    local hasPurchase = true
    while hasPurchase do
        hasPurchase = false

        for _, uid in g.iterateUpgradeTree(prestige) do
            local uinfo = g.getUpgradeInfo(uid)
            if upgId ~= uid then
                local level = g.getUpgradeLevel(uinfo) + 1
                local price = g.getUpgradePrice(uinfo, level)

                -- if price <= targPrice:
                if g.canAfford(price, targPrice) then
                    hasPurchase = true
                    print("BUY: ", uid, level)
                    session.upgradeLevels[uid] = level
                end
            end
        end
    end
end



---@param upgId string
---@param duration number
function simulation.setup(upgId, duration)
    local session = g.getSn()
    local uinfo = g.getUpgradeInfo(upgId)
    simulation.targetUpgrade = upgId

    -- Set player currency and set max limit
    for _, resId in ipairs(g.RESOURCE_LIST) do
        local resInfo = g.getResourceInfo(resId)
        session.resources[resId] = uinfo.price[resId] or 0
        g.stats[resInfo.limitStat] = 1e9
    end

    buyAffordableUpgrades(upgId, 0)

    -- Set user currency to zero
    for _, resId in ipairs(g.RESOURCE_LIST) do
        session.resources[resId] = 0
    end

    -- Set duration
    simulation.duration = duration
end



function simulation.update(dt)
    local world = g.getMainWorld()
    simulation.duration = simulation.duration - dt

    if simulation.duration <= 0 then
        local rps = world:_getResourcesPerSecond()
        print("Request per seconds over last 60 seconds")
        for k, v in pairs(rps) do
            print(v.." "..k.."/s")
        end
        love.event.quit()
    end

    local time = love.timer.getTime()
    if time-simulation.lastMouseHitTime > 0.3 then
        simulation.lastMouseHitTime = time
        simulation.mouseX, simulation.mouseY = getBestMousePositionInWorld()
    end

    world:_enableMouseHarvester(simulation.mouseX, simulation.mouseY)
end



return simulation
