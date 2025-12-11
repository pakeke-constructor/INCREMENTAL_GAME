




---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "HARVESTING"
    g.defineUpgrade(id,name,tabl)
end




defUpgrade("more_damage", "More Damage", {
    getValues = function(self,level)
        return level
    end,

    valueFormatter = {"+%d%%"},
    description = "Deal %{1} extra damage to ALL tokens",

    getTokenHitMultiplier = function(self,level)
        local a=self:getValues(level)
        return 1+(a/100)
    end
})



defUpgrade("more_speed", "More Speed", {
    getValues = function(self,level)
        return level
    end,

    valueFormatter = {"+%d%%"},
    description = "%{1} hit speed",

    getHitSpeedMultiplier = function(self,level)
        local a=self:getValues(level)
        return 1+(a/100)
    end
})



defUpgrade("more_area", "More Area", {
    getValues = function(self,level)
        return level
    end,

    valueFormatter = {"+%d%%"},
    description = "%{1} hit area",

    getHarvestAreaMultiplier = function(self,level)
        local a=self:getValues(level)
        return 1+(a/100)
    end
})




defUpgrade("lucky_hit", "Lucky Hit", {
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
    image = "money", -- TODO: change
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
