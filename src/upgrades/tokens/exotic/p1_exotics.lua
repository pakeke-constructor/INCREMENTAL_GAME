
--[[

Exotic tokens.

Have special effects:

Green Mushroom (When destroyed, spawns 6 random grasses)
Red Mushroom (When destroyed, explodes, dealing 10 dmg)
Blue mushroom: When destroyed, spawns a lightning-bolt!


]]


-- TODO: Balancing
g.defineToken("plant_pot", "Plant Pot", {
    maxHealth = 200,
    resources = {},
    description = "When destroyed, damages surrounding grass crops",
    ---@param tok g.Token
    tokenDestroyed = function(tok)
        g.playWorldSound("pot_smash", nil, 0.8, 0.2)
        g.iterateTokensInArea(tok.x, tok.y, 36, function(t)
            if t.category == "grass" then
                g.damageToken(t, 80)
            end
        end)
    end,
    procGen = {weight = 3, distance = {1, 6}, needs = "grass_1"}
})



g.defineToken("bomb", "Bomb", {
    maxHealth = 200,
    resources = {},

    tokenDestroyed = function(tok)
        worldutil.explosion(tok.x, tok.y)
    end,
    perSecondUpdate = function(tok)
        g.damageToken(tok, 40)
    end,
    procGen = {weight = 2, distance = {2, 8}}
})



g.defineToken("bomb_without_fuse", "Bomb", {
    image = "bomb",
    maxHealth = 200,
    resources = {},
    tokenDestroyed = function(tok)
        worldutil.explosion(tok.x, tok.y)
    end,
})





g.defineToken("knife_bush", "Knife Bush", {
    maxHealth = 200,
    resources = {money = 10},
    description = "Shoots knives when destroyed!",
    tokenDestroyed = function(tok)
        local roff = helper.lerp(0, 2 * math.pi, love.math.random())
        for i = 1, 5 do
            g.spawnEntity("knife", tok.x, tok.y, i * 2 * math.pi / 5 + roff)
        end
    end,
    procGen = {weight = 5, distance = {2, 8}}
})
