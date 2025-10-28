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
    -- HarvestArea is circular, divide by sqrt(2) so it covers rectangle diagonals.
    local cellSize = math.floor(2 * g.stats.HarvestArea / math.sqrt(2))
    local gridW = math.ceil(world.WIDTH / cellSize)
    local gridH = math.ceil(world.HEIGHT / cellSize)
    -- These are used to make sure the grid is on the center.
    local offX = (gridW * cellSize - world.WIDTH) / 2
    local offY = (gridH * cellSize - world.HEIGHT) / 2
    ---@type g.Token[][]
    local grid = table_new(gridW * gridH, 0)
    for _ = 1, gridW * gridH do
        grid[#grid+1] = {}
    end

    -- Iterate tokens
    -- We don't use g.iterateTokensInArea because we just want to iterate everything
    for _, tok in ipairs(world.tokens) do
        ---@cast tok g.Token
        local gx = math.floor((tok.x + offX) / cellSize)
        local gy = math.floor((tok.y + offY) / cellSize)
        local i = gy * gridW + gx + 1
        table.insert(grid[i], tok)
    end

    -- Get best grid position
    local targetGI = 0
    local best = 0
    for i, toks in ipairs(grid) do
        local hp = 0

        for _, tok in ipairs(toks) do
            hp = hp + tok.health / tok.maxHealth
        end

        local avgHealth = 0
        if #toks > 0 then
            avgHealth = hp / #toks
        end

        local ranking = (2 - (avgHealth / #toks)) * #toks
        if ranking > best then
            best = ranking
            targetGI = i
        end
    end

    if targetGI == 0 then
        return 0, 0
    end

    -- Calculate best mouse pos in world
    local targetGX = (targetGI - 1) % gridW
    local targetGY = math.floor((targetGI - 1) / gridW)
    return (targetGX + 0.5) * cellSize - offX, (targetGY + 0.5) * cellSize - offY
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
