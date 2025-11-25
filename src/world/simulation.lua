local simulation = {}


simulation.isOn = false

simulation.duration = 0

simulation.lastMouseHitTime = 0
simulation.mouseX = 0
simulation.mouseY = 0


function simulation.isSimulating()
    return simulation.isOn
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



---Buys all upgrades BELOW the target upgrade.
--- Emulates how the players will typically play 
---@param upgId string
---@param prestige integer
local function buyAffordableUpgrades(upgId, prestige)
    local session = g.getSn()

    error("TODO: fix all this shiiet.")
    local tree = g.getUpgTree()

    local targLevel = 1
    local targPrice = tree:getUpgradePrice(upgId, targLevel)

    -- we use a while-loop because there are some upgrades 
    -- that reduce the price of other upgrades.
    local hasPurchase = true
    while hasPurchase do
        hasPurchase = false

        for _, upg in ipairs(tree:getUpgrades()) do
            local id=upg.id
            if upgId ~= id then
                local level = tree:setUpgradeLevel(upg, upg.level + 1)
                local price = tree:getUpgradePrice(upg)

                -- if price <= targPrice:
                if g.canAfford(price, targPrice) then
                    hasPurchase = true
                    session.upgradeLevels[id] = level
                end
            end
        end
    end
end



---@param upgId string
---@param duration number
function simulation.setup(tree)
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
