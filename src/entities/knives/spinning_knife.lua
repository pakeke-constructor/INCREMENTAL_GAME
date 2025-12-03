g.defineEntity("spinning_knife", {
    image = "spinning_knife",
    orbitRing = 1,
    update = function(ent, dt)
        ent.rot = (ent.rot or 0) + dt
    end,
    hitToken = {
        radius = 24,
        collision = function(_, tok)
            g.damageToken(tok, 1)
        end
    }
})
