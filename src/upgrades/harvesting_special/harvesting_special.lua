



---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defUpgrade(id,name,tabl)
    tabl.kind = "HARVESTING"
    tabl.procGen = {
        weight = 30,
        distance = {2, 8}
    }
    g.defineUpgrade(id,name,tabl)
end




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
        return level*2 + 4
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

