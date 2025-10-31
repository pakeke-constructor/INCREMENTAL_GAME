




---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "HARVESTING"
    g.defineUpgrade(id,name,tabl)
end




defUpgrade("more_damage", "More Damage", {
    startingUpgrade=true,

    price = {money=10},

    getValues = function(self,level)
        return level*10
    end,
    description = "Deal +%{1}% extra damage to ALL tokens",

    getTokenHitMultiplier = function(self,level)
        local a=self:getValues(level)
        return 1+(a/100)
    end
})



defUpgrade("hit_speed", "Hit Speed", {
    price = {money=10},

    getValues = function(self,level)
        return level*10
    end,
    description = "+%{1}% hit speed",

    getHitDurationMultiplier = function(self,level)
        local a=self:getValues(level)
        return 1/(1+(a/100))
    end
})



defUpgrade("more_area", "More Area", {
    price = {money=10},

    getValues = function(self,level)
        return level*4
    end,
    description = "+%{1}% hit area",

    getHarvestAreaMultiplier = function(self,level)
        local a=self:getValues(level)
        return 1+(a/100)
    end
})




defUpgrade("lucky_hit", "Lucky Hit", {
    price = {money=10},

    getValues = function(self,level)
        return level*3
    end,
    description = "When a token is hit, +%{1}% chance to hit another token",

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





defUpgrade("spinning_axes_upgrade", "Spinning Axes", {
    price = {money=800},

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



defUpgrade("more_loot", "More Loot", {
    image = "money_icon", -- TODO: change
    price = {money = 100},
    description = "All tokens have %{1} more health, and earn %{2} more resources.",

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




defUpgrade("critical_damage", "Critical Damage", {
    price = {money = 100},
    description = "%{1} chance of hitting token with 100x more damage.",
    getValues = function(uinfo, level)
        return 1 + (level - 1) / 2
    end,
    valueFormatter = {"%.14g%%"},

    getTokenHitMultiplier = function(uinfo, level)
        local val = uinfo:getValues(level) / 100
        return love.math.random() <= val and 100 or 1
    end
})



defUpgrade("bomb", "Bomb", {
    description = "Every second, there's %{1} chance of spawning Bomb token.",
    getValues = function(uinfo, level)
        return 5 + level * 5
    end,
    valueFormatter = {"%d%%"},
    price = {money = 100},

    perSecondUpdate = function(uinfo, level)
        local world = g.getMainWorld()
        local bombs = world.tokenCounts.bomb or 0
        if bombs < 10 then
            local chance = uinfo:getValues(level) / 100
            if love.math.random() <= chance then
                local x = helper.lerp(8, world.WIDTH - 8, love.math.random())
                local y = helper.lerp(8, world.HEIGHT - 8, love.math.random())
                g.spawnToken("bomb", x, y)
            end
        end
    end
})
