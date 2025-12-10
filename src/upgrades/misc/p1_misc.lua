-------------------------
-- Resource limit upgrade
-------------------------

---@param id string
---@param name string
---@param resId g.ResourceType
---@param expIncrease number
local function defineResLimitUpgrade(id, name, resId, expIncrease)
    local resInfo = g.getResourceInfo(resId)
    local stat = g.VALID_STATS[resInfo.limitStat]
    return g.defineUpgrade(id, name, {
        description = ("Increase "..resId.." limit by additional %{1}."),
        kind = "MISC",
        image = resInfo.image,
        maxLevel = 10,
        getValues = function(_, level)
            return expIncrease ^ level
        end,
        getPriceOverride = function (uinfo, level)
            local limit = g.getResourceLimit(resId)
            return {
                [resId] = limit
            }
        end,
        valueFormatter = {g.formatNumber},
        [stat.addQuestion] = function(uinfo, level)
            return uinfo:getValues(level)
        end,
    })
end

-- TODO: Balancing
defineResLimitUpgrade("money_limit", "Money Limit", "money", 10)
defineResLimitUpgrade("fabric_limit", "Fabric Limit", "fabric", 5)
defineResLimitUpgrade("bread_limit", "Bread Limit", "bread", 5)
defineResLimitUpgrade("juice_limit", "Juice Limit", "juice", 5)
defineResLimitUpgrade("fish_limit", "Fish Limit", "fish", 5)










---------------------
-- Capitalist upgrade
---------------------
g.defineUpgrade("capitalist", "Capitalist", {
    kind = "MISC",
    image = "money",
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
})





--------------------
-- Lightning upgrade
--------------------

g.defineUpgrade("lightning_upgrade", "Lightning Bolt", {
    image = "happy_cat",
    description = "Every second, %{1} chance for Lightning to spawn!",
    kind = "MISC",

    getValues = function(uinfo, level)
        return 4 + level
    end,
    valueFormatter = {"%d%%"},
    maxLevel = 20,

    perSecondUpdate = function(uinfo, level)
        local chance = uinfo:getValues(level) / 100
        if love.math.random() < chance then
            -- Damage token around
            local worldW, worldH = g.getWorldDimensions()
            local x = love.math.random(worldW) - 1
            local y = love.math.random(worldH) - 1
            worldutil.spawnLightning(x, y, 2)
        end
    end
})
