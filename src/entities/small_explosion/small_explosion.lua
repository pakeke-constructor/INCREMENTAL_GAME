
local frames

local function lazyGetFrames()
    if frames then
        return frames
    end
    local quad = g.getImageQuad("large_explosion_spritesheet")
    frames = helper.splitQuadHorizontally(quad, 9)
    return frames
end

local LIFETIME = 0.5

g.defineEntity("small_explosion_animation", {
    draw = function(e)
        local f = lazyGetFrames()
        local frameIndex = math.floor((1 - e.lifetime / LIFETIME) * #f) + 1
        frameIndex = helper.clamp(frameIndex, 1, #f)
        return g.drawImage(f[frameIndex], e.x, e.y)
    end,

    lifetime = LIFETIME,
    oy=0,
    ox=0,
})


