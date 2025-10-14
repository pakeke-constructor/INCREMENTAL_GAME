
local frames = objects.Array()

for i=10,1,-1 do
    frames:add("small_explosion_frame000"..tostring(i))
end

g.defineEntity("small_explosion_animation", {
    draw = function(e)
    end,
    lifetime = 0.25,
    oy=0,
    ox=0,
    update = worldutil.lifetimeAnimationUpdater({
        frames = frames
    }),
})


