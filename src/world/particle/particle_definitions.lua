-- A simple wrapper for ParticleSystem
-- We can add more features as needed

local love = require("love")

---@class particle.definitions
---@field public frames string[]
---@field public lifetime number

---@type table<string, particle.definitions>
local particleList = {}

---@class particle.params
---@field public frames string[]
---@field public lifetime number

---@param name string
---@param def particle.params
local function defineParticle(name, def)
    if particleList[name] then
        error("particle '"..name.."' already defined")
    end

    -- Note: Just use asserts here because it will be obvious if there are errors in
    -- the parameter validation.
    assert(def.frames and #def.frames > 0, "missing particle frames")
    assert(def.lifetime and def.lifetime > 0, "missing or invalid particle lifetime")
end

-- Define particles here

-- End define particles

local particles = {}

---@param name string
function particles.makeParticleSystem(name)
    if particleList[name] then
        error("particle '"..name.."' is not defined")
    end

    local def = particleList[name]
    local quads = {}
    for _, v in ipairs(def.frames) do
        quads[#quads+1] = g.getImageQuad(v)
    end

    local ps = love.graphics.newParticleSystem(g.getAtlas())
    ps:setQuads(quads)
    ps:setParticleLifetime(def.lifetime)
    return ps
end

return particles
