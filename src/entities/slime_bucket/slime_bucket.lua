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
