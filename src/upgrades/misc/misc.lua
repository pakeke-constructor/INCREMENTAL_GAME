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




---------------------
-- Capitalist upgrade
---------------------
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




---------------------
-- Farmer Cat upgrade
---------------------

---@class FarmerCatEntity: g.Entity
---@field public dirX -1|1
---@field public dirY -1|1
---@field public speed number
local FarmerCatEntity = {
    image = "happy_cat",
    radius = 20,
    speed = 50
}

function FarmerCatEntity:update(dt)
    local world = g.getMainWorld()

    -- Update positions
    worldutil.updateLikeDVD(world, self, dt)

    -- Try harvest
    g.iterateTokensInArea(self.x, self.y, self.radius + consts.HARVEST_AREA_LEEWAY, g.tryHitToken)
end


local HARVEST_CIRCLE_INSIDE = {0.2,0.2,0.2,0.09}
local HARVEST_CIRCLE_BORDER = {.9,.9,.9,0.8}

function FarmerCatEntity:drawBelow()
    return worldutil.drawHarvestCircle(self.x, self.y, self.radius, HARVEST_CIRCLE_INSIDE, HARVEST_CIRCLE_BORDER)
end

g.defineEntity("farmer_cat", FarmerCatEntity)

-- TODO: Balancing
g.defineUpgrade("farmer_cat", "Farmer Cat", {
    kind = "MISC",
    description = "Spawn %{1} Farmer Cat to farm for you.",
    image = "happy_cat",
    price = {money = 1000},
    maxLevel = 10,
    getEntityCount = function(uinfo, level)
        return level
    end,
    getValues = function(uinfo, level)
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
