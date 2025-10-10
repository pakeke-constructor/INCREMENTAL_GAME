---@param id string
---@param name string
---@param resId g.ResourceType
---@param price g.Bundle
---@param expIncrease number
local function defineResLimitUpgrade(id, name, resId, price, expIncrease)
    local resInfo = g.getResourceInfo(resId)
    local stat = g.VALID_STATS[resInfo.limitStat]
    return g.defineUpgrade(id, name, {
        description = loc("Increase "..resId.." limit by additional %{1}."),
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




g.defineUpgrade("capitalist", "Capitalist", {
    kind = "MISC",
    image = "money_particle_4",
    description = loc("All upgrades become %{1} cheaper."),
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
