
--[[

Exotic tokens.

Have special effects:

Green Mushroom (When destroyed, spawns 6 random grasses)
Red Mushroom (When destroyed, explodes, dealing 10 dmg)
Blue mushroom: When destroyed, spawns a lightning-bolt!


]]

-- TODO: Balancing
g.defineToken("mushroom_blue", "Blue Mushroom", {
    category = "mushroom",
    maxHealth = 7,
    resources = {},
    description = "Spawns lightning when destroyed!",
    tokenDestroyed = function(tok)
        worldutil.spawnLightning(tok.x, tok.y, 2)
    end
})




g.defineToken("mushroom_red", "Red Mushroom", {
    category = "mushroom",
    description = "Explodes when destroyed!",
    maxHealth = 4,
    resources = {},
    tokenDestroyed = function(tok)
        worldutil.explosion(tok.x, tok.y, 10)
    end
})




g.defineToken("mushroom_green", "Green Mushroom", {
    category = "mushroom",
    maxHealth = 7,
    resources = {},
    description = "When destroyed, spawns 6 grass crops",
    tokenDestroyed = function()
        for _=1, 6 do
            local x,y = g.getRandomPositionForToken()
            if x and y then
                local t = nil
                local r = love.math.random()
                if r < 0.4 then
                    t = "grass_1"
                elseif r < 0.7 then
                    t = "grass_2"
                else
                    t = "grass_3"
                end
                g.spawnToken(t, x,y)
            end
        end
    end
})



-- TODO: Balancing
g.defineToken("plant_pot", "Plant Pot", {
    maxHealth = 10,
    resources = {},
    description = "When destroyed, damages surrounding grass crops",
    ---@param tok g.Token
    tokenDestroyed = function(tok)
        g.playWorldSound("pot_smash", nil, 0.8, 0.2)
        g.iterateTokensInArea(tok.x, tok.y, 36, function(t)
            if t.category == "grass" then
                g.damageToken(t, 8)
            end
        end)
    end
})



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



g.defineToken("knife_bush", "Knife Bush", {
    maxHealth = 10,
    resources = {money = 10},
    description = "Shoots knives when destroyed!",
    tokenDestroyed = function(tok)
        local roff = helper.lerp(0, 2 * math.pi, love.math.random())
        for i = 1, 5 do
            g.spawnEntity("knife", tok.x, tok.y, i * 2 * math.pi / 5 + roff)
        end
    end
})
