g.defineEntity("spinning_knife", {
    image = "knife",
    orbitRing = 1,
    hitToken = {
        radius = 24,
        collision = function(_, tok)
            g.damageToken(tok, 1)
        end
    }
})
