g.defineStalk("knife_stalk", {
    image = "knife",
    growthpos = {
        {x = -8, y = -8},
        {x = 0, y = -8},
        {x = 8, y = -8},
        {x = -8, y = 8},
        {x = 8, y = 8},
    }
})

g.defineToken("knife_bush", "Knife Bush", {
    maxHealth = 10,
    growths = {stalk = "knife_stalk", growth = "knife"},
    resources = {money = 10},
    tokenDestroyed = function(tok)
        local roff = helper.lerp(0, 2 * math.pi, love.math.random())
        for i = 1, 5 do
            g.spawnEntity("knife", tok.x, tok.y, i * 2 * math.pi / 5 + roff)
        end
    end
})
