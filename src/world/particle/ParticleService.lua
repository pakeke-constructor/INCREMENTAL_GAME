local love = require("love")

local objects = require("src.modules.objects.objects")
local particles = require(".particle_definitions")

---@class g.ParticleService: objects.Class
local ParticleService = objects.Class("g:ParticleService")

function ParticleService:init()
    ---@type table<string, love.ParticleSystem>
    self.particleMap = {}
    -- Iterating `particleMap` with `pairs` may result in particle order flickering
    -- because `pairs` order is undefined.
    ---@type love.ParticleSystem[]
    self.particleList = {}
end

if false then
    ---@return g.ParticleService
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function ParticleService() end
end

function ParticleService:update(dt)
    for _, ps in ipairs(self.particleList) do
        ps:update(dt)
    end
end

function ParticleService:draw()
    for _, ps in ipairs(self.particleList) do
        love.graphics.draw(ps)
    end
end

---@param particleName string
---@param x number
---@param y number
---@param amount integer? (defaults to 1)
function ParticleService:spawnParticles(particleName, x, y, amount)
    local ps = self.particleMap[particleName]
    if not ps then
        ps = particles.makeParticleSystem(particleName)
        self.particleMap[particleName] = ps
        self.particleList[#self.particleList+1] = ps
    end

    amount = math.max(amount or 1, 0)
    if amount > 0 then
        ps:setPosition(x, y)
        ps:emit(amount or 1)
    end
end

return ParticleService
