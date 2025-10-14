
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
        maxHealth = 7,
        resources = {},
        tokenDestroyed = function(tok)
            worldutil.explosion(tok.x, tok.y, 10)
        end
    },
    upgrade = {
        description = "Spawns lightning when destroyed!",
        price = {money = 500}
    }
})

