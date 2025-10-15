
g.defineEntity("spinning_axe", {
    draw = function(e)
    end,
    lifetime = 0.6,
    update = function(e,dt)
        local ROT_SPEED = 4
        e.rot = e.rot + dt*ROT_SPEED
    end,
    perSecondUpdate = function (e)
        g.iterateTokensInArea(e.x,e.y, 10, function(tok)
            g.damageToken(tok, 1)
        end)
    end
})



