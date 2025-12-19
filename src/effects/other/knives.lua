g.defineEffect("knife_swarm", "Knife Swarm", {
    description = "Spawn knives on mouse position.",
    image = "knife",
    isDebuff = false,

    perSecondUpdate = function()
        local world = g.getMainWorld()
        local x, y
        if world.mouseX and world.mouseY then
            x, y = assert(world.mouseX), assert(world.mouseY)
        else
            local w, h = g.getWorldDimensions()
            x = w * love.math.random()
            y = h * love.math.random()
        end

        local roff = helper.lerp(0, 2 * math.pi, love.math.random())
        for i = 1, 10 do
            g.spawnEntity("knife", x, y, i * 2 * math.pi / 10 + roff)
        end
    end
})
