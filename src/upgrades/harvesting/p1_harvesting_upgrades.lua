




---@param id string
---@param name string
---@param tabl g.UpgradeInfo|{kind:nil}
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
    description = loc("Deal +%{1}% extra damage to ALL tokens"),

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
    description = loc("+%{1}% hit speed"),

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
    description = loc("+%{1}% hit area"),

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
    description = loc("When a token is hit, +%{1}% chance to hit another token"),

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



