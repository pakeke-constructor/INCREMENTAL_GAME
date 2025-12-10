
---@param id string
---@param name string
---@param tabl g.UpgradeDefinition|{kind:nil}
local function defOrbitalUpgrade(id,name,tabl)
    tabl.kind = "HARVESTING"

    tabl.getValues = function(uinfo, level)
        return level
    end
    tabl.getEntityCount = function(uinfo, level)
        return (uinfo:getValues(level))
    end
    tabl.spawnEntity = function (uinfo)
        -- Position will be controlled by the world since it's orbital entity.
        return g.spawnEntity(id, 0, 0)
    end

    g.defineUpgrade(id,name,tabl)
end





g.defineEntity("orbital_knife", {
    image = "orbital_knife",
    orbitRing = 1,
    update = function(ent, dt)
        ent.rot = (ent.rot or 0) + dt*2
    end,
    hitToken = {
        radius = 24,
        collision = function(_, tok)
            g.damageToken(tok, 1)
        end
    }
})

defOrbitalUpgrade("orbital_knife", "Orbital Knife", {
    description = "Spawn %{1} orbiting knives that deal 1 damage!",
    maxLevel = 8,
})






g.defineEntity("orbital_scythe", {
    image = "orbital_scythe",
    orbitRing = 2,
    update = function(ent, dt)
        ent.rot = (ent.rot or 0) + dt*5
    end,
    hitToken = {
        radius = 24,
        collision = function(_, tok)
            g.damageToken(tok, 2)
        end
    }
})

defOrbitalUpgrade("orbital_scythe", "Orbital Scythe", {
    description = "Spawn %{1} orbiting scythes that deal 2 damage!",
    maxLevel = 8,
})







g.defineEntity("slime_bucket", {
    image = "slime_bucket",
    orbitRing = 2,
    update = function(ent, dt)
        ent.rot = ((ent.rot or 0) + dt) % (2 * math.pi)
    end,
    hitToken = {
        radius = 24,
        collision = function(_, tok)
            if love.math.random() <= 0.2 then
                g.slimeToken(tok)
            end
        end
    },
})

defOrbitalUpgrade("slime_bucket", "Slime Bucket", {
    description = "Spawn %{1} orbiting slime buckets, 20% chance to slime crops!",
    maxLevel = 5,
    kind="HARVESTING",
})






g.defineUpgrade("better_orbits", "Better Orbits", {
    kind = "HARVESTING",
    getValues = helper.percentageGetter(30,30),
    valueFormatter = {"%d%%"},
    description = "Increases speed of ALL orbitals by %{1}",
    maxLevel = 4,
    getOrbitSpeedMultiplier = function(self,level)
        local a=self:getValues(level)
        return 1+(a/100)
    end
})





g.defineEntity("orbital_star", {
    image = "star_icon",
    orbitRing = 1,
    update = function(ent, dt)
        ent.rot = ((ent.rot or 0) + dt) % (2 * math.pi)
    end,
    hitToken = {
        radius = 24,
        collision = function(_, tok)
            if love.math.random() <= 0.2 then
                g.starToken(tok)
            end
        end
    },
})

defOrbitalUpgrade("orbital_star", "Orbital Star", {
    description = "Spawn %{1} star orbiting the mouse, 20% chance to star crops!",
    kind = "HARVESTING",
    maxLevel = 5
})
