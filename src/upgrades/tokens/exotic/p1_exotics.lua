
--[[

Exotic tokens.

Have special effects:

Green Mushroom (When destroyed, spawns 6 random grasses)
Red Mushroom (When destroyed, explodes, dealing 10 dmg)
Blue mushroom: When destroyed, spawns a lightning-bolt!

Jungle cat: When hit, deals damage to surrounding grass tokens
Clay Pot: gives a random amount of money, between 0 and 50
Treasure chest: Gives random loot! (Between $50 and $500)
Evil cat: Deal 10 damage to the nearest token every 0.4 seconds

]]

-- TODO: Balancing
g.defineTokenUpgrade("mushroom_blue", "Blue Mushroom", {
    token = {
        category = "mushroom",
        maxHealth = 7,
        resources = {},
        tokenDestroyed = function(tok)
            worldutil.spawnLightning(tok.x, tok.y, 10)
        end
    },
    upgrade = {
        description = "Spawns lightning when destroyed!",
        price = {money = 500}
    }
})




g.defineTokenUpgrade("mushroom_red", "Red Mushroom", {
    token = {
        category = "mushroom",
        maxHealth = 4,
        resources = {},
        tokenDestroyed = function(tok)
            worldutil.explosion(tok.x, tok.y, 10)
        end
    },
    upgrade = {
        description = "Explodes when destroyed!",
        price = {money = 100}
    }
})




g.defineTokenUpgrade("mushroom_green", "Green Mushroom", {
    token = {
        category = "mushroom",
        maxHealth = 7,
        resources = {},
        tokenDestroyed = function()
            for _=1, 6 do
                local x,y = g.getRandomPositionForToken()
                if x and y then
                    local t = nil
                    local r = love.math.random()
                    if r < 0.4 then
                        t = "small_grass"
                    elseif r < 0.7 then
                        t = "grass_blades"
                    else
                        t = "thick_grass"
                    end
                    g.spawnToken(t, x,y)
                end
            end
        end
    },
    upgrade = {
        description = "When destroyed, spawns 6 grass tokens",
        price = {money = 250}
    }
})



-- TODO: Balancing
g.defineTokenUpgrade("plant_pot", "Plant Pot", {
    token = {
        maxHealth = 10,
        resources = {},
        ---@param tok g.Token
        tokenDestroyed = function(tok)
            g.playSound("pot_smash", nil, 0.8, 0.2)
            g.iterateTokensInArea(tok.x, tok.y, 36, function(t)
                if t.category == "grass" then
                    g.damageToken(t, 8)
                end
            end)
        end
    },
    upgrade = {
        description = "When destroyed, damages surrounding grass tokens.",
        price = {money = 100}
    }
})



-- defineTokenUpgrade is not used because we don't want it in token pool.
-- but probably this _may_ be moved anyway.
g.defineToken("bomb", "Bomb", {
    maxHealth = 10,
    resources = {},

    tokenDestroyed = function(tok)
        worldutil.explosion(tok.x, tok.y, 32)
    end,
    perSecondUpdate = function(tok)
        g.damageToken(tok, 1)
    end
})
