
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



local ORBIT_BULGE_DUR = 0.15
local ORBIT_BULGE_MAG = 0.6


g.defineEntity("orbital_knife", {
    image = "orbital_knife",
    orbitRing = 1,
    update = function(ent, dt)
        ent.rot = (ent.rot or 0) + dt*2
    end,
    hitToken = {
        radius = 24,
        collision = function(self, tok)
            g.damageToken(tok, g.stats.KnifeDamage)
            g.bulgeEntity(self, ORBIT_BULGE_DUR, ORBIT_BULGE_MAG)
        end
    }
})

defOrbitalUpgrade("orbital_knife", "Orbital Knife", {
    description = "Spawn %{1} orbiting knives that deal damage!",
    maxLevel = 8,
    procGen = {weight = 3, distance = {3, 8}}
})






g.defineEntity("orbital_scythe", {
    image = "orbital_scythe",
    orbitRing = 2,
    update = function(ent, dt)
        ent.rot = (ent.rot or 0) + dt*5
    end,
    hitToken = {
        radius = 24,
        collision = function(self, tok)
            g.damageToken(tok, g.stats.HitDamage / 3)
            g.bulgeEntity(self, ORBIT_BULGE_DUR, ORBIT_BULGE_MAG)
        end
    }
})

defOrbitalUpgrade("orbital_scythe", "Orbital Scythe", {
    description = "Spawn %{1} orbiting scythes that deal 2 damage!",
    maxLevel = 8,
    procGen = {weight = 2, distance = {4, 10}, needs = "orbital_knife"}
})







g.defineEntity("slime_bucket", {
    image = "slime_bucket",
    orbitRing = 2,
    hitToken = {
        radius = 24,
        collision = function(self, tok)
            if love.math.random() <= .2 then
                g.slimeToken(tok)
            end
            g.bulgeEntity(self, ORBIT_BULGE_DUR, ORBIT_BULGE_MAG)
        end
    },
})

defOrbitalUpgrade("slime_bucket", "Slime Bucket", {
    description = "Spawn %{1} orbiting slime buckets, 20% chance to slime crops!",
    maxLevel = 5,
    kind="HARVESTING",
    procGen = {weight = 1, distance = {5, 12}, needs = "slime_token"}
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
    end,
    procGen = {weight = 1, distance = {5, 10}, needs = "orbital_knife"}
})





g.defineEntity("orbital_star", {
    image = "orbital_star",
    orbitRing = 1,
    hitToken = {
        radius = 24,
        collision = function(self, tok)
            if love.math.random() <= 0.2 then
                g.starToken(tok)
            end
            g.bulgeEntity(self, ORBIT_BULGE_DUR, ORBIT_BULGE_MAG)
        end
    },
})

defOrbitalUpgrade("orbital_star", "Orbital Star", {
    description = "Spawn %{1} stars orbiting the mouse, 20% chance to star crops!",
    kind = "HARVESTING",
    maxLevel = 5,
    image = "null_image",
    procGen = {weight = 1, distance = {5, 12}, needs = "orbital_knife"},

    drawUI = function(uinfo, level, x, y, w, h)
        local t1 = love.timer.getTime()/2

        local cx,cy = x+w/2, y+h/2
        local rad = w/5

        for i = 1, 5 do
            local rot = t1 + i / 5 * 2 * math.pi
            local starx, stary = cx+rad*math.sin(rot), cy+rad*math.cos(rot)
            g.drawImage("star_icon", starx, stary)
        end
    end
})
