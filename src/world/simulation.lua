local simulation = {}

local table_new = require("table.new")

-- Target upgrade ID to be used as baseline
-- If this is nil, simulation is not used.
---@type string|nil
simulation.targetUpgrade = nil
simulation.duration = 0

function simulation.getBestMousePositionInWorld()
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

        local ranking = (1 - (avgHealth / #toks)) * #toks
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


---Buy all affordable upgrade using current currency as the threshold.
---@param excludeuid objects.Set<string>
function simulation.buyAffordableUpgrades(excludeuid)
    local session = g.getSn()

    repeat
        local noneBought = true

        for _, uid in ipairs(g.UPGRADE_LIST) do
            if not excludeuid:has(uid) then
                local uinfo = g.getUpgradeInfo(uid)

                if not g.isUpgradeHidden(uinfo) then
                    local nextlevel = (session.upgradeLevels[uid] or 0) + 1
                    local price = g.getUpgradePrice(uinfo, nextlevel)

                    -- Increase price by 1 to simulate larger than
                    for k, v in pairs(price) do
                        if v > 0 then
                            price[k] = v + 1
                        end
                    end

                    if g.canAfford(price) then
                        print("Bought upgrade:", uid, nextlevel)
                        session.upgradeLevels[uid] = nextlevel
                        noneBought = false
                    end
                end
            end
        end
    until noneBought
end

---@param targetUpgrade string
---@param duration number
function simulation.setup(targetUpgrade, duration)
    local session = g.getSn()
    local uinfo = g.getUpgradeInfo(targetUpgrade)
    simulation.targetUpgrade = targetUpgrade

    -- Set player currency and set max limit
    for _, resId in ipairs(g.RESOURCE_LIST) do
        local resInfo = g.getResourceInfo(resId)
        session.resources[resId] = uinfo.price[resId] or 0
        g.stats[resInfo.limitStat] = 1e9
    end

    simulation.buyAffordableUpgrades(objects.Set({targetUpgrade}))

    -- Set user currency to zero
    for _, resId in ipairs(g.RESOURCE_LIST) do
        session.resources[resId] = 0
    end

    -- Set duration
    simulation.duration = duration
end

return simulation
