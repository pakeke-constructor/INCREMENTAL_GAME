

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
