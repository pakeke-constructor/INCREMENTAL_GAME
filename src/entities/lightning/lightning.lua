

g.defineEntity("lightning_animation", {
    draw = function(e)
    end,
    lifetime = 0.25,
    oy=-116,
    ox=-2,
    update = worldutil.lifetimeAnimationUpdater("lightning_skill4_frame",5),
    blendmode = "add",
})


