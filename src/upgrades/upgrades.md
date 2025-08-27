

# upgrades: 


IDEAL API:
```lua

upgrades.defineUpgrade("unlock_map", {
    prestigeType = "MISC",
    prestigeLevel = 1,
})


upgrades.defineUpgrade("wood", {
    prestigeType = "TOKENS",
    prestigeLevel = 1,

    events = {
        -- (`level` inserted as a first argument automatically)
        populateTokens = function(level, tokens)
            -- populateTokens called automatically every few seconds
            for i=1, level do
                tokens:add("wood")
            end
        end,
    }

})



upgrades.defineUpgrade("lucky_diamond", {
    description = loc("{level}% chance to spawn a lucky diamond every second!"),

    prestigeType = "TOKEN_UPGRADES",
    prestigeLevel = 1,

    events = {
        update = function(level, dt)
            local r = love.math.random()
            local chance = level / 100 -- level 3 --> 3% chance
            if r < (chance * dt) then
                spawnLuckyDiamond()
            end
        end,
    }
})



upgrades.defineUpgrade("lucky_diamond", {
    description = loc("2% increased mining power"),

    prestigeType = "TOKENS",
    prestigeLevel = 1,

    questions = {
    }
})




```


