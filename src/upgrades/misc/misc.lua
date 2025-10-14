-------------------------
-- Resource limit upgrade
-------------------------

---@param id string
---@param name string
---@param resId g.ResourceType
---@param price g.Bundle
---@param expIncrease number
local function defineResLimitUpgrade(id, name, resId, price, expIncrease)
    local resInfo = g.getResourceInfo(resId)
    local stat = g.VALID_STATS[resInfo.limitStat]
    return g.defineUpgrade(id, name, {
        description = ("Increase "..resId.." limit by additional %{1}."),
        kind = "MISC",
        price = price,
        image = resInfo.image,
        maxLevel = 10,
        getValues = function(_, level)
            return expIncrease ^ level
        end,
        valueFormatter = {g.formatNumber},
        [stat.addQuestion] = function(uinfo, level)
            return uinfo:getValues(level)
        end,
    })
end

-- TODO: Balancing
defineResLimitUpgrade("money_limit", "Money Limit", "money", {money = 100}, 10)
defineResLimitUpgrade("logs_limit", "Logs Limit", "logs", {logs = 10}, 5)
defineResLimitUpgrade("rocks_limit", "Rocks Limit", "rocks", {rocks = 10}, 5)
defineResLimitUpgrade("bones_limit", "Bones Limit", "bones", {bones = 10}, 5)




---------------------
-- Capitalist upgrade
---------------------
g.defineUpgrade("capitalist", "Capitalist", {
    kind = "MISC",
    image = "money_icon",
    description = ("All upgrades become %{1} cheaper."),
    getValues = function(uinfo, level)
        return 5 * level
    end,
    valueFormatter = {"%d%%"},
    getUpgradePriceMultiplier = function(uinfo, level)
        local reduction = uinfo:getValues(level) / 100
        return math.max(1 - reduction, 0)
    end,
    maxLevel = 4,
    price = {money = 500}
})




---------------------
-- Farmer Cat upgrade
---------------------

-- TODO: Balancing
g.defineUpgrade("farmer_cat", "Farmer Cat", {
    kind = "MISC",
    description = "Farmer-Cats farm automatically!",
    image = "happy_cat",
    price = {money = 1000},
    maxLevel = 10,
    getEntityCount = function(uinfo, level)
        return level
    end,
    spawnEntity = function()
        local world = g.getMainWorld()
        local x = love.math.random(0, world.WIDTH - 1)
        local y = love.math.random(0, world.HEIGHT - 1)
        local e = g.spawnEntity("farmer_cat", x, y)
        ---@cast e FarmerCatEntity
        e.dirX = love.math.random(0, 1) * 2 - 1
        e.dirY = love.math.random(0, 1) * 2 - 1
        return e
    end
})



--------------------
-- Lightning upgrade
--------------------

g.defineUpgrade("lightning_upgrade", "Lightning Bolt", {
    image = "stick",
    description = "Every second, %{1} chance for Lightning to spawn!",
    kind = "MISC",
    price = {money = 1000},

    getValues = function(uinfo, level)
        return 4 + level
    end,
    valueFormatter = {"%d%%"},
    maxLevel = 20,

    perSecondUpdate = function(uinfo, level)
        local chance = uinfo:getValues(level) / 100
        if love.math.random() < chance then
            -- Damage token around
            local world = g.getMainWorld()
            local x = love.math.random(world.WIDTH) - 1
            local y = love.math.random(world.HEIGHT) - 1
            worldutil.spawnLightning(x, y, 50)
        end
    end
})
