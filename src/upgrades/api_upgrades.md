

# upgrades API planning: 


```lua

upgrades.defineUpgrade("unlock_map", {
    prestigeType = "MISC",
    prestigeLevel = 1,
})



tokens.defineToken("basic_log", {
    health = 12,
    money = 5,
    wood = 1
})
upgrades.defineUpgrade("basic_log", {
    prestigeType = "TOKENS",
    prestigeLevel = 1,

    -- (`level` inserted as a first argument automatically)
    populateTokens = function(level, tokens)
        -- populateTokens called automatically every few seconds
        tokens:add("basic_log", level)
    end,
})



tokens.defineToken("basic_bomb", {
    -- after 3 seconds, blows up
    health = 10000,
    _lifetime = 3,
    onUpdate = function(self, dt)
        self._lifetime = self._lifetime - dt
        if self._lifetime <= 0 then
            g.destroy(self)
        end
    end,
    onDestroyed = function(self, dt)
        ...
        -- damage surrounding tokens
    end
})
upgrades.defineUpgrade("basic_bomb", {
    prestigeType = "TOKENS",
    prestigeLevel = 1,

    populateTokens = function(level, tokens)
        -- TODO:
        -- We should make this more robust w/ defineToken.
        -- I accidentally did `basic_log` instead of `basic_bomb`, which 
        -- wouldnt have been caught at load-time.

        -- Maybe make a wrapper to glue these calls together into one?
        tokens:add("basic_bomb")
    end,
})




upgrades.defineUpgrade("carpet_bomber", {
    -- every 15 seconds, spawn a bomb
    perSecondUpdate = function(level, dt)
        if g.getMetric("SECONDS_ELAPSED") % 15 == 0 then
            spawnBomb()
        end
    end,
})



upgrades.defineUpgrade("lucky_diamond", {
    description = loc("{level}% chance to spawn a lucky diamond every second!"),

    prestigeType = "TOKEN_UPGRADES",
    prestigeLevel = 1,

    -- perSecondUpdate, called once per second
    perSecondUpdate = function(level)
        local r = love.math.random()
        local chance = level / 100 -- level 3 --> 3% chance
        if r < chance then
            spawnLuckyDiamond()
        end
    end,
})



upgrades.defineUpgrade("Logbait", {
    description = loc("Logs earn +$2"),

    prestigeType = "TOKEN_UPGRADES",
    prestigeLevel = 1,

    getTokenMoneyModifier = function(level, token)
        if isType(token, "log") then
            return 2 * level
        end
        return 0
    end
})


upgrades.defineUpgrade("Forager cat", {
    description = loc("Every 5 logs you harvest, spawn a mushroom"),
    ...
    tokenMined = function(token)
        if isType(token, "log") then
            local count = g.getMetric("LOGS_DESTROYED")
            -- or maybe:
            local count = g.getMetric("DESTROYED_COUNTS:log")

            if count % 5 == 0 then
                spawnMushroomRandomly()
            end
        end
    end
})














--[[
===================

Harvesting Upgrades:

===================
]]


upgrades.defineUpgrade("bigger_area_1", {
    -- Increase harvest area by 2% (Currently 16%)

    getHarvestAreaMultiplier = function(level)
        local mult = 1 + ((level*2)/100)
        return mult
    end
})



local function spawnSpinningAxe()
    local e = {
        update = function(self, dt) end,
        draw = function(self) end
    }
    g.addEntity(a)
end


upgrades.defineUpgrade("spinning_axe", {
    -- Every second, 10% chance to spawn a spinning axe!
    perSecondUpdate = function(level, dt)
        if random() < 0.1 then
            spawnSpinningAxe()
        end
    end
})




```


