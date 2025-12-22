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

        local CT=50
        for i = 1, CT do
            local rot = i*2*math.pi/CT
            worldutil.spawnKnife(x,y, rot, 26)
        end
    end
})
