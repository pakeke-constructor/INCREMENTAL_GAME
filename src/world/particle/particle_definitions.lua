-- A simple wrapper for ParticleSystem
-- We can add more features as needed

local love = require("love")

---@class particle.definitions
---@field public frames string[]
---@field public lifetime number
---@field public emissionArea particle.emissionArea?

---@class particle.emissionArea
---@field public distribution love.AreaSpreadDistribution
---@field public distance [number, number]

---@type table<string, love.ParticleSystem>
local particleTypes = {}

---@class particle.params
---@field public frames string[]
---@field public lifetime number
---@field public emissionArea particle.emissionArea?

---@param name string
---@param def particle.params
local function defineParticle(name, def)
    if particleTypes[name] then
        error("particle '"..name.."' already defined")
    end

    -- Note: Just use asserts here because it will be obvious if there are errors in
    -- the parameter validation.
    assert(def.frames and #def.frames > 0, "missing particle frames")
    assert(def.lifetime and def.lifetime > 0, "missing or invalid particle lifetime")

    local quads = {}
    for _, v in ipairs(def.frames) do
        quads[#quads+1] = g.getImageQuad(v)
    end

    local ps = love.graphics.newParticleSystem(g.getAtlas())
    ps:setQuads(quads)
    ps:setParticleLifetime(def.lifetime)
    if def.emissionArea then
        ps:setEmissionArea(def.emissionArea.distribution, def.emissionArea.distance[1], def.emissionArea.distance[2])
    end

    particleTypes[name] = ps
end


-- We can't define particles at load-time 
--  because g is not defined yet
local initParticles



local particles = {}

---@param name string
function particles.makeParticleSystem(name)
    if initParticles then
        initParticles()
        initParticles = false
    end

    if not particleTypes[name] then
        error("particle '"..name.."' is not defined")
    end
    return particleTypes[name]:clone()
end









--[[

==============================
Particle definitions go below this line,
  Inside initParticles.
==============================

]]

function initParticles()

    defineParticle("crosshair", {
        frames = {"crosshair"},
        lifetime = 0.2,
        emissionArea = {
            distribution = "ellipse",
            distance = {4, 4}
        }
    })

    -- ... 

    -- ... 

    -- ... 

end



return particles
