

g.defineEntity("small_explosion_animation", {
    draw = function(e)
    end,
    lifetime = 0.25,
    oy=0,
    ox=0,
    update = worldutil.lifetimeAnimationUpdater("small_explosion_frame000",10),
})


