
--[[

Exotic tokens.

Have special effects:

Green Mushroom (When destroyed, spawns 6 random grasses)
Red Mushroom (When destroyed, explodes, dealing 10 dmg)
Blue mushroom: When destroyed, spawns 4 lightning-bolts!

Jungle cat: When hit, deals damage to surrounding grass tokens
Clay Pot: gives a random amount of money, between 0 and 50
Treasure chest: Gives random loot! (Between $50 and $500)
Evil cat: Deal 10 damage to the nearest token every 0.4 seconds

]]

-- TODO: Balancing
g.defineTokenUpgrade("lightning_cat", "Lightning Cat", {
    token = {
        maxHealth = 70,
        resources = {},
        tokenDestroyed = function()
            local world = g.getMainWorld()

            for i = 1, 3 do
                local x = love.math.random(world.WIDTH) - 1
                local y = love.math.random(world.HEIGHT) - 1
                worldutil.spawnLightning(x, y, 50)
            end
        end
    },
    upgrade = {
        price = {money = 10000, logs = 1}
    }
})
