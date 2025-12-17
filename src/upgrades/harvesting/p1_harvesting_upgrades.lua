




---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "HARVESTING"
    g.defineUpgrade(id,name,tabl)
end


---@class _.upgrades
local upgrades = {
    {
        id = "more_damage",
        title = "More Damage",
        desc = "%{1} scythe damage",
        stat = "HitDamage",
        increase = 0.5
    },
    {
        id = "more_speed",
        title = "More Speed",
        desc = "%{1} scythe speed",
        stat = "HitSpeed",
        increase = 1
    },
    {
        id = "more_area",
        title = "More Area",
        desc = "%{1} area",
        stat = "HarvestArea",
        increase = 2
    }
}

for _, u in ipairs(upgrades) do
    defUpgrade("percentage_"..u.id, u.title, {
        image = u.id,

        getValues = function(self, level)
            return level
        end,
        valueFormatter = {"+%d%%"},
        description = u.desc,

        ["get" .. u.stat .. "Multiplier"] = function(self, level)
            local a = self:getValues(level)
            return 1 + (a / 100)
        end
    })

    defUpgrade("flat_"..u.id, u.title, {
        image = u.id,

        getValues = function(self, level)
            return level*u.increase
        end,

        valueFormatter = {"+%.1f"},
        description = u.desc,

        ["get" .. u.stat .. "Modifier"] = function(self, level)
            return self:getValues(level)
        end
    })
end





defUpgrade("critical_damage", "Critical Damage", {
    --[[
    TODO!!
    We should have more upgrades related to critical-strikes.
    ]]
    description = "%{1} chance of hitting token with 10x more damage.",
    getValues = function(uinfo, level)
        return 1 + (level - 1) / 2
    end,
    valueFormatter = {"%.14g%%"},

    getTokenHitMultiplier = function(uinfo, level)
        local val = uinfo:getValues(level) / 100
        return love.math.random() <= val and 10 or 1
    end
})






defUpgrade("lucky_hit", "Lucky Hit", {
    getValues = function(self,level)
        return level*3
    end,
    description = "When a crop is hit, +%{1}% chance to hit another crop",

    tokenHit = function(self,level)
        local r = love.math.random()
        local a=self:getValues(level)
        local chance = (a/100)
        if r < chance then
            local tok = g.getRandomToken(function (tok)
                return not g.isBeingHit(tok)
            end)
            if tok then
                g.tryHitToken(tok)
            end
        end
    end
})




defUpgrade("more_loot", "More Loot", {
    image = "money", -- TODO: change
    description = "All crops have %{1} more health, and earn %{2} more resources.",

    getValues = function(uinfo, level)
        ---@diagnostic disable-next-line: redundant-return-value
        return 6 + level * 4, 10 * level
    end,
    valueFormatter = {"%d%%", "%d%%"},

    getTokenMaxHealthMultiplier = function(uinfo, level)
        local healthMult = uinfo:getValues(level) / 100
        return 1 + healthMult
    end,
    getTokenResourceMultiplier = function(uinfo, level)
        local resMult = select(2, uinfo:getValues(level)) / 100
        return 1 + resMult
    end
})





defUpgrade("spinning_axes_upgrade", "Spinning Axes", {
    maxLevel = 3,

    getValues = function(self,level)
        return level*10
    end,
    description = "Every second, +%{1}% chance to spawn a spinning axe",

    perSecondUpdate = function(self,level)
        local r = love.math.random()
        local a=self:getValues(level)
        local chance = (a/100)
        if r < chance then
            local x,y = g.getRandomPositionForToken()
            if x and y then
                g.spawnEntity("spinning_axe", x,y)
            end
        end
    end
})


defUpgrade("bomb_rain", "Bomb Rain", {
    description = "Every second, %{1} chance of spawning a Bomb!",
    getValues = function(uinfo, level)
        return level
    end,
    valueFormatter = {"%d%%"},

    perSecondUpdate = function(uinfo, level)
        local world = g.getMainWorld()
        local bombs = world.tokenCounts.bomb or 0
        if bombs < 10 then
            local chance = uinfo:getValues(level) / 100
            if love.math.random() <= chance then
                local x, y = g.getRandomPositionForToken(true)
                g.spawnToken("bomb", x, y)
            end
        end
    end
})





defUpgrade("thorns", "Thorns", {
    description = "When a crop is harvested, %{1} chance for it to shoot out a knife projectile!",

    getValues = function(uinfo, level)
        return level * 2
    end,
    valueFormatter = {"%d%%"},
    tokenDestroyed = function(uinfo, level, tok)
        local chance = uinfo:getValues(level) / 100
        if love.math.random() <= chance then
            -- Spawn knife
            g.spawnEntity("knife", tok.x, tok.y)
        end
    end
})
