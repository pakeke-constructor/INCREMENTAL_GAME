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
        description = "Increases "..resId.." {"..resId.."} limit!",
        descriptionContext = "As in, increasing the money cap, the amount of money that player can hold",
        kind = "MISC",
        image = resInfo.image,
        maxLevel = 5,
        getValues = function(_, level)
            return expIncrease ^ level
        end,
        getPriceOverride = function (uinfo, level)
            local limit = g.getResourceLimit(resId)
            return {
                [resId] = limit/2
            }
        end,
        valueFormatter = {g.formatNumber},
        [stat.multQuestion] = function(uinfo, level)
            return uinfo:getValues(level)
        end,
        procGen = {weight = 2, distance = {2, 8}, resource = resId},
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
    procGen = {
        weight = 10,
        distance = {3, 6}
    },
})





--------------------
-- Lightning upgrade
--------------------

g.defineUpgrade("lightning_upgrade", "Lightning Storm", {
    image = "lightning_icon",
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
            worldutil.spawnLightning(x, y)
        end
    end,
    procGen = {
        weight = 20,
        distance = {3, 6}
    },
})



----------------
-- Knife Thrower
----------------

g.defineUpgrade("knife_thrower", "Knife Thrower", {
    description = "Every 5 seconds, shoot out %{1} knives on mouse position.",
    kind = "MISC",
    image = "null_image",
    maxLevel = 6,

    getValues = helper.valueGetter(1, 5),

    perSecondUpdate = function (uinfo, level)
        local t = math.floor(g.getWorldTime())

        if t % 5 == 4 then
            local w = g.getMainWorld()
            local ww, wh = g.getWorldDimensions()
            local mx = w.mouseX or (ww / 2)
            local my = w.mouseY or (wh / 2)
            local count = uinfo:getValues(level)
            local roff = helper.lerp(0, 2 * math.pi, love.math.random())
            for i = 1, count do
                g.spawnEntity("knife", mx, my, i * 2 * math.pi / count + roff)
            end
        end
    end,

    drawUI = function(uinfo, level, x, y, w, h)
        local t = love.timer.getTime()/2
        local cx,cy = x+w/2, y+h/2

        for i = 1, 3 do
            local rot = math.pi / 4 + t + i / 3 * 2 * math.pi
            g.drawImageOffset("knife", cx, cy, rot, 1, 1, 0.2, 0.8)
        end
    end,

    procGen = {
        weight = 20,
        distance = {2, 6}
    },
})

--------------------
-- Scythe Thrower --
--------------------

g.defineUpgrade("scythe_thrower", "Scythe Thrower", {
    description = "Every 5 seconds, shoot out %{1} scythes on mouse position.",
    kind = "MISC",
    image = "null_image",
    maxLevel = 6,

    getValues = helper.valueGetter(1, 5),

    perSecondUpdate = function (uinfo, level)
        local t = math.floor(g.getWorldTime())

        if t % 5 == 4 then
            local w = g.getMainWorld()
            local ww, wh = g.getWorldDimensions()
            local mx = w.mouseX or (ww / 2)
            local my = w.mouseY or (wh / 2)
            local count = uinfo:getValues(level)
            local roff = helper.lerp(0, 2 * math.pi, love.math.random())
            for i = 1, count do
                g.spawnEntity("scythe_projectile", mx, my, i * 2 * math.pi / count + roff)
            end
        end
    end,

    drawUI = function(uinfo, level, x, y, w, h)
        local t = love.timer.getTime()/2
        local cx,cy = x+w/2, y+h/2

        for i = 1, 3 do
            local rot = math.pi / 4 + t + i / 3 * 2 * math.pi
            g.drawImageOffset("iron_scythe", cx, cy, rot, 1, 1, 0.5, 0.75)
        end
    end,

    procGen = {
        weight = 20,
        distance = {2, 6}
    },
})