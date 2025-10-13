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

    -- Update X position
    self.x = self.x + self.speed * self.dirX * dt
    if self.x < 0 then
        self.x = -self.x -- make it positive
        self.dirX = -self.dirX
    elseif self.x >= world.WIDTH then
        self.x = 2 * world.WIDTH - self.x
        self.dirX = -self.dirX
    end

    -- Update Y position
    self.y = self.y + self.speed * self.dirY * dt
    if self.y < 0 then
        self.y = -self.y -- make it positive
        self.dirY = -self.dirY
    elseif self.y >= world.HEIGHT then
        self.y = 2 * world.HEIGHT - self.y
        self.dirY = -self.dirY
    end

    -- Try harvest
    world.tokenPartition:query(self.x,self.y, function (tok)
        if math.distance(self.x-tok.x, self.y-tok.y) <= (self.radius + consts.HARVEST_AREA_LEEWAY) then
            g.tryHitToken(tok)
        end
    end, self.radius)
end


local HARVEST_CIRCLE_INSIDE = {0.2,0.2,0.2,0.09}
local HARVEST_CIRCLE_BORDER = {.9,.9,.9,0.8}

function FarmerCatEntity:drawBelow()
    local rad = self.radius
    love.graphics.setColor(HARVEST_CIRCLE_INSIDE)
    love.graphics.circle("fill", self.x, self.y, rad)

    local lw = love.graphics.getLineWidth()
    love.graphics.setLineWidth(math.floor(rad / 15))
    love.graphics.setColor(HARVEST_CIRCLE_BORDER)
    love.graphics.circle("line", self.x, self.y, rad)
    love.graphics.setLineWidth(lw)
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
