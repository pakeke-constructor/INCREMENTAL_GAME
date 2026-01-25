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
---@return love.ParticleSystem
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

    local GRAVITY = 100
    ps:setLinearAcceleration(0, GRAVITY, 0, GRAVITY)
    ps:setSpeed(50, 80)
    ps:setDirection(0)
    ps:setSpread(math.pi * 2)
    ps:setRotation(0, math.pi * 2)

    particleTypes[name] = ps
    return ps
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

---@param prefix string
---@param len integer
---@param start integer?
local function makeFrames(prefix, len, start)
    local t = {}
    for i=(start or 1),len do
        table.insert(t, prefix .. tostring(i))
    end
    return t
end

function initParticles()

    local crosshair = defineParticle("crosshair", {
        frames = {"crosshair"},
        lifetime = 0.2,
        emissionArea = {
            distribution = "ellipse",
            distance = {4, 4}
        }
    })
    crosshair:setLinearAcceleration(0, 0, 0, 0)
    crosshair:setSpeed(0, 0)
    crosshair:setRotation(0, 0)


    do
    local lifetime=0.2
    local xp = defineParticle("xp1", {
        frames = {"xp_particle_blue","xp_particle_blue2"},
        lifetime=lifetime,
        emissionArea = {
            distribution = "ellipse",
            distance = {0,0}
        }
    })
    local xp2 = defineParticle("xp2", {
        frames = {"xp_particle_white", "xp_particle_white2", "xp_particle_white3"},
        lifetime=lifetime,
        emissionArea = {
            distribution = "ellipse",
            distance = {0,0}
        }
    })
    local xp3 = defineParticle("xp3", {
        frames = {"xp_particle_pink","xp_particle_pink2"},
        lifetime=lifetime,
        emissionArea = {
            distribution = "ellipse",
            distance = {0,0}
        }
    })

    for _,psys in ipairs({xp,xp2,xp3}) do
        psys:setSpeed(40,40)
    end
    end

    local grass = defineParticle("grass", {
        frames = makeFrames("grass_particle_", 3, 0),
        lifetime = 0.4,
        emissionArea = {
            distribution = "ellipse",
            distance = {4, 4}
        }
    })
    grass:setSpeed(30,50)


    local wood = defineParticle("wood", {
        frames = makeFrames("wooden_particle_", 3),
        lifetime = 0.3,
        emissionArea = {
            distribution = "ellipse",
            distance = {4, 4}
        }
    })


    local slime = defineParticle("slime", {
        frames = makeFrames("slimed_particle_", 3),
        lifetime = 0.3,
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
