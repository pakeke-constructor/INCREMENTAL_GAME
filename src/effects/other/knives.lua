
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




local SCYTHES_PER_SECOND = 20

g.defineEffect("scythe_swarm", "Scythe Swarm", {
    description = "Spawn a swarm of scythes!",
    image = "iron_scythe",
    isDebuff = false,

    update = function(dur, dt)
        local t = love.timer.getTime()
        local rot = t*3
        local world = g.getMainWorld()
        if world.mouseX and world.mouseY then
            local x, y = assert(world.mouseX), assert(world.mouseY)
            if (love.math.random() < SCYTHES_PER_SECOND*dt) then
                worldutil.spawnScytheProjectile(x,y, rot + math.pi, 16)
            end

            if (love.math.random() < SCYTHES_PER_SECOND*dt) then
                worldutil.spawnScytheProjectile(x,y, rot, 16)
            end
        end
    end
})




local EXPLOSIONS_PER_SECOND = 6

g.defineEffect("explosion_swarm", "Explosion Swarm", {
    description = "The mouse causes explosions!",
    descriptionContext = "As in, the computer mouse. Where the player puts their mouse-pointer, there are explosions",
    image = "explosion_swarm",
    isDebuff = false,

    update = function(dur, dt)
        local world = g.getMainWorld()
        if world.mouseX and world.mouseY then
            local x, y = assert(world.mouseX), assert(world.mouseY)
            if (love.math.random() < EXPLOSIONS_PER_SECOND*dt) then
                local dx,dy = love.math.random(-30, 30), love.math.random(-30,30)
                worldutil.explosion(x+dx,y+dy, 1)
            end
        end
    end
})

